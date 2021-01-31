
resource "aws_key_pair" "mykey" {
  key_name = "jjouhiu"
  public_key = "${file("./jjouhiu.pub")}"
 
} 



module "vpc" {
    source = "./module/"


}
/*
resource "aws_iam_role" "example" {
  name = "eks-cluster-example"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "example-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.example.name
}

resource "aws_eks_cluster" "milk" {
  name     = "milk"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = [module.vpc.milk_private_subnet1.id, module.vpc.milk_private_subnet2.id,
                     module.vpc.milk_public_subnet1.id, module.vpc.milk_public_subnet2.id ]
    security_group_ids = [module.vpc.milk_bastion_security_group, module.vpc.milk_default_security_group]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]
 }
 

resource "aws_security_group_rule" "milk-cluster-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow to communicate with the cluster API Server"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_eks_cluster.milk.vpc_config[0].cluster_security_group_id
  to_port           = 22
  type              = "ingress"
}




resource "aws_iam_role" "milk-node" {
  name = "terraform-eks-milk-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "milk-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.milk-node.name
}

resource "aws_iam_role_policy_attachment" "milk-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.milk-node.name
}

resource "aws_iam_role_policy_attachment" "milk-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.milk-node.name
}


resource "aws_eks_node_group" "milk-nodegroup" {
  cluster_name    = aws_eks_cluster.milk.name
  node_group_name = "milk-node-group-name"
  node_role_arn   = aws_iam_role.milk-node.arn
  subnet_ids      = [module.vpc.milk_public_subnet1.id, module.vpc.milk_public_subnet2.id]


  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.milk-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.milk-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.milk-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
*/





 
module "eks" {
  source          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v12.1.0"
  cluster_name    = local.cluster_name
  vpc_id          = module.vpc.vpc_id
  subnets         = [module.vpc.milk_private_subnet1.id, module.vpc.milk_private_subnet2.id,
                     module.vpc.milk_public_subnet1.id, module.vpc.milk_public_subnet2.id ]
  cluster_version = "1.18"

  node_groups = {
    eks_nodes = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 3
      key_name         = aws_key_pair.mykey.key_name
      instance_type    = "t3.micro"
      source_security_group_ids = [
        module.vpc.milk_bastion_security_group
      ]
    }
  }
  manage_aws_auth = false
}


resource "aws_security_group_rule" "milk-cluster-ingress-ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow to communicate with the cluster API Server"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = module.eks.cluster_primary_security_group_id
  to_port           = 22
  type              = "ingress"
}



############   Local Variable  ######################
locals {
  cluster_name = "kilhan-eks-cluster"
  region       = "us-east-1"
}

 

output "vpc_id"{
    value="${module.vpc.vpc_id}"
}

output "milk_private_subnet1"{
    value="${module.vpc.milk_private_subnet1}"
}

output "milk_private_subnet2"{
    value="${module.vpc.milk_private_subnet2}"
}

# output "endpoint" {
#   value = aws_eks_cluster.milk.endpoint
# }

# output "kubeconfig-certificate-authority-data" {
#   value = aws_eks_cluster.milk.certificate_authority[0].data
# }

# output "aws_eks_cluster_milk_info" {
#   value= aws_eks_cluster.milk.vpc_config[0].cluster_security_group_id
# }

# output "aws_key_pair_mykey_name" {
#   value=aws_key_pair.mykey.key_name
# }

output "eks_info" {
  value = module.eks.cluster_primary_security_group_id
}

output "milk_bastion_security_group" {
  value = module.vpc.milk_bastion_security_group
}