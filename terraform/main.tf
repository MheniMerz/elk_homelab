terraform {
  required_version = ">= 1.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
  ssh {
    agent    = true
    username = var.proxmox_ssh_user
  }
}

# -----------------------------------------------------------------------------
# VM definitions — 3x Elasticsearch, 1x Kibana, 1x Fleet, 1x Logstash
# -----------------------------------------------------------------------------

locals {
  vms = {
    es01 = { vmid = 9001, cores = 4, memory = 8192, disk = 200, ip = var.ip_es01, role = "elasticsearch" }
    es02 = { vmid = 9002, cores = 4, memory = 8192, disk = 200, ip = var.ip_es02, role = "elasticsearch" }
    es03 = { vmid = 9003, cores = 4, memory = 8192, disk = 200, ip = var.ip_es03, role = "elasticsearch" }
    kibana   = { vmid = 9010, cores = 2, memory = 2048, disk = 20, ip = var.ip_kibana, role = "kibana" }
    fleet    = { vmid = 9011, cores = 2, memory = 2048, disk = 20, ip = var.ip_fleet, role = "fleet" }
    logstash = { vmid = 9012, cores = 2, memory = 4096, disk = 40, ip = var.ip_logstash, role = "logstash" }
  }
}

resource "proxmox_virtual_environment_vm" "elk" {
  for_each = local.vms

  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vmid
  tags      = ["elk", each.value.role]
  started = true

  clone {
    vm_id = var.template_vmid
    full  = true
  }

  agent {
    enabled = true
    timeout = "5m"
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = each.value.disk
    file_format  = "raw"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.storage_pool
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.subnet_cidr_bits}"
        gateway = var.gateway
      }
    }
    dns {
      servers = var.dns_servers
    }
    user_account {
      username = var.vm_user
      keys     = [trimspace(file(var.ssh_public_key_path))]
    }
  }

  operating_system {
    type = "l26"
  }
  
}




# -----------------------------------------------------------------------------
# Auto-generate the Ansible inventory from the VMs we just created
# -----------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.ini"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/hosts.ini.tftpl", {
    es01_ip     = var.ip_es01
    es02_ip     = var.ip_es02
    es03_ip     = var.ip_es03
    kibana_ip   = var.ip_kibana
    fleet_ip    = var.ip_fleet
    logstash_ip = var.ip_logstash
    ansible_user = var.vm_user
  })

  depends_on = [proxmox_virtual_environment_vm.elk]
}
