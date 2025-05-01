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

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

apt-get update
apt-get install -y docker.io vim build-essential jq jc python3-pip kubelet kubectl kubernetes-cni kubeadm

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker
systemctl enable docker
systemctl enable kubelet
systemctl start kubelet

echo ".........----------------#################._.-.-KUBERNETES-.-._.#################----------------........."
set -e

echo "[Step 1] Disable swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "[Step 2] Load kernel modules"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo modprobe br_netfilter

echo "[Step 3] Set sysctl params"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

echo "[Step 4] Install containerd"
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[Step 5] Add Kubernetes repo"
sudo apt-get update
sudo apt-get install -y apt-transport-https curl gnupg
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo "deb https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "[Step 6] Install kubelet, kubeadm, kubectl"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[Step 7] Initialize Kubernetes cluster with Weave Net CIDR"
kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers --v=9
sudo kubeadm init --apiserver-advertise-address=192.168.0.88 --pod-network-cidr=10.32.0.0/12 # 192.168.0.88 is your vm ip, change it with your vm ip

echo "[Step 8] Configure kubectl for current user"
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[Step 9] Install Weave Net CNI"
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
sleep 60

echo "[Step 10] Allow scheduling pods on the control-plane node"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

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
wget http://archive.ubuntu.com/ubuntu/pool/main/i/init-system-helpers/init-system-helpers_1.56+nmu1~ubuntu18.04.1_all.deb
sudo dpkg -i init-system-helpers_1.56+nmu1~ubuntu18.04.1_all.deb
sudo apt update
sudo apt install -y jenkins
systemctl daemon-reload
systemctl enable jenkins
sudo systemctl start jenkins
#sudo systemctl status jenkins
sudo usermod -a -G docker jenkins
echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
