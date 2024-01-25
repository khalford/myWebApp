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
snap install terraform --classic
