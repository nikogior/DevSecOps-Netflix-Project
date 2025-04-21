#!/bin/bash

install_jenkins(){
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
        https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
        https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl status jenkins
}
install_java_17(){
    sudo apt install temurin-17-jdk -y
    /usr/bin/java --version
}
install_docker(){
    sudo apt-get update
    sudo apt-get install docker.io -y
    sudo usermod -aG docker $USER   #my case is ubuntu
    newgrp docker
    sudo chmod 777 /var/run/docker.sock
    sudo usermod -aG docker jenkins #add jenkins user to Docker group
    sudo systemctl restart jenkins
}
setup_sonarqube(){
    docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
    sudo docker run -d --name sonar \
        -p 9000:9000 \
        # -e SONAR_JDBC_URL=jdbc:postgresql://sonar-db:5432/sonar \
        # -e SONAR_JDBC_USERNAME=sonar \
        # -e SONAR_JDBC_PASSWORD=sonar \
        sonarqube:lts-community
}
install_trivy(){
    sudo apt-get install wget apt-transport-https gnupg lsb-release -y
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
    # wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
    # echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update -y
    sudo apt-get install trivy -y
}
install_kubectl(){
    sudo apt update -y 
    sudo apt install curl -y
    curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
}

# Update and add required packages
sudo apt update -y 
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y

# ** Install Jenkins, Docker and Trivy on the EC2 **
# Install Jenkins
install_jenkins
# Install Java 17
install_java_17
# Install Docker
install_docker
# Bring Up SonarQube
setup_sonarqube
# Install Trivy
install_trivy
# Install kubectl
install_kubectl