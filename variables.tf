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

variable "memory_floating" {
  description = <<-EOT
    Floating (ballooning minimum) memory in MB. Maps to the provider's `memory.floating`
    argument / Proxmox's `balloon` setting.
      - `null` (default) or `0` — ballooning disabled (matches current module behavior).
      - equal to `var.memory` — ballooning enabled with no effective minimum.
      - less than `var.memory` — ballooning enabled, down to this minimum.
    Must not exceed `var.memory` (enforced via a resource precondition).
  EOT
  type        = number
  default     = null
}

variable "machine" {
  description = "Machine settings"
  type        = string
  default     = ""
}

variable "disks" {
  description = <<-EOT
    Mappa dei dischi virtuali (la chiave della mappa sarà un nome logico, es. 'boot', 'storage').

    Each entry is either a normal storage-backed disk (set `size`, leave
    `path_in_datastore` unset) or a raw physical-disk passthrough entry (set
    `path_in_datastore` to a host block device path, e.g.
    `/dev/disk/by-id/dm-name-...`, leave `size` unset, and set
    `datastore_id = ""`). Exactly one of `size`/`path_in_datastore` must be set per
    entry; this is enforced via variable validation. Only the plain
    host-passthrough shape is supported here — not the provider's other
    `path_in_datastore` use case of attaching another VM's existing disk (which
    pairs it with a non-empty `datastore_id` and `size`).

    WARNINGS for `path_in_datastore` entries:
      - Never attach the same passthrough device to more than one VM.
      - Never reuse an existing `interface` key for a different physical device
        across applies — this risks a detach/recreate against a real device.
        `prevent_destroy` on this module's VM resource does not protect an
        individual disk from being dropped or recreated in place.
      - Passthrough entries still inherit `backup=true, ssd=true, iothread=true,
        discard="on"` from this type's defaults. When adopting an existing device,
        set these explicitly to match its real Proxmox-side configuration (a
        passthrough disk commonly already has `backup=false`) to avoid a spurious
        diff.
      - A passthrough entry planned as a brand-new disk (no prior Terraform state
        for that VM/disk) will show `size = 8` in the plan — that's the
        provider's schema default, not the device's real size, and this module
        cannot override it. Always bring an existing device under management via
        `terraform import` + matching config entry (see README) rather than
        letting Terraform create the entry from scratch.
  EOT
  # La chiave della mappa sarà un nome logico (es. 'boot', 'storage')
  type = map(object({
    backup            = optional(bool, true)
    datastore_id      = string
    interface         = string # Es. scsi0, scsi1 (FONDAMENTALE che sia univoco)
    size              = optional(number)
    path_in_datastore = optional(string)
    file_format       = optional(string)
    file_id           = optional(string)
    iothread          = optional(bool, true)
    ssd               = optional(bool, true)
    discard           = optional(string, "on")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, d in var.disks :
      (d.size != null && d.path_in_datastore == null) ||
      (d.size == null && d.path_in_datastore != null)
    ])
    error_message = "Each disks entry must set exactly one of `size` or `path_in_datastore` (mutually exclusive)."
  }

  validation {
    condition = alltrue([
      for k, d in var.disks :
      d.path_in_datastore == null || d.datastore_id == ""
    ])
    error_message = "When `path_in_datastore` is set, `datastore_id` must be \"\" (empty string) — this module only supports the raw host-block-device passthrough shape, not the provider's separate \"attach another VM's disk\" shape."
  }
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
