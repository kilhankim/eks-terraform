resource "aws_iam_role" "example" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}



resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "${aws_iam_role.example.name}"
}
resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.example.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_vpc" "milk-vpc" {
  cidr_block  = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"
  tags={
      "Name" = "milk-vpc"
  }
}
resource "aws_default_route_table" "milk" {
  default_route_table_id = "${aws_vpc.milk-vpc.default_route_table_id}"

  tags={
    Name = "milk-default-rtb"
  }
}

data "aws_availability_zones" "all" {} // Availability zone list 

resource "aws_subnet" "milk_public_subnet1" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  cidr_block = "10.10.1.0/24"
  map_public_ip_on_launch = true// 퍼블릭 서브넷이므로 서버 등을 띄울 때 자동으로 퍼블릭 IP가 할당
  availability_zone = "${data.aws_availability_zones.all.names[0]}"
  tags = {
    Name = "milk-public-az-1"
  }
}

resource "aws_subnet" "milk_public_subnet2" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  cidr_block = "10.10.2.0/24"
  map_public_ip_on_launch = true // 퍼블릭 서브넷이므로 서버 등을 띄울 때 자동으로 퍼블릭 IP가 할당
  availability_zone = "${data.aws_availability_zones.all.names[1]}"
  tags = {
    Name = "milk-public-az-2"
  }
}

resource "aws_subnet" "milk_private_subnet1" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  cidr_block = "10.10.10.0/24"
  availability_zone = "${data.aws_availability_zones.all.names[0]}"
  tags = {
    Name = "milk-private-az-1"
  }
}

resource "aws_subnet" "milk_private_subnet2" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  cidr_block = "10.10.11.0/24"
  availability_zone = "${data.aws_availability_zones.all.names[1]}"
  tags = {
    Name = "milk-private-az-2"
  }
}

resource "aws_internet_gateway" "milk_igw" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  tags = {
    Name = "milk-igw"
  }
}

resource "aws_route" "milk_internet_access" {
#   route_table_id = "${aws_vpc.milk-vpc.main_route_table_id}"
  route_table_id = "${aws_default_route_table.milk.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.milk_igw.id}"
}

resource "aws_eip" "milk-eip" {
  vpc = true
  depends_on = ["aws_internet_gateway.milk_igw"]
}

// NAT gateway
resource "aws_nat_gateway" "milk_nat" {
  allocation_id = "${aws_eip.milk-eip.id}"
  subnet_id = "${aws_subnet.milk_public_subnet1.id}"
  depends_on = ["aws_internet_gateway.milk_igw"]
}


resource "aws_route_table" "milk_private_route_table" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  tags ={
    Name = "milk-private-rtb"
  }
}

resource "aws_route" "private_route" {
  route_table_id = "${aws_route_table.milk_private_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.milk_nat.id}"
}


// associate subnets to route tables
resource "aws_route_table_association" "milk_public_subnet1_association" {
  subnet_id = "${aws_subnet.milk_public_subnet1.id}"
  route_table_id = "${aws_default_route_table.milk.id}"
}

resource "aws_route_table_association" "milk_public_subnet2_association" {
  subnet_id = "${aws_subnet.milk_public_subnet2.id}"
  route_table_id = "${aws_default_route_table.milk.id}"
}

resource "aws_route_table_association" "milk_private_subnet1_association" {
  subnet_id = "${aws_subnet.milk_private_subnet1.id}"
  route_table_id = "${aws_route_table.milk_private_route_table.id}"
}

resource "aws_route_table_association" "milk_private_subnet2_association" {
  subnet_id = "${aws_subnet.milk_private_subnet2.id}"
  route_table_id = "${aws_route_table.milk_private_route_table.id}"
}


// default security group
resource "aws_default_security_group" "milk_default" {
  vpc_id = "${aws_vpc.milk-vpc.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags={
    Name = "milk-default-securitygroup"
  }
}


// network acl for public subnets
resource "aws_network_acl" "milk_acl_public" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  subnet_ids = [
    "${aws_subnet.milk_public_subnet1.id}",
    "${aws_subnet.milk_public_subnet2.id}",
  ]

  tags ={
    Name = "milk_acl_public"
  }
}


