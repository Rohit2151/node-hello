# K8S setup

AWS infrastructure and EKS cluster with all required services and YAML configurations.

---

 1. Infrastructure Requirements

 AWS Services: VPC, EKS, RDS, S3, ECR
 IAM Roles: Cluster, Node Group, Jump Server
 Monitoring & GitOps: Grafana, Loki, Prometheus, ArgoCD
 Jump Server: Bastion host for secure cluster access

---

 2. VPC & Networking

 VPC CIDR: `10.0.0.0/16`
 Subnets:

   Public: `10.0.0.0/20`, `10.0.16.0/20`
   Private: `10.0.128.0/20`, `10.0.144.0/20`
 Route Tables:

   Public → Internet Gateway
   Private → NAT Gateway

---

 3. EKS Cluster Setup

Create cluster IAM role: `AmazonEKSClusterPolicy`

Create cluster with AWS consile:

---

 4. Node Group Migration


# Cordon old nodes
kubectl cordon node-1

# Drain pods (skip daemonsets)
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data

# Verify pods
kubectl get pods -o wide

# Delete old node group
eksctl delete nodegroup --cluster node-eks-cluster --name node-1

---

 5. Jump Server Setup

Install required packages:

sudo apt update && sudo apt install -y curl nginx
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo snap install kubectl --classic

# Configure kubeconfig
aws eks update-kubeconfig --name node-eks-cluster --region ap-southeast-4

---

 6. RDS Setup

 Launch in private subnets
 Security group: allow EKS nodes and Jump Server access

---

 7. Cluster Security

 Access controlled via Jump Server only, Allow specific IP on EKS SG for HTTPS (443)

---

 8. Autoscaling Setup

Install Metrics Server:

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

Cluster Autoscaler IAM policy:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:Describe",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ""
    }
  ]
}

Create IAM role and attach to service account:

eksctl utils associate-iam-oidc-provider --region ap-southeast-4 --cluster node-eks-cluster --approve

eksctl create iamserviceaccount \
  --cluster project-eks-cluster \
  --namespace kube-system \
  --name cluster-autoscaler \
  --attach-policy-arn arn:aws:iam::541428895748:policy/ClusterAutoscalerPolicy \
  --approve \
  --override-existing-serviceaccounts

Install via Helm:

helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=project-eks-cluster \
  --set awsRegion=ap-southeast-4 \
  --set rbac.serviceAccount.create=true \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set extraArgs.balance-similar-node-groups=true \
  --set extraArgs.skip-nodes-with-local-storage=false \
  --set extraArgs.expander=least-waste
  
---

 9. NGINX Ingress Setup
nginx-ingress-public-lb.yaml

Apply:
kubectl apply -f nginx-ingress-public-lb.yaml

---

 10. ECR Setup
 Create private repository per project stack
 Push Docker images for deployment

---
