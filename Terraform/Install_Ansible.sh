#! /bin/bash
echo "Installing Epel Release"
sudo yum install epel-release -y
echo "Updating Repository"
sudo yum update
echo "Installing Ansible"
sudo yum install ansible -y
