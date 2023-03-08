variable "awsprops" {
  type = map(any)
  default = {
    region       = "eu-central-1"
    vpc          = "vpc-05b99d75d75889e66"
    ami          = "ami-0b828c1c5ac3f13ee"
    itype        = "t2.micro"
    subnet       = "    subnet-04005e0954febd470"
    publicip     = true
    keyname      = "myseckey"
    secgroupname = "IAC-Sec-Group"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}

resource "aws_security_group" "project-iac-sg" {
  name        = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  vpc_id      = lookup(var.awsprops, "vpc")

  // To Allow SSH Transport
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port   = 80
    protocol    = ""
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 443 Transport
  ingress {
    from_port   = 443
    protocol    = ""
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
  user_data = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install git
sudo apt-get install php7.4-mbstring
sudo apt-get install php7.4-xml
sudo apt-get install php7.4-xmlwriter
wget https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -O - -q | php -- --quiet
composer update
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
composer update
sudo mv composer.phar /usr/local/bin/composer
cd /home
git pull https://github.com/qirk4/Laravel-Support-Ticketing.git

EOF
}

resource "aws_instance" "project-iac" {
  ami                         = lookup(var.awsprops, "ami")
  instance_type               = lookup(var.awsprops, "itype")
  subnet_id                   = lookup(var.awsprops, "subnet")
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name                    = lookup(var.awsprops, "keyname")


  vpc_security_group_ids = [
    aws_security_group.project-iac-sg.id
  ]
  root_block_device {
    delete_on_termination = true
    iops                  = 150
    volume_size           = 50
    volume_type           = "gp2"
  }
  tags = {
    Name        = "SERVER01"
    Environment = "LARAVEL"
    OS          = "UBUNTU"
    Managed     = "IAC"
  }

  depends_on = [aws_security_group.project-iac-sg]
}


output "ec2instance" {
  value = aws_instance.project-iac.public_ip
}