#!/bin/bash

# Script setup
USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Redirect output to log file
exec > >(tee -a $LOGFILE) 2>&1

# Validation function
VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "$2...$R FAILURE $N"
    exit 1
  else
    echo -e "$2...$G SUCCESS $N"
  fi
}

# Check for root user
if [ $USERID -ne 0 ]; then
  echo -e "$R Please run this script with root access. $N"
  exit 1
else
  echo -e "$G You are super user. $N"
fi

echo -e "$Y ==== Installing Docker ==== $N"
yum install -y yum-utils
VALIDATE $? "Installing yum-utils"

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
VALIDATE $? "Adding Docker repo"

yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
VALIDATE $? "Installing Docker packages"

systemctl start docker
VALIDATE $? "Starting Docker service"

systemctl enable docker
VALIDATE $? "Enabling Docker service"

usermod -aG docker ec2-user
VALIDATE $? "Adding ec2-user to Docker group"

echo -e "$Y ==== Installing eksctl ==== $N"
yum install -y curl tar
VALIDATE $? "Installing curl and tar"

curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" -o /tmp/eksctl.tar.gz
VALIDATE $? "Downloading eksctl"

tar -xzf /tmp/eksctl.tar.gz -C /tmp
VALIDATE $? "Extracting eksctl"

mv /tmp/eksctl /usr/local/bin/
VALIDATE $? "Moving eksctl to /usr/local/bin"

chmod +x /usr/local/bin/eksctl
VALIDATE $? "Making eksctl executable"

eksctl version
VALIDATE $? "Verifying eksctl installation"

echo -e "$Y ==== Installing kubectl ==== $N"
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/amd64/kubectl
VALIDATE $? "Downloading kubectl"

chmod +x ./kubectl
VALIDATE $? "Making kubectl executable"

mv kubectl /usr/local/bin/kubectl
VALIDATE $? "Moving kubectl to /usr/local/bin"

kubectl version --client
VALIDATE $? "Verifying kubectl installation"

echo -e "$Y ==== Installing kubens ==== $N"
yum install -y git
VALIDATE $? "Installing git"

if [ ! -d "/opt/kubectx" ]; then
  git clone https://github.com/ahmetb/kubectx /opt/kubectx
  VALIDATE $? "Cloning kubectx repository"
else
  echo -e "$Y /opt/kubectx already exists, skipping clone. $N"
fi

ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
VALIDATE $? "Linking kubens to /usr/local/bin"

kubens --help &>/dev/null
VALIDATE $? "Verifying kubens installation"

echo -e "$G ==== All installations completed successfully! ==== $N"


# # Helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh
# VALIDATE $? "helm installation"