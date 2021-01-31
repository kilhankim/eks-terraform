

output "aws_default_route_table_info"{
    value = "${aws_default_route_table.milk.id}"
}

output "aws_az_list"{
    value="${data.aws_availability_zones.all}"
}

output "igw_info"{
    value="${aws_internet_gateway.milk_igw.id}"
}


# output "bastion_info"{
#     value="${aws_instance.milk_bastion}"
# }



# output "bastion_id"{
#     # value="${aws_instance.milk_bastion.id}"
#     value="${aws_instance.milk_bastion}"
# }



# output "bastion_ip"{
#     value="${aws_instance.milk_bastion.public_ip}"
# }



# output "bastion_ip2"{
#     value="${aws_instance.milk_bastion.public_ip}"
# }

output "vpc_id" {
    value = "${aws_vpc.milk-vpc.id}"
}

output "milk_private_subnet1"{
    value="${aws_subnet.milk_private_subnet1}"
}
output "milk_private_subnet2"{
    value="${aws_subnet.milk_private_subnet2}"
}
output "milk_bastion_security_group"{
    value="${aws_security_group.milk_bastion_security_group.id}"
}

output "milk_default_security_group"{
    value="${aws_default_security_group.milk_default.id}"
}

output "milk_public_subnet1"{
    value="${aws_subnet.milk_public_subnet1}"
}

output "milk_public_subnet2"{
    value="${aws_subnet.milk_public_subnet2}"
}
