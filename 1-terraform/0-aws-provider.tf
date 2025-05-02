# Common resources:
# - VPC: britebill-ms360-52590630-VPC-003: vpc-091f24c021616d3e7
# - SUBNETS: 
# - britebill-ms360-52590630-VPC-003-DATA-AZ-1	subnet-06071e5712141343f 
# - britebill-ms360-52590630-VPC-003-DATA-AZ-2	subnet-0767cf2c8acdf8c31
# - britebill-ms360-52590630-VPC-003-DATA-AZ-3	subnet-0cac7670b94b35341
# - britebill-ms360-52590630-VPC-003-UTILS-AZ-1	subnet-032482e5102ca0bb1
# - britebill-ms360-52590630-VPC-003-UTILS-AZ-2	subnet-04725e435f5c5a482
# - britebill-ms360-52590630-VPC-003-UTILS-AZ-3	subnet-045729cf1d381b7f5
# - britebill-ms360-52590630-VPC-003-WORKERS-AZ-1	subnet-0f0e543c4bd28d9dd eu-west-1a
# - britebill-ms360-52590630-VPC-003-WORKERS-AZ-2	subnet-030db4822e11f59f3 eu-west-1b
# - britebill-ms360-52590630-VPC-003-WORKERS-AZ-3	subnet-0c8ce64cf9cb27b68 eu-west-1c
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.96.0"
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
