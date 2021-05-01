 

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


/////////// eks2 add ////////
data "aws_iam_role" "jjouhiu-eks-cluster-2021-2" {
  name = "jjouhiu-eks-cluster-2021-2"
}
data "aws_iam_instance_profile" "jjouhiu-eks-nodegroup-role2" {
  name = "jjouhiu-eks-nodegroup-role"
}
/////////// eks2 add ////////

module "vpc" {
    source = "./module/"


}


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
 
  source       = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_enabled_log_types = ["api","controllerManager","scheduler","authenticator","audit"]
  vpc_id          = module.vpc.vpc_id 
 
  subnets         = [module.vpc.milk_public_subnet1.id, module.vpc.milk_public_subnet2.id ]  
  cluster_version = "1.19"
  manage_cluster_iam_resources = false
  cluster_iam_role_name = "${data.aws_iam_role.jjouhiu-eks-cluster-2021.name}"
    

  manage_aws_auth = true
   
  map_roles = [
    {
      rolearn  = "arn:aws:iam::936777008077:role/eks_role"
      username = "eks_role" 
      groups    = ["system:masters"]
    }     
  ]

  map_users = [
    {
      userarn  = "arn:aws:iam::936777008077:user/kilhan.kim"
      username = "kilhan.kim" 
      groups    = ["system:masters"]
    }  
    ,
    {
      userarn  = "arn:aws:iam::936777008077:user/kilhan-tam"
      username = "kilhan-tam" 
      groups    = ["system:masters"]
    }       

  ]   
  

  node_groups = {
    eks_nodes = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 3
      key_name = "perfMaster"
      instance_type    = "t3.micro"
      node_name ="eks-worker-node"
      public_ip = true
      source_security_group_ids = [
        module.vpc.milk_bastion_security_group ,
        module.vpc.milk_default_security_group
      ]
      tags ={
        Name = "eks-node"
        auto-delete="no"
        auto-delete="false"

      }
    
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


# /////////// eks2 add ////////
# module "eks2" {
 
#   source       = "terraform-aws-modules/eks/aws"
#   cluster_name    = "seoul-eks-cluster2"
#   cluster_enabled_log_types = ["api","controllerManager","scheduler","authenticator","audit"]
#   vpc_id          = module.vpc.vpc_id 
 
#   subnets         = [module.vpc.milk_public_subnet1.id, module.vpc.milk_public_subnet2.id ]  
#   cluster_version = "1.19"
#   manage_cluster_iam_resources = false
#   cluster_iam_role_name = "${data.aws_iam_role.jjouhiu-eks-cluster-2021-2.name}"
    

#   manage_aws_auth = true
   
#   map_roles = [
#     {
#       rolearn  = "arn:aws:iam::936777008077:role/eks_role"
#       username = "eks_role" 
#       groups    = ["system:masters"]
#     }     
#   ]

#   map_users = [
#     {
#       userarn  = "arn:aws:iam::936777008077:user/kilhan.kim"
#       username = "kilhan.kim" 
#       groups    = ["system:masters"]
#     }  
#     ,
#     {
#       userarn  = "arn:aws:iam::936777008077:user/kilhan-tam"
#       username = "kilhan-tam" 
#       groups    = ["system:masters"]
#     }       

#   ]   
  

#   node_groups = {
#     eks_nodes = {
#       desired_capacity = 3
#       max_capacity     = 5
#       min_capacity     = 3
#       key_name = "perfMaster"
#       instance_type    = "t3.micro"
#       node_name ="eks-worker-node"
#       public_ip = true
#       source_security_group_ids = [
#         module.vpc.milk_bastion_security_group ,
#         module.vpc.milk_default_security_group
#       ]
#       tags ={
#         Name = "eks-node"
#         auto-delete="no"
#         auto-delete="false"

#       }
    
#     }
#   }
# }


# resource "aws_security_group_rule" "milk-cluster-ingress-ssh2" {
#   cidr_blocks       = ["0.0.0.0/0"]
#   description       = "Allow to communicate with the cluster API Server"
#   from_port         = 22
#   protocol          = "tcp"
#   security_group_id = module.eks2.cluster_primary_security_group_id
#   to_port           = 22
#   type              = "ingress"
    
# }
# /////////// eks2 add ////////






############   Local Variable  ######################
locals {
  cluster_name = "seoul-eks-cluster"
  cluster_name2 = "seoul-eks-cluster2"
  region       = "ap-northeast-2"
}

 

output "vpc_id"{
    value="${module.vpc.vpc_id}"
}
output "milk_public_subnet1"{
    value="${module.vpc.milk_public_subnet1.id}"
}

output "milk_public_subnet2"{
    value="${module.vpc.milk_public_subnet2.id}"
}
/*
output "milk_private_subnet1"{
    value="${module.vpc.milk_private_subnet1.id}"
}

output "milk_private_subnet2"{
    value="${module.vpc.milk_private_subnet2.id}"
}
*/
# output "eks_info" {
#   value = module.eks.cluster_primary_security_group_id
# }

# output "milk_bastion_security_group" {
#   value = module.vpc.milk_bastion_security_group
# }

output "milk_bastion_security_group"{
    value= module.vpc.milk_bastion_security_group
}

output "milk_default_security_group"{
    value= module.vpc.milk_default_security_group
}
