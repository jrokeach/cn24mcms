#!/bin/bash

if [ "$EUID" -eq 0 ]
  then echo "Please run as jcluser"
  exit
fi

# Collect inputs
# Note that this currently only supports a statically assumed 1 master and 3 workers.
# Ideally, this should be taken from a configuration file along with service IP address information.
set -a

WORKER_PASS=$(cat /proc/sys/kernel/random/uuid)
WORKER_PASS_CONFIRM=$(cat /proc/sys/kernel/random/uuid)
WORKER_PASS_ORIGINAL=$WORKER_PASS
until [ "$WORKER_PASS" = "$WORKER_PASS_CONFIRM" ]
do
	if [ "$WORKER_PASS" != "$WORKER_PASS_ORIGINAL" ]
	then
		echo "Passwords didn't match. Please try again."
	fi
	WORKER_PASS=$(cat /proc/sys/kernel/random/uuid)
	WORKER_PASS_CONFIRM=$(cat /proc/sys/kernel/random/uuid)
	read -sp "jcluser password: " WORKER_PASS
	echo
	read -sp "(Confirm) jcluser password: " WORKER_PASS_CONFIRM
	echo
done
unset WORKER_PASS_CONFIRM
unset WORKER_PASS_ORIGINAL

confirm_settings="n"
until [[ ${confirm_settings} =~ [yY] ]]
do
	echo -e "\r\nPlease note that the following IP addresses are all the management IP addresses.\r\nService (eth1) IP addresses are currently statically defined in master-stage1.yml > 'Set up ansible hosts file'."
	read -p "k8s-master mgt ip [100.123.35.1]: " k8s_master_mgtip
	read -p "k8s-worker1 mgt ip [100.123.35.2]: " k8s_worker1_mgtip
	read -p "k8s-worker2 mgt ip [100.123.35.3]: " k8s_worker2_mgtip
	read -p "k8s-worker3 mgt ip [100.123.35.4]: " k8s_worker3_mgtip
	echo
	echo "You have defined the following parameters:"
	echo "k8s-master mgt ip: ${k8s_master_mgtip:-100.123.35.1}"
	echo "k8s-master mgt ip: ${k8s_worker1_mgtip:-100.123.35.2}"
	echo "k8s-master mgt ip: ${k8s_worker2_mgtip:-100.123.35.3}"
	echo "k8s-master mgt ip: ${k8s_worker3_mgtip:-100.123.35.4}"
	read -p "Confirm [y/N]: " confirm_settings
done
unset confirm_settings

# Get required repositories, software, and execute playbooks.
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install git ansible -y
git clone --branch v0.0.2_dev --depth 1 https://github.com/jrokeach/cn24mcms.git
cd cn24mcms
sudo ansible-galaxy collection install community.general community.crypto ansible.posix
bash -c "(
	cd k8s-setup ;
	ansible-playbook master-stage1.yml --extra-vars 'ansible_sudo_pass=$WORKER_PASS k8s_master_mgtip=$k8s_master_mgtip k8s_worker1_mgtip=$k8s_worker1_mgtip k8s_worker2_mgtip=$k8s_worker2_mgtip k8s_master_mgtip=$k8s_worker2_mgtip'
)"
bash -c "(
        cd k8s-setup ;
        ansible-playbook worker.yml  --extra-vars 'ansible_sudo_pass=$WORKER_PASS ansible_ssh_pass=$WORKER_PASS'
)"
bash -c '( cd ../kubespray ; ansible-playbook cluster.yml )'
bash -c '( cd k8s-setup ; ansible-playbook master-stage2.yml )'
