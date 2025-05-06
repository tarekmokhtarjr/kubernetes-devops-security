#!/bin/bash

apt-get autoremove -y  #removes the packages that are no longer needed
apt-get update
systemctl daemon-reload

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
sudo apt-get install -y docker.io vim build-essential jq jc python3-pip kubelet kubeadm kubectl kubernetes-cni
sudo apt-mark hold kubelet kubeadm kubectl

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

echo "[Step 7] Initialize Kubernetes cluster with Weave Net CIDR"
kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers --v=9
sudo kubeadm init --apiserver-advertise-address=192.168.56.100/24

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