resource "aws_network_acl_rule" "milk_public_ingress80" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 100 //항목에 할당할 규칙 번호입니다(예: 100). ACL 항목은 규칙 번호에 따라 오름차순으로 처리됩니다. 하나가 송신 규칙이고 다른 하나가 수신 규칙이 아닌 경우 항목은 동일한 규칙 번호를 사용할 수 없습니다.
  rule_action = "allow"
  egress = false //이 규칙이 서브넷에서의 송신 트래픽에 적용될지(true) 또는 서브넷에 대한 수신 트래픽에 적용될지(false) 여부입니다
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "milk_public_egress80" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 100
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "milk_public_ingress443" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 110
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "milk_public_egress443" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 110
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "milk_public_ingress22" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 120
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

resource "aws_network_acl_rule" "milk_public_egress22" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 120
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "${aws_vpc.milk-vpc.cidr_block}" //허용하거나 거부할 IPv6 네트워크 범위입니다(CIDR 표기). 요구 사항은 조건부입니다
  from_port = 22
  to_port = 22
}

resource "aws_network_acl_rule" "milk_public_ingress_ephemeral" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 140
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "milk_public_egress_ephemeral" {
  network_acl_id = "${aws_network_acl.milk_acl_public.id}"
  rule_number = 140
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}


// network acl for private subnets
resource "aws_network_acl" "milk_acl_private" {
  vpc_id = "${aws_vpc.milk-vpc.id}"
  subnet_ids = [
    "${aws_subnet.milk_private_subnet1.id}",
    "${aws_subnet.milk_private_subnet2.id}"
  ]

  tags ={
    Name = "milk_acl_private"
  }
}


resource "aws_network_acl_rule" "milk_private_ingress_vpc" {
  network_acl_id = "${aws_network_acl.milk_acl_private.id}"
  rule_number = 100
  rule_action = "allow"
  egress = false
  protocol = -1
  cidr_block = "${aws_vpc.milk-vpc.cidr_block}"
  from_port = 0
  to_port = 0
}

resource "aws_network_acl_rule" "milk_private_egress_vpc" {
  network_acl_id = "${aws_network_acl.milk_acl_private.id}"
  rule_number = 100
  rule_action = "allow"
  egress = true
  protocol = -1
  cidr_block = "${aws_vpc.milk-vpc.cidr_block}"
  from_port = 0
  to_port = 0
}

resource "aws_network_acl_rule" "milk_private_ingress_nat" {
  network_acl_id = "${aws_network_acl.milk_acl_private.id}"
  rule_number = 110
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "milk_private_egress80" {
  network_acl_id = "${aws_network_acl.milk_acl_private.id}"
  rule_number = 120
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "milk_private_egress443" {
  network_acl_id = "${aws_network_acl.milk_acl_private.id}"
  rule_number = 130
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}


// Basiton Host
resource "aws_security_group" "milk_bastion_security_group" {
  name = "milk_bastion_security_group"
  description = "Security group for bastion instance"
  vpc_id = "${aws_vpc.milk-vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "milk_bastion_security_group"
  }
}

/*
resource "aws_instance" "milk_bastion" {
#   ami = "${data.aws_ami.ubuntu.id}"
    ami = "ami-0c94855ba95c71c99"
    instance_type = "t2.micro"
  availability_zone = "${aws_subnet.milk_public_subnet1.availability_zone}"
  key_name = "jjouhiu"
  vpc_security_group_ids = [
    "${aws_default_security_group.milk_default.id}",
    "${aws_security_group.milk_bastion_security_group.id}"
  ]
  subnet_id = "${aws_subnet.milk_public_subnet1.id}"
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"

  tags ={
    Name = "milk_bastion"
  }
}


resource "aws_eip" "side_effect_bastion" {
  vpc = true
  instance = "${aws_instance.milk_bastion.id}"
  depends_on = ["aws_internet_gateway.milk_igw"]
}
*/



# terraform {
#   backend "s3" {
#     bucket = "terraform-state-kkh"
#     key = "milk.tfstate"
#     region = "us-east-1"
#     encrypt = true
#   }
# }
