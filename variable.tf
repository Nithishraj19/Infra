variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidr" {
    type = list(any)
}
variable "public_subnet_availability_zone" {
    type = list(any)
}
variable "private_subnet_cidr" {
   type = list(any)
}
variable "private_az" {
  type = list(any)
}
# variable "inbound_for_HTTP" {
  
# }
# variable "inbound_to_HTTP" {
  
# }
# variable "inbound_for_ssh_from_port" {
  
# }
# variable "inbound_for_ssh_to_port" {
  
# }
variable "incoming_traffic" {
  
}
# variable "egress_from_port" {
  
# }
# variable "egress_to_port" {

# }
variable "ami_of_Public_server1" {
  
}
variable "instance_type" {
  
}
variable "server1_key_name" {
  
}

variable "ami_of_private_server" {
  
}
variable "name_of_private_server" {
  
}
