aws_region = "us-east-2"

#my-key-values
my_key_name  = "ec2-user-publickey"
my_publickey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMVFg4T9xpmygL6+2bHKqNzhhwvykMBsWu7nUhLEaetMJE5hlrEfvZvzmQ0Bu9NyEe6jpVFxoYS29Ypurg8beGXM2kLaruXUK5XkCfQgQfDEEPVKAnyTONL4f/1yfQ4DFQ9L4zbMk8VYmEjX02I0mZxenAV2bl63DsgZ2nPxJAcnBg8fMo1xoZdaThQ4T3xJuWkg88nfGiAICjFGQUc5KLLQjsYyjCdf4s/8Qc2Wpx2hnKFELCkiF+J0c7a8VMjus7v5o7u20kiMZTTu6DPZca4J9pnSlSmdH/4UgDdwFdbe2hU8KB7ocX7CgmDkLoOMg2x7dwNa2XjLUTm5gA+yAx ec2-user@ip-10-0-100-233.us-east-2.compute.internal"

#my-vpc-values

my_vpc_name             = "terra-2-vpc"
my_vpc_cidr             = "10.0.0.0/16"
my_vpc_azs              = ["us-east-2a", "us-east-2b"]
my_vpc_private_subnets  = ["10.0.1.0/24"]
my_vpc_public_subnets   = ["10.0.100.0/24", "10.0.101.0/24"]
my_dns_hostnames_bool   = "true"
my_vpc_nat_gateway_bool = "false"
my_vpc_tags             = { Name = "terra-2-vpc" }
my_public_subnets_tags  = { Name = "terra-2-public-subnet-a" }
my_private_subnets_tags = { Name = "terra-2-private-subnet-a" }
my_igw_tags             = { Name = "terra-2-igw" }

#my-sg-values

sg_alb_name      = "sg_alb"
sg_description   = "Security group for web_server and ssh access"
sg_ingress_cidr  = ["0.0.0.0/0"]
sg_ingress_rules = ["https-443-tcp", "http-80-tcp", "ssh-tcp", "http-8080-tcp"]
sg_egress_cidr   = ["0.0.0.0/0"]
sg_egress_rules  = ["all-all"]


#my-data-source-values

most_recent_bool = "true"
ami_tag_type     = "name"
ami_value        = ["ansible*"]
ami_owner        = ["021510583954"]







