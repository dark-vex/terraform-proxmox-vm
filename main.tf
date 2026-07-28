locals {
  qemu_guest_agent_runcmd = var.install_qemu_guest_agent ? [
    "apt-get update && apt-get install -y qemu-guest-agent && systemctl enable --now qemu-guest-agent"
  ] : []

  combined_runcmd = concat(local.qemu_guest_agent_runcmd, var.additional_runcmd)

  vendor_data_enabled = var.cloud_init_datastore_id != null && length(local.combined_runcmd) > 0
}

# additional_runcmd/install_qemu_guest_agent are inert (no error, no resource) whenever
# cloud_init_datastore_id is null, since there's no initialization block to attach
# vendor_data_file_id to. Surface that as a visible warning instead of a silent no-op.
check "runcmd_requires_cloud_init_datastore" {
  assert {
    condition     = var.cloud_init_datastore_id != null || length(local.combined_runcmd) == 0
    error_message = "additional_runcmd is non-empty or install_qemu_guest_agent is true, but cloud_init_datastore_id is null, so cloud-init is disabled for this VM and the requested runcmd will never be delivered."
  }
}

# Vendor-data cloud-init snippet: carries additional_runcmd and/or the qemu-guest-agent
# install command. Kept separate from user_data_file_id (which the module's own
# user_account block or a caller-supplied cloud_init_file_id populate) since
# vendor_data_file_id is the only slot cloud-init exposes for this without displacing
# either of those. Only created when there's something to render.
resource "proxmox_virtual_environment_file" "vendor_data" {
  count = local.vendor_data_enabled ? 1 : 0

  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name

  source_raw {
    file_name = "${var.name}-vendor-data.yaml"
    data      = "#cloud-config\n${yamlencode({ runcmd = local.combined_runcmd })}"
  }

  lifecycle {
    precondition {
      # cloud-init merge semantics: user-data's runcmd always replaces vendor-data's,
      # so a custom cloud_init_file_id would silently swallow this snippet's runcmd
      # with no error anywhere. Fail loudly instead. Deliberately conservative: this
      # rejects every non-null cloud_init_file_id, even a snippet that happens not to
      # define its own runcmd, because Terraform can't introspect that file's contents
      # to tell the two cases apart.
      condition     = var.cloud_init_file_id == null
      error_message = "additional_runcmd/install_qemu_guest_agent render a vendor-data runcmd that cloud-init silently ignores whenever cloud_init_file_id supplies its own user-data runcmd. Set install_qemu_guest_agent = false and additional_runcmd = [] when using a custom cloud_init_file_id, or move the runcmd into that snippet instead."
    }

    precondition {
      # cloud_init_datastore_id (the cloud-init drive) typically only supports the
      # "images" content type (e.g. LVM-thin stores like "local-lvm"); "snippets"
      # needs a directory-backed store (e.g. "local"). No safe default exists across
      # Proxmox storage layouts, so this is required rather than falling back.
      condition     = var.snippets_datastore_id != null
      error_message = "additional_runcmd/install_qemu_guest_agent require snippets_datastore_id to be set explicitly to a datastore with the 'snippets' content type enabled (e.g. a directory-backed store like \"local\"). cloud_init_datastore_id is usually the wrong store for this: it typically only supports \"images\" (LVM-thin datastores such as \"local-lvm\" never support snippets)."
    }
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  tags        = var.tags

  node_name = var.node_name
  vm_id     = var.vmid

  started = var.started
  on_boot = var.start_on_boot

  protection = var.protection
  bios       = var.bios_type # es. "seabios" o "ovmf"
  machine    = var.machine

  # Definisce il controller SCSI (importante per le performance)
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = var.agent_enabled
  }

  cpu {
    cores   = var.cpu_cores
    sockets = var.cpu_sockets
    type    = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  # --- GESTIONE DISCHI ---
  dynamic "disk" {
    # Itera sulla mappa (chiave => oggetto)
    for_each = var.disks

    content {
      backup       = disk.value.backup
      datastore_id = disk.value.datastore_id
      size         = disk.value.size

      # Qui è il trucco: l'interfaccia DEVE essere definita nel valore
      interface = disk.value.interface

      file_format = try(disk.value.file_format, "raw")
      file_id     = try(disk.value.file_id, null)
      iothread    = try(disk.value.iothread, true)
      ssd         = try(disk.value.ssd, true)
      discard     = try(disk.value.discard, "on")
    }
  }

  # --- GESTIONE CD-ROM (Opzionale) ---
  # Si attiva solo se la variabile var.cdrom è definita
  dynamic "cdrom" {
    for_each = var.cdrom != null ? [var.cdrom] : []
    content {
      file_id   = cdrom.value.file_id # es. "local:iso/ubuntu.iso" o "none"
      interface = try(cdrom.value.interface, "ide2")
    }
  }

  # --- GESTIONE EFI (Opzionale) ---
  dynamic "efi_disk" {
    for_each = var.efi_disk != null ? [var.efi_disk] : []
    content {
      datastore_id      = efi_disk.value.datastore_id
      file_format       = try(efi_disk.value.file_format, "raw")
      type              = try(efi_disk.value.type, "4m")
      pre_enrolled_keys = try(efi_disk.value.pre_enrolled_keys, false)
    }
  }

  # --- ORDINE DI AVVIO ---
  # È buona norma esplicitarlo
  boot_order = var.boot_order

  dynamic "network_device" {
    for_each = var.network_devices
    content {
      bridge       = network_device.value.bridge
      mac_address  = network_device.value.mac_address
      disconnected = network_device.value.disconnected
      firewall     = network_device.value.firewall
      model        = network_device.value.model
      vlan_id      = network_device.value.vlan_id
    }
  }

  # --- CLOUD-INIT ---
  dynamic "initialization" {
    for_each = var.cloud_init_datastore_id != null ? [1] : []

    content {
      datastore_id = var.cloud_init_datastore_id

      # Configurazione DNS
      dynamic "dns" {
        #for_each = var.cloud_init_dns != null ? [var.cloud_init_dns] : []
        for_each = try(var.cloud_init_dns.domain != null || length(var.cloud_init_dns.servers) > 0, false) ? [var.cloud_init_dns] : []
        content {
          domain  = try(dns.value.domain, null)
          servers = try(dns.value.servers, [])
        }
      }

      # Configurazione IP
      ip_config {
        ipv4 {
          address = var.ip_config.ipv4_address
          gateway = var.ip_config.ipv4_gateway
        }
        dynamic "ipv6" {
          for_each = var.ip_config.ipv6_address != null ? [1] : []
          content {
            address = var.ip_config.ipv6_address
            gateway = var.ip_config.ipv6_gateway
          }
        }
      }

      # User Account (se non c'è il file custom)
      dynamic "user_account" {
        for_each = var.cloud_init_file_id == null ? [1] : []
        content {
          keys     = var.ssh_keys
          password = var.cloud_init_password
          username = var.cloud_init_user
        }
      }

      # File custom (se presente)
      user_data_file_id = var.cloud_init_file_id

      # Vendor-data snippet (additional_runcmd / install_qemu_guest_agent), if rendered
      vendor_data_file_id = local.vendor_data_enabled ? proxmox_virtual_environment_file.vendor_data[0].id : null
    }
  }

  operating_system {
    type = var.os_type # es. "l26"
  }

  serial_device {}

  lifecycle {
    ignore_changes = [
      # Ignora tutti i file_id dei dischi (evita che TF provi a ricreare il disco dopo un clone)
      #disk[*].file_id,
      # Ignora modifiche post-deploy all'account utente cloud-init
      initialization[0].user_account,
      # Spesso utile ignorare lo stato power se gestito manualmente
      started
    ]
    prevent_destroy = true
  }
}
