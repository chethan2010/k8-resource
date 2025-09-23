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

exec > >(tee -a "$LOGFILE") 2>&1

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

# Get latest version
EKSCTL_LATEST=$(curl -s https://api.github.com/repos/eksctl-io/eksctl/releases/latest | grep tag_name | cut -d '"' -f4)
VALIDATE $? "Fetching latest eksctl version"

curl -sL "https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_LATEST}/eksctl_Linux_${PLATFORM}.tar.gz" -o /tmp/eksctl.tar.gz
VALIDATE $? "Downloading eksctl ${EKSCTL_LATEST}"

tar -xzf /tmp/eksctl.tar.gz -C /tmp
VALIDATE $? "Extracting eksctl"

mv /tmp/eksctl /usr/local/bin/eksctl
chmod +x /usr/local/bin/eksctl
VALIDATE $? "Installing eksctl"

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

  curl -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/${PLATFORM}/kubectl
  VALIDATE $? "Downloading kubectl"

  chmod +x /usr/local/bin/kubectl
  VALIDATE $? "Installing kubectl"
else
  echo -e "$G kubectl already installed, skipping. $N"
fi

#####################################
# Add /usr/local/bin to PATH for ec2-user and root
#####################################
for USER_HOME in /root /home/ec2-user; do
  if ! grep -q "/usr/local/bin" "$USER_HOME/.bashrc"; then
    echo 'export PATH=$PATH:/usr/local/bin' >> "$USER_HOME/.bashrc"
    echo -e "$G Added /usr/local/bin to PATH for $USER_HOME $N"
  fi
done

# #####################################
# # Final Check and Version Outputs
# #####################################
# echo -e "$G ==== All installations completed successfully! ==== $N"

# echo -e "$Y Docker Version: $N"
# docker --version || echo -e "$R Docker not available in this shell. Try re-logging. $N"

# echo -e "$Y eksctl Version: $N"
# eksctl version || echo -e "$R eksctl not found. $N"

# echo -e "$Y kubectl Version: $N"
# kubectl version --client || echo -e "$R kubectl not found. $N"

# echo -e "$Y kubens Version: $N"
# kubens --help | head -n 2 || echo -e "$R kubens not found. $N"

# echo -e "$Y Helm Version: $N"
# helm version || echo -e "$R helm not found. $N"
