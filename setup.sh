#!/bin/bash
apt update
apt upgrade -y
apt install python3 -y
apt install python3-pip -y
apt install python3-venv -y
python3 -m venv ansible-venv
source ansible-venv/bin/activate
pip3 install ansible
pip3 install openstacksdk
apt-get update && apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt-get install terraform -y
