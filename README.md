# ELK Homelab — Automated Deployment

Terraform + Ansible automation for a 6-VM ELK stack on Proxmox, plus
Ansible-driven enrollment of Linux/Windows/Docker/K8s clients and syslog
configuration guidance for network gear.

## Layout

```
terraform/            # Creates 6 VMs on Proxmox from an Ubuntu 24.04 cloud-init template
ansible/
  inventory/          # Hosts file — edit IPs here after Terraform apply
  group_vars/         # Cluster-wide variables (passwords via Ansible Vault)
  roles/
    common/           # Base OS prep for ES nodes
    elasticsearch/    # 3-node cluster install + security bootstrap
    kibana/           # Kibana install + ES enrollment
    fleet_server/     # Fleet Server install
    logstash/         # Logstash + syslog pipeline
    client_linux/     # Installs Elastic Agent on Linux clients
    client_windows/   # Installs Elastic Agent on Windows clients
  playbooks/
    00-deploy-stack.yml       # End-to-end stack deployment
    10-enroll-linux.yml       # Enroll Linux fleet
    11-enroll-windows.yml     # Enroll Windows fleet
    20-apply-ilm.yml          # Apply retention policies
```

## Prerequisites

1. Proxmox host reachable with an API token (`Datacenter → Permissions → API Tokens`)
2. An Ubuntu 24.04 cloud-init template in Proxmox named `ubuntu-2404-cloud`
   (or change the name in `terraform/variables.tf`)
3. Terraform ≥ 1.6, Ansible ≥ 2.15 on your workstation
4. SSH key pair — public key goes into the cloud-init template

## Usage

```bash
# 1. Create the VMs
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in
terraform init && terraform apply

# 2. Terraform writes ansible/inventory/hosts.ini automatically
cd ../ansible

# 3. Encrypt your secrets
ansible-vault create group_vars/all/vault.yml
#   vault_elastic_bootstrap_pw: "choose-a-strong-one"
#   vault_kibana_system_pw: "another-strong-one"
#   vault_logstash_writer_pw: "yet-another"

# 4. Deploy the stack
ansible-playbook playbooks/00-deploy-stack.yml --ask-vault-pass

# 5. Enroll clients (after adding their IPs to inventory)
ansible-playbook playbooks/10-enroll-linux.yml --ask-vault-pass
ansible-playbook playbooks/11-enroll-windows.yml --ask-vault-pass

# 6. Apply retention / ILM policies
ansible-playbook playbooks/20-apply-ilm.yml --ask-vault-pass
```

Network gear (pfSense, UniFi, switches) can't be configured via Ansible in
a uniform way — send syslog to `logstash.lan:5514` per the README section
at the bottom.
