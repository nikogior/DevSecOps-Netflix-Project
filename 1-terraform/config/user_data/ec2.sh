#!/bin/bash

install_jenkins(){
    # sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    #     https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    # echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
    #     https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    #     /etc/yum.repos.d/jenkins.repo > /dev/null
    # sudo yum update -y
    # sudo yum install jenkins -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
        https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf upgrade
    # Add required dependencies for the jenkins package
    sudo dnf install fontconfig java-21-openjdk -y
    sudo dnf install jenkins -y
    sudo systemctl daemon-reload
    sudo systemctl start jenkins
    sudo systemctl status jenkins
}
install_java_17(){
    sudo yum install temurin-17-jdk -y
    /usr/bin/java --version
}
install_docker(){
    sudo yum update
    sudo yum install docker -y
    sudo usermod -aG docker ec2-user   #my case is ubuntu
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
    sudo yum install wget -y
    sudo yum install yum-utils -y
    wget -qO - https://aquasecurity.github.io/trivy-repo/rpm/public.key | sudo rpm --import -
    sudo yum-config-manager --add-repo https://aquasecurity.github.io/trivy-repo/rpm/releases/x86_64/
    sudo yum update -y
    sudo yum install trivy -y
}
install_kubectl(){
    sudo yum update -y 
    sudo yum install curl -y
    curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
}
install_prometheus(){
    sudo useradd --system --no-create-home --shell /bin/false prometheus
    wget https://github.com/prometheus/prometheus/releases/download/v3.3.0/prometheus-3.3.0.linux-amd64.tar.gz
    tar xvfz prometheus-*.tar.gz
    cd prometheus-*
    sudo mkdir -p /data /etc/prometheus
    sudo mv prometheus promtool /usr/local/bin/
    sudo mv consoles/ console_libraries/ /etc/prometheus/
    sudo mv prometheus.yml /etc/prometheus/prometheus.yml
    sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
    cat <<EOF | sudo tee -a /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable prometheus
    sudo systemctl start prometheus
    sudo systemctl status prometheus
    # Accessed via: http://<your-server-ip>:9090
}

export http_proxy="http://cirrus-proxy.shared-services.local:8080"
export https_proxy="http://cirrus-proxy.shared-services.local:8080"

# # Install and start AWS Systems Manager (SSM) Agent
# sudo yum install -y amazon-ssm-agent
# sudo systemctl enable amazon-ssm-agent
# sudo systemctl start amazon-ssm-agent
# sudo systemctl status amazon-ssm-agent

# # Update and add required packages
# sudo yum update -y 
# wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/yum.repos.d/adoptium.repo
# echo "[adoptium]
# name=Adoptium
# baseurl=https://packages.adoptium.net/artifactory/rpm/$(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release)
# enabled=1
# gpgcheck=1
# gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public" | sudo tee /etc/yum.repos.d/adoptium.repo
# sudo yum update -y

# # ** Install Jenkins, Docker and Trivy on the EC2 **
# # Install Jenkins
# install_jenkins
# # Install Java 17
# install_java_17
# # Install Docker
# install_docker
# # Bring Up SonarQube
# setup_sonarqube
# # Install Trivy
# install_trivy
# # Install kubectl
# install_kubectl

# Open a new tab in the Browser and search for TMDB API key
# Create account, click Account Icon on the top right > Settings > API > Create API. Follow the steps and Generate the API

# Install Prometheus and Grafana 
# install_prometheus
