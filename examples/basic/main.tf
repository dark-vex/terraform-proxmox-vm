terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.83.0"
    }
  }
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_username" {
  description = "Proxmox API username (e.g. root@pam)"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key content for cloud-init"
  type        = string
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
}

module "vm" {
  source = "github.com/dark-vex/terraform-proxmox-vm?ref=v1.0.0"

  name      = "example-vm"
  vmid      = 100
  node_name = "pve"

  cpu_cores = 2
  memory    = 2048

  cloud_init_datastore_id = "local-lvm"

  disks = {
    boot = {
      datastore_id = "local-lvm"
      interface    = "scsi0"
      size         = 20
    }
  }

  ip_config = {
    ipv4_address = "192.168.1.100/24"
    ipv4_gateway = "192.168.1.1"
  }

  ssh_keys = [var.ssh_public_key]
}
