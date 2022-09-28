# Contrail for MCMS

## Step-by-step

1. Build lab environment as per [lab topology](lab_topology.jpg).
2. Log in to `k8s-master`
3. On `k8s-master`:
   1. Install ansible requirements
   	```bash
	sudo apt-get install ansible -y
   sudo ansible-galaxy collection install community.general
   ```
   2. Copy `templates/`, `master-playbook.yml`, and `worker-playbook.yml` to the server.
   3. Modify the values specified in `master-playbook.yml` as required.
   4. Run the k8s-master playbook:
   ```bash
   ansible-playbook master-playbook.yml --ask-become
   ```
   5. Run the worker playbook:
   ```bash
   ansible-playbook worker-playbook.yml --ask-become
   ```