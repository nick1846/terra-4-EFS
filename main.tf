provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

resource "aws_key_pair" "ec2-user-public" {
  key_name   = var.my_key_name
  public_key = var.my_publickey
}


module "my_vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = var.my_vpc_name
  cidr                 = var.my_vpc_cidr
  azs                  = var.my_vpc_azs
  private_subnets      = var.my_vpc_private_subnets
  public_subnets       = var.my_vpc_public_subnets
  enable_dns_hostnames = var.my_dns_hostnames_bool
  enable_nat_gateway   = var.my_vpc_nat_gateway_bool
  vpc_tags             = var.my_vpc_tags
  public_subnet_tags   = var.my_public_subnets_tags
  private_subnet_tags  = var.my_private_subnets_tags
  igw_tags             = var.my_igw_tags

}


data "aws_ami" "my_ami" {
  most_recent = var.most_recent_bool
  filter {
    name   = var.ami_tag_type
    values = var.ami_value
  }
  owners = var.ami_owner
}


resource "aws_launch_configuration" "asg_lconf" {
  name            = "my_launch_conf"
  image_id        = data.aws_ami.my_ami.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sg_lconf.id, aws_security_group.my_ec2_egress_sg.id]
  key_name        = var.my_key_name
  user_data       = data.template_file.script.rendered
  lifecycle {
    create_before_destroy = true
  }
}


module "asg" {
  source                       = "terraform-aws-modules/autoscaling/aws"
  name                         = "dev_server"
  create_lc                    = false
  launch_configuration         = aws_launch_configuration.asg_lconf.name
  recreate_asg_when_lc_changes = true
  target_group_arns            = module.my_alb.target_group_arns
  asg_name                     = "my_asg"
  vpc_zone_identifier          = [module.my_vpc.public_subnets[0], module.my_vpc.public_subnets[1]]
  health_check_type            = "EC2"
  min_size                     = 0
  max_size                     = 3
  desired_capacity             = 3
  wait_for_capacity_timeout    = 0

  tags = [
    {
      key                 = "Enviroment"
      value               = "test"
      propagate_at_launch = true
    }
  ]
}


module "my_alb" {
  source             = "terraform-aws-modules/alb/aws"
  name               = "my-alb"
  load_balancer_type = "application"
  vpc_id             = module.my_vpc.vpc_id
  subnets            = module.my_vpc.public_subnets
  security_groups    = [module.sg_alb.this_security_group_id]

  target_groups = [
    {
      name_prefix      = "dev-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 10
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      tags = {
        InstanceTargetGroupTag = "dev_server"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}


resource "aws_efs_file_system" "my_efs_with_policy" {
  creation_token   = "my_efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "my-efs"
  }
}

resource "aws_efs_mount_target" "my_efs_mount_target" {

  file_system_id  = aws_efs_file_system.my_efs_with_policy.id
  count           = length(module.my_vpc.public_subnets)
  subnet_id       = module.my_vpc.public_subnets[count.index]
  security_groups = [aws_security_group.my_efs_sg.id]
}


data "template_file" "script" {
  template = file("userdata.sh")

  vars = {
    efs_id = aws_efs_file_system.my_efs_with_policy.id
  }
}

module "sg_alb" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = var.sg_alb_name
  description         = var.sg_description
  vpc_id              = module.my_vpc.vpc_id
  ingress_cidr_blocks = var.sg_ingress_cidr
  ingress_rules       = var.sg_ingress_rules
  egress_cidr_blocks  = var.sg_egress_cidr
  egress_rules        = var.sg_egress_rules
}


resource "aws_security_group" "sg_lconf" {
  name   = "sg_lconf"
  vpc_id = module.my_vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.sg_alb.this_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "my_efs_sg" {
  name        = "sg_efs"
  vpc_id      = module.my_vpc.vpc_id
  description = "Allow traffic from instances on port 2049"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "my_efs_sg_rule" {
  type                     = "ingress"
  security_group_id        = aws_security_group.my_efs_sg.id
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my_ec2_egress_sg.id
}


resource "aws_security_group" "my_ec2_egress_sg" {
  name   = "sg_ec2_egress"
  vpc_id = module.my_vpc.vpc_id
}

resource "aws_security_group_rule" "my_ec2_egress_sg_rule" {
  type                     = "egress"
  security_group_id        = aws_security_group.my_ec2_egress_sg.id
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my_efs_sg.id

}
