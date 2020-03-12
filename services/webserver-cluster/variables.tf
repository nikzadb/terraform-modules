variable "server_port" {
    type        =   number
    default     =   8080
}

variable "region" {
    type    =   string
    default =   "us-east-2"
}

variable "cluster_name" {
    description     =   "The name to use for all the cluster resources"
    type            =   string
  
}

variable "instance_type" {
    description     =   "The type of EC2 instances to run (e.g., t2.micro)"
    type            =   string
}

variable "min_size" {
    description     =   "The minimum number of EC2 instances in the ASG"
    type            =    number
}

variable "max_size" {
    description     =   "The maximum number of EC2 instances in the ASG"
    type            = number
}




