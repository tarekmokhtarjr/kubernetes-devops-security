#!/bin/bash

echo ".........----------------#################._.-.-Caution-.-._.#################----------------........."
echo "It's recommended to run this script as a root user or a super user and with sudo"
echo "If you are running this script on a virtualbox vm and you want to set a maunal ip address then follow the steps:"
echo "    - First set the network adapter to bridged"
echo "    - Use the template in network-config-template"
echo "    - run -> sudo netplan apply"
echo "#######################################################################################################"


echo ".........----------------#################._.-.-INSTALL-.-._.#################----------------........."
PS1='\[\e[01;36m\]\u\[\e[01;37m\]@\[\e[01;33m\]\H\[\e[01;37m\]:\[\e[01;32m\]\w\[\e[01;37m\]\$\[\033[0;37m\] '
echo "PS1='\[\e[01;36m\]\u\[\e[01;37m\]@\[\e[01;33m\]\H\[\e[01;37m\]:\[\e[01;32m\]\w\[\e[01;37m\]\$\[\033[0;37m\] '" >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc
source ~/.bashrc

apt-get autoremove -y  #removes the packages that are no longer needed
apt-get update
systemctl daemon-reload
apt-get update
apt-get install -y docker.io python3-pip 

echo ".........----------------#################._.-.-KUBERNETES-.-._.#################----------------........."
echo "Kubernetes will be installed using K3S"
set -e

echo "[Step 1] Disable swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
echo "[Step 2] Install K3S"
curl -sfL https://get.k3s.io | sh -

echo "Check Kubernetes is installed and ready."
kubectl get nodes

echo ".........----------------#################._.-.-Java and MAVEN-.-._.#################----------------........."
sudo apt install openjdk-17-jdk -y
java -version
sudo apt install -y maven
mvn -v



echo ".........----------------#################._.-.-JENKINS-.-._.#################----------------........."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev$
curl -O http://archive.ubuntu.com/ubuntu/pool/main/i/init-system-helpers/init-system-helpers_1.56+nmu1~ubuntu18.04.1_all.deb
sudo dpkg -i init-system-helpers_1.56+nmu1~ubuntu18.04.1_all.deb
sudo apt update
sudo apt install -y jenkins
systemctl daemon-reload
systemctl enable jenkins
sudo systemctl start jenkins
#sudo systemctl status jenkins
sudo usermod -a -G docker jenkins
echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
