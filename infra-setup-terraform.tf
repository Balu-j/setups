provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "one" {
  count                  = 5
  ami                    = "ami-08e7318c2e031024c"
  instance_type          = "t2.micro"
  key_name               = "mumbai"
  vpc_security_group_ids = ["sg-08fe89a0f50d95931"]

  tags = {
    Name = var.instance_names[count.index]
  }
}

variable "instance_names" {
  default = ["jenkins", "tomcat-1", "tomcat-2", "Monitoring server", "nexus"]
}
