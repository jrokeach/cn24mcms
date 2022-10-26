# Contrail Networking 2 for MCMS

## k8s JCL Quickstart

1. Build lab environment as per [lab topology](lab_topology.jpg).
2. On `k8s-master`, run the installer script
   	```bash
	bash <(curl -s https://raw.githubusercontent.com/jrokeach/cn24mcms/v0.0.3/setup.sh)
   ```