#!/bin/bash
set -euo pipefail

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0" | cut -d. -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

exec > >(tee -a $LOGFILE) 2>&1

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "$2...$R FAILURE $N"
    exit 1
  else
    echo -e "$2...$G SUCCESS $N"
  fi
}

if [ $USERID -ne 0 ]; then
  echo -e "$R Please run this script with root access. $N"
  exit 1
else
  echo -e "$G You are super user. $N"
fi

#####################################
# Docker Installation
#####################################
if ! command -v docker &>/dev/null; then
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
  echo -e "$Y Please log out and back in for group changes to take effect. $N"
else
  echo -e "$G Docker already installed, skipping. $N"
fi

#####################################
# eksctl Installation
#####################################
if ! command -v eksctl &>/dev/null; then
  echo -e "$Y ==== Installing eksctl ==== $N"

  yum install -y curl tar
  VALIDATE $? "Installing curl and tar"

  ARCH=$(uname -m)
  if [ "$ARCH" == "x86_64" ]; then
    PLATFORM="amd64"
  elif [ "$ARCH" == "aarch64" ]; then
    PLATFORM="arm64"
  else
    echo -e "$R Unsupported architecture: $ARCH $N"
    exit 1
  fi

  curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_${PLATFORM}.tar.gz" -o /tmp/eksctl.tar.gz
  VALIDATE $? "Downloading eksctl"

  tar -xzf /tmp/eksctl.tar.gz -C /tmp
  VALIDATE $? "Extracting eksctl"

  EKSCTL_PATH=$(find /tmp -type f -name eksctl | head -n 1)
  if [ -f "$EKSCTL_PATH" ]; then
    mv "$EKSCTL_PATH" /usr/local/bin/eksctl
    VALIDATE $? "Moving eksctl to /usr/local/bin"
    chmod +x /usr/local/bin/eksctl
    VALIDATE $? "Making eksctl executable"
  else
    echo -e "$R eksctl binary not found after extraction. $N"
    exit 1
  fi
else
  echo -e "$G eksctl already installed, skipping. $N"
fi

#####################################
# kubectl Installation
#####################################
if ! command -v kubectl &>/dev/null; then
  echo -e "$Y ==== Installing kubectl ==== $N"

  ARCH=$(uname -m)
  if [ "$ARCH" == "x86_64" ]; then
    PLATFORM="amd64"
  elif [ "$ARCH" == "aarch64" ]; then
    PLATFORM="arm64"
  else
    echo -e "$R Unsupported architecture: $ARCH $N"
    exit 1
  fi

  curl -o /tmp/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/${PLATFORM}/kubectl
  VALIDATE $? "Downloading kubectl"

  chmod +x /tmp/kubectl
  VALIDATE $? "Making kubectl executable"

  mv /tmp/kubectl /usr/local/bin/kubectl
  VALIDATE $? "Moving kubectl to /usr/local/bin"
else
  echo -e "$G kubectl already installed, skipping. $N"
fi

# #####################################
# # kubens Installation
# #####################################
# if ! command -v kubens &>/dev/null; then
#   echo -e "$Y ==== Installing kubens ==== $N"
#   yum install -y git
#   VALIDATE $? "Installing git"

#   if [ ! -d "/opt/kubectx" ]; then
#     git clone https://github.com/ahmetb/kubectx /opt/kubectx
#     VALIDATE $? "Cloning kubectx repository"
#   else
#     echo -e "$Y /opt/kubectx already exists, skipping clone. $N"
#   fi

#   ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
#   VALIDATE $? "Linking kubens to /usr/local/bin"
# else
#   echo -e "$G kubens already installed, skipping. $N"
# fi

#####################################
# PATH fix
#####################################
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
  echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
  export PATH=$PATH:/usr/local/bin
  echo -e "$G Added /usr/local/bin to PATH $N"
fi

#####################################
# echo -e "$G ==== All installations completed successfully! ==== $N"
# eksctl version
# kubectl version 
# kubens --help | head -n 2


# # Helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh
# VALIDATE $? "helm installation"