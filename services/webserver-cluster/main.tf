
data "aws_availability_zones" "all" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration    =   aws_launch_configuration.example.name
    availability_zones      =   data.aws_availability_zones.all.names

    load_balancers      =   [aws_elb.example.name]
    health_check_type   =   "ELB"

    min_size    =   var.min_size
    max_size    =   var.max_size
  
    tag {
        key                 =   "${var.cluster_name}-autoscaling"
        value               =   "terraform-asg-example"
        propagate_at_launch =   true
    }
}

resource "aws_security_group" "instance" { 
    name = "${var.cluster_name}-instance"
    
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    lifecycle { 
        create_before_destroy = true
    } 
}


#######################################
# Load balancer
#######################################

resource "aws_elb" "example" {
    name                =   "${var.cluster_name}-aws-elb"
    availability_zones  =   data.aws_availability_zones.all.names
    security_groups     =   [aws_security_group.elb.id]

    listener    {
        lb_port =   80
        lb_protocol =   "http"
        instance_port   =   var.server_port
        instance_protocol   =   "http"
    }

    health_check    {
        healthy_threshold   =   2
        unhealthy_threshold =   2
        timeout             =   3
        interval            =   30
        target              =   "HTTP:${var.server_port}/"
    }
}

resource "aws_security_group" "elb" {
    name    =   "${var.cluster_name}-elb"

    ingress {
        from_port   =   80
        to_port     =   89
        protocol    =   "tcp"
        cidr_blocks =   ["0.0.0.0/0"]
    }

    egress {
        from_port   =   0
        to_port     =   0
        protocol    =   "-1"
        cidr_blocks =   ["0.0.0.0/0"]
    }
}

output "elb_dns_name" {
  value = aws_elb.example.dns_name
}

output "asg_name" {
  value         =   aws_autoscaling_group.example.name
  description   =   "The name of the Auto Scaling Group"
}

output "clb_dns_name" {
  value         = aws_elb.example.dns_name
  description   = "The domain name of the load balancer"  
}






