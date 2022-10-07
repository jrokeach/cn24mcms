#!/bin/bash

# Collect inputs
# Note that this currently only supports a statically assumed 1 master and 3 workers.
# Ideally, this should be taken from a configuration file along with service IP address information.
set -a
read -sp "jcluser password: " WORKER_PASS
echo -e "\r\nPlease note that the following IP addresses are all the management IP addresses.\r\nService (eth1) IP addresses are currently statically defined in master-stage1.yml > 'Set up ansible hosts file'."
read -p "k8s-master mgt ip [100.123.35.1]: " k8s_master_mgtip
read -p "k8s-worker1 mgt ip [100.123.35.2]: " k8s_worker1_mgtip
read -p "k8s-worker2 mgt ip [100.123.35.3]: " k8s_worker2_mgtip
read -p "k8s-worker3 mgt ip [100.123.35.4]: " k8s_worker3_mgtip
echo

sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install git ansible -y
sudo -u $(logname) git clone --branch v0.0.2_dev --depth 1 https://github.com/jrokeach/cn24mcms.git
cd cn24mcms
sudo ansible-galaxy collection install community.general community.crypto ansible.posix
sudo -u $(logname) bash -c "(
	cd k8s-setup ;
	ansible-playbook master-stage1.yml --extra-vars 'ansible_sudo_pass=$WORKER_PASS k8s_master_mgtip=$k8s_master_mgtip k8s_worker1_mgtip=$k8s_worker1_mgtip k8s_worker2_mgtip=$k8s_worker2_mgtip k8s_master_mgtip=$k8s_worker2_mgtip
')"
sudo -u $(logname) bash -c "(
        cd k8s-setup ;
        ansible-playbook worker.yml  --extra-vars 'ansible_sudo_pass=$WORKER_PASS ansible_ssh_pass=$WORKER_PASS'
)"
sudo -u $(logname) bash -c '( cd ../kubespray ; ansible-playbook cluster.yml )'
sudo -u $(logname) bash -c '( cd k8s-setup ; ansible-playbook master-stage2.yml )'
