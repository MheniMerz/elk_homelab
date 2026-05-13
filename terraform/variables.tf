variable "proxmox_endpoint" {
  description = "Proxmox API URL, e.g. https://pve.lan:8006/"
  type        = string
  default     = "https://192.168.1.121:8006/"
}

variable "proxmox_api_token" {
  description = "API token in the form USER@REALM!TOKENID=SECRET"
  type        = string
  sensitive   = true
  default     = "root@pam!elk-deployment=58be1ab1-836c-48ec-b802-b7c1ad748559"
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (self-signed Proxmox cert)"
  type        = bool
  default     = true
}

variable "proxmox_ssh_user" {
  description = "SSH user on the Proxmox host (needed by the bpg provider for some ops)"
  type        = string
  default     = "root"
}

variable "proxmox_node" {
  description = "Proxmox node name to deploy VMs on"
  type        = string
}

variable "template_vmid" {
  description = "VMID of the Ubuntu 24.04 cloud-init template to clone"
  type        = number
}

variable "storage_pool" {
  description = "Proxmox storage pool (e.g. local-lvm, local-zfs)"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge (e.g. vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "subnet_cidr_bits" {
  description = "Subnet CIDR bits (e.g. 24 for /24)"
  type        = number
  default     = 24
}

variable "dns_servers" {
  type    = list(string)
  default = ["1.1.1.1", "9.9.9.9"]
}

variable "vm_user" {
  description = "Cloud-init user created on each VM — Ansible will SSH as this user"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

# Static IPs — set these to free addresses in your homelab subnet
variable "ip_es01"     { type = string }
variable "ip_es02"     { type = string }
variable "ip_es03"     { type = string }
variable "ip_kibana"   { type = string }
variable "ip_fleet"    { type = string }
variable "ip_logstash" { type = string }
