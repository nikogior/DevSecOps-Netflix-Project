terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }
  }
}

data "aws_availability_zones" "available" {}

provider "aws" {
  region = local.region
  # profile = "comcastbackup"
}

locals {
  # name   = "ex-${basename(path.cwd)}"
  name   = "ex-ec2-instance"
  region = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  user_data = <<-EOT
    #!/bin/bash
    # Install Jenkins, Docker and Trivy on the EC2
    sudo apt update -y 
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
    sudo apt update -y

    # Install Java 17
    sudo apt install temurin-17-jdk -y
    /usr/bin/java --version

    # Install Jenkins
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl status jenkins

    # Install Docker
    sudo apt-get update
    sudo apt-get install docker.io -y
    sudo usermod -aG docker $USER   #my case is ubuntu
    newgrp docker
    sudo chmod 777 /var/run/docker.sock
    sudo usermod -aG docker jenkins #add jenkins user to Docker group
    sudo systemctl restart jenkins

    # Bring Up SonarQube
    docker run -d --name sonar -p 9000:9000 sonarqube:lts-community


  EOT

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  }
}
