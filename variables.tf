variable "name" {
  description = "VM name/hostname"
  type        = string
}

variable "vmid" {
  description = "VM ID"
  type        = number
}

variable "node_name" {
  description = "Target Proxmox node name"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = ""
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "cpu_sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}
variable "cpu_type" {
  description = "CPU type (e.g., host, x86-64-v2-AES)"
  type        = string
  default     = "host"
}


variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "machine" {
  description = "Machine settings"
  type        = string
  default     = ""
}

variable "disks" {
  description = "Mappa dei dischi virtuali"
  # La chiave della mappa sarà un nome logico (es. 'boot', 'storage')
  type = map(object({
    backup       = optional(bool, true)
    datastore_id = string
    interface    = string # Es. scsi0, scsi1 (FONDAMENTALE che sia univoco)
    size         = number
    file_format  = optional(string, "raw")
    file_id      = optional(string)
    iothread     = optional(bool, true)
    ssd          = optional(bool, true)
    discard      = optional(string, "on")
  }))
  default = {}
}

variable "network_devices" {
  description = "Map of network devices"
  type = map(object({
    bridge       = optional(string, "vmbr0")
    mac_address  = optional(string)
    disconnected = optional(bool, false)
    firewall     = optional(bool, false)
    model        = optional(string, "virtio")
    vlan_id      = optional(number)
  }))
  default = {
    net0 = {
      bridge = "vmbr0"
    }
  }
}

variable "ip_config" {
  description = "IP configuration"
  type = object({
    ipv4_address = optional(string, "dhcp")
    ipv4_gateway = optional(string)
    ipv6_address = optional(string)
    ipv6_gateway = optional(string)
  })
  default = {
    ipv4_address = "dhcp"
  }
}

variable "ssh_keys" {
  description = "List of SSH public keys"
  type        = list(string)
  default     = []
}

variable "cloud_init_user" {
  description = "Cloud-init username"
  type        = string
  default     = "ubuntu"
}

variable "cloud_init_password" {
  description = "Cloud-init password"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloud_init_file_id" {
  description = "Cloud-init user data file ID"
  type        = string
  default     = null
}

variable "cloud_init_dns" {
  description = "Cloud-init DNS configuration"
  type = object({
    domain  = optional(string)
    servers = optional(list(string))
  })
  default = {}
}

variable "tags" {
  description = "Resource tags"
  type        = list(string)
  default     = ["automation"]
}

variable "started" {
  description = "Whether VM should be started after creation"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Whether VM should start on host boot"
  type        = bool
  default     = true
}

variable "agent_enabled" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = true
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "l26" # Linux 2.6+ kernel
}

variable "bios_type" {
  description = "BIOS type"
  type        = string
  default     = "seabios"
}

variable "protection" {
  description = "Enable VM protection to prevent accidental deletion"
  type        = bool
  default     = false
}

variable "efi_disk" {
  type = object({
    datastore_id      = string
    file_format       = optional(string)
    type              = optional(string)
    pre_enrolled_keys = optional(bool)
  })
  default = null
}

variable "cdrom" {
  description = "Configurazione del CD-ROM"
  type = object({
    file_id   = string
    interface = optional(string, "ide2")
  })
  default = null
}

variable "cloud_init_datastore_id" {
  description = "Datastore per il disco Cloud-Init. Se null, Cloud-Init viene disabilitato."
  type        = string
  default     = null
}

variable "boot_order" {
  description = "Boot order (es. 'cdn' per CD-ROM, disco, network)"
  type        = list(string)
  default     = ["scsi0"]
}

variable "additional_runcmd" {
  description = "Extra runcmd entries rendered into a vendor-data cloud-init snippet, merged at boot with the module's own generated user-data. Only takes effect when cloud_init_datastore_id is set and cloud_init_file_id is null (a custom user-data snippet's runcmd always wins over vendor-data and would silently swallow these). Empty list = no vendor-data snippet uploaded, zero behavior change."
  type        = list(string)
  default     = []
}

variable "install_qemu_guest_agent" {
  description = "Install and enable qemu-guest-agent via a cloud-init runcmd on first boot (Debian/Ubuntu family only; set false for other distros). Defaults to false so existing VMs are unaffected on upgrade: setting the resulting vendor_data_file_id for the first time on an already-existing VM forces replacement. Only new VMs should opt in. Independent of agent_enabled, which already defaults to true and controls Proxmox's QMP guest-agent channel (agent { enabled = ... }) regardless of whether the package is actually installed."
  type        = bool
  default     = false
}

variable "snippets_datastore_id" {
  description = "Datastore ID used to upload the generated vendor-data cloud-init snippet (must support the 'snippets' content type, e.g. a directory-backed store like \"local\"). Required (plan-time error otherwise) whenever additional_runcmd is non-empty or install_qemu_guest_agent is true. No default: cloud_init_datastore_id is usually the wrong store for this (LVM-thin datastores such as \"local-lvm\" only support the 'images' content type, never 'snippets')."
  type        = string
  default     = null
}
