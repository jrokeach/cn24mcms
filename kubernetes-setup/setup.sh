#!/bin/bash

echo "Enter your jcluser password:"
read -s WORKER_PASS

sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install ansible -y
sudo ansible-galaxy collection install community.general community.crypto ansible.posix
sudo bash -c '( cd k8s-setup ; ansible-playbook master-stage1.yml )'
sudo -u $(logname) bash -c "( cd k8s-setup ; ansible-playbook worker.yml  --extra-vars 'ansible_sudo_pass=$WORKER_PASS ansible_pass=$WORKER_PASS' )"
sudo -u $(logname) bash -c '( cd ../kubespray ; ansible-playbook cluster.yml )'
sudo -u $(logname) bash -c '( cd k8s-setup ; ansible-playbook master-stage2.yml )'