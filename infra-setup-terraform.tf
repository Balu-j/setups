provider "aws" {
region = "ap-south-1"
}

resource "aws_instance" "one" {
  count                  = 5
  ami                    = "ami-0e12ffc2dd465f6e4 "
  instance_type          = "t2.micro"
  key_name               = "mumbai"
  vpc_security_group_ids = ["sg-0e12ffc2dd465f6e4"]
  tags = {
    Name = var.instance_names[count.index]
  }
}

variable "instance_names" {
  default = ["jenkins", "tomcat-1", "tomcat-2", "Monitoring server","nexus"]
}
