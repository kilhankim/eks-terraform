
# resource "aws_key_pair" "mykey" {
#   key_name = "jjouhiu"
#   public_key = "${file("./jjouhiu.pub")}"
 
# } 

data "aws_iam_user" "kilhan_kim" {
  user_name = "kilhan.kim"
}
data "aws_iam_user" "kilhan-tam" {
  user_name = "kilhan-tam"
}


data "aws_iam_role" "jjouhiu-eks-cluster-2021" {
  name = "jjouhiu-eks-cluster-2021"
}
data "aws_iam_instance_profile" "jjouhiu-eks-nodegroup-role" {
  name = "jjouhiu-eks-nodegroup-role"
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


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.12"
}


 
module "eks" {
  # source          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v12.2.0"
  # source = "github.com/mzcdev/terraform-aws-eks?ref=v0.12.50"
  source       = "terraform-aws-modules/eks/aws"
  #source          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git"
  cluster_name    = local.cluster_name
  cluster_enabled_log_types = ["api","controllerManager","scheduler","authenticator","audit"]
  vpc_id          = module.vpc.vpc_id 
  # public subnet에서만 만들어질 수 있도록 private subnet을 remove

  # subnets         = [module.vpc.milk_private_subnet1.id, module.vpc.milk_private_subnet2.id,
  #                    module.vpc.milk_public_subnet1.id, module.vpc.milk_public_subnet2.id ]
  subnets         = [module.vpc.milk_public_subnet1.id, module.vpc.milk_public_subnet2.id ]  
  cluster_version = "1.18"
  manage_cluster_iam_resources = false
  # manage_worker_iam_resources = false
  cluster_iam_role_name = "${data.aws_iam_role.jjouhiu-eks-cluster-2021.name}"
  # cluster_iam_role_arn  = "${data.aws_iam_role.jjouhiu-eks-cluster-2021.arn}"
    #  worker_iam_instance_profile_names = "${data.aws_iam_instance_profile.jjouhiu-eks-nodegroup-role.name}"
    #   worker_iam_instance_profile_arns	= "${data.aws_iam_instance_profile.jjouhiu-eks-nodegroup-role.arn}"
  # worker_iam_role_arn  = "${data.aws_iam_instance_profile.jjouhiu-eks-nodegroup-role.arn}"
  #     worker_iam_role_name = "${data.aws_iam_instance_profile.jjouhiu-eks-nodegroup-role.name}"
  

  manage_aws_auth = true
  #manage_aws_auth = false


  map_users = [
    {
      userarn  = "arn:aws:iam::936777008077:user/kilhan.kim"
      username = "kilhan.kim" 
      groups    = ["system:masters"]
    }    

  ]   
  

  node_groups = {
    eks_nodes = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 3
      # key_name         = aws_key_pair.mykey.key_name
      key_name = "perfMaster"
      instance_type    = "t3.micro"
      node_name ="eks-worker-node"
      public_ip = true
      source_security_group_ids = [
        module.vpc.milk_bastion_security_group ,
        module.vpc.milk_default_security_group
      ]
    
    }
  }
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
  cluster_name = "lunar-eks-cluster"
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