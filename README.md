# terraform-proxmox-vm

Terraform module for Proxmox VE virtual machines using the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox) provider.

## Usage

```hcl
module "vm" {
  source = "github.com/dark-vex/terraform-proxmox-vm?ref=v1.0.0"

  name      = "my-vm"
  vmid      = 100
  node_name = "pve"

  cpu_cores = 2
  memory    = 2048

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
}
```

See [`examples/basic/`](examples/basic/) for a full working example.

## Cloud-init: `additional_runcmd` and `install_qemu_guest_agent`

Both inputs render into a single vendor-data cloud-init snippet (uploaded via a
new `proxmox_virtual_environment_file` resource, only created when there's
something to render) and are merged into one `runcmd` list — cloud-init only
exposes one `vendor_data_file_id` slot per VM.

- **New VMs only — and it stays a one-way door for the life of the VM.**
  Setting `vendor_data_file_id` on an already-existing VM forces replacement,
  and this module's `prevent_destroy = true` will hard-error the plan. This
  isn't just a first-apply concern: once a VM has vendor-data enabled,
  *changing* `additional_runcmd`, toggling `install_qemu_guest_agent`,
  changing `snippets_datastore_id`, disabling the feature again, or renaming
  the VM (the snippet's filename is derived from `var.name`) are all changes
  to the same replacement-sensitive attribute and will hit the same
  `prevent_destroy` wall. Treat both inputs as fixed at VM creation time.
  `install_qemu_guest_agent` defaults to `false` for this reason — opt in
  explicitly per new VM rather than at the module level, so existing callers
  see no plan changes on upgrade.
- **Incompatible with a custom `cloud_init_file_id`.** cloud-init's `runcmd`
  merge behavior is replace, not concatenate, and user-data always wins over
  vendor-data — a VM using its own `cloud_init_file_id` snippet would silently
  never run this vendor-data `runcmd`, with no error from cloud-init itself.
  This module guards against that with a `lifecycle.precondition` that fails
  the plan instead: set `install_qemu_guest_agent = false` and
  `additional_runcmd = []` when using a custom `cloud_init_file_id`, or move
  the commands into that snippet directly. This precondition is deliberately
  conservative — it rejects *any* non-null `cloud_init_file_id`, even one that
  happens not to define its own `runcmd`, because Terraform can't inspect that
  file's contents to tell the two cases apart.
- **`install_qemu_guest_agent` assumes a Debian/Ubuntu-family image** (uses
  `apt-get`). Set it `false` for other distros and install the agent another
  way (e.g. a config management run against the booted host).
- **Requires an explicit snippets-capable datastore and provider `ssh`
  block.** `snippets_datastore_id` has no default and must be set to a
  datastore with the `snippets` content type enabled (e.g. a directory-backed
  store like `"local"`) whenever either input is active — `cloud_init_datastore_id`
  is usually the wrong store for this (LVM-thin datastores such as
  `"local-lvm"` only support `images`, never `snippets`). Snippet uploads also
  require the `bpg/proxmox` provider's `ssh` block to be configured.
- **Both inputs are inert, not an error, if `cloud_init_datastore_id` is
  null** (a `check` block emits a plan-time warning in that case, since
  there's no cloud-init drive for the vendor-data snippet to attach to).
- **`runcmd` fires once per cloud-init `instance-id`.** Fine for VMs built
  from a pristine, never-booted cloud image (this module's normal path). If
  VMs are ever created by cloning a previously-booted Proxmox template
  instead, a clone can retain the template's original `instance-id` and skip
  `runcmd` entirely on first boot, silently — worth remembering before
  adopting clone-based provisioning with either input in use.
- **`agent_enabled` (default `true`) and `install_qemu_guest_agent` are
  independent and can be out of sync during boot.** `agent_enabled` makes
  Proxmox expect the QMP guest-agent channel immediately; the package itself
  only lands late in boot once `runcmd` executes. Expect Proxmox to wait on
  the agent channel for a bit longer than on an image with the agent
  pre-baked in — that's expected, not a hang.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.83.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >= 0.83.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_virtual_environment_file.vendor_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_runcmd"></a> [additional\_runcmd](#input\_additional\_runcmd) | Extra runcmd entries rendered into a vendor-data cloud-init snippet, merged at boot with the module's own generated user-data. Only takes effect when cloud\_init\_datastore\_id is set and cloud\_init\_file\_id is null (a custom user-data snippet's runcmd always wins over vendor-data and would silently swallow these). Empty list = no vendor-data snippet uploaded, zero behavior change. | `list(string)` | `[]` | no |
| <a name="input_agent_enabled"></a> [agent\_enabled](#input\_agent\_enabled) | Enable QEMU guest agent | `bool` | `true` | no |
| <a name="input_bios_type"></a> [bios\_type](#input\_bios\_type) | BIOS type | `string` | `"seabios"` | no |
| <a name="input_boot_order"></a> [boot\_order](#input\_boot\_order) | Boot order (es. 'cdn' per CD-ROM, disco, network) | `list(string)` | <pre>[<br/>  "scsi0"<br/>]</pre> | no |
| <a name="input_cdrom"></a> [cdrom](#input\_cdrom) | Configurazione del CD-ROM | <pre>object({<br/>    file_id   = string<br/>    interface = optional(string, "ide2")<br/>  })</pre> | `null` | no |
| <a name="input_cloud_init_datastore_id"></a> [cloud\_init\_datastore\_id](#input\_cloud\_init\_datastore\_id) | Datastore per il disco Cloud-Init. Se null, Cloud-Init viene disabilitato. | `string` | `null` | no |
| <a name="input_cloud_init_dns"></a> [cloud\_init\_dns](#input\_cloud\_init\_dns) | Cloud-init DNS configuration | <pre>object({<br/>    domain  = optional(string)<br/>    servers = optional(list(string))<br/>  })</pre> | `{}` | no |
| <a name="input_cloud_init_file_id"></a> [cloud\_init\_file\_id](#input\_cloud\_init\_file\_id) | Cloud-init user data file ID | `string` | `null` | no |
| <a name="input_cloud_init_password"></a> [cloud\_init\_password](#input\_cloud\_init\_password) | Cloud-init password | `string` | `null` | no |
| <a name="input_cloud_init_user"></a> [cloud\_init\_user](#input\_cloud\_init\_user) | Cloud-init username | `string` | `"ubuntu"` | no |
| <a name="input_cpu_cores"></a> [cpu\_cores](#input\_cpu\_cores) | Number of CPU cores | `number` | `1` | no |
| <a name="input_cpu_sockets"></a> [cpu\_sockets](#input\_cpu\_sockets) | Number of CPU sockets | `number` | `1` | no |
| <a name="input_cpu_type"></a> [cpu\_type](#input\_cpu\_type) | CPU type (e.g., host, x86-64-v2-AES) | `string` | `"host"` | no |
| <a name="input_description"></a> [description](#input\_description) | VM description | `string` | `""` | no |
| <a name="input_disks"></a> [disks](#input\_disks) | Mappa dei dischi virtuali | <pre>map(object({<br/>    backup       = optional(bool, true)<br/>    datastore_id = string<br/>    interface    = string # Es. scsi0, scsi1 (FONDAMENTALE che sia univoco)<br/>    size         = number<br/>    file_format  = optional(string, "raw")<br/>    file_id      = optional(string)<br/>    iothread     = optional(bool, true)<br/>    ssd          = optional(bool, true)<br/>    discard      = optional(string, "on")<br/>  }))</pre> | `{}` | no |
| <a name="input_efi_disk"></a> [efi\_disk](#input\_efi\_disk) | n/a | <pre>object({<br/>    datastore_id      = string<br/>    file_format       = optional(string)<br/>    type              = optional(string)<br/>    pre_enrolled_keys = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_install_qemu_guest_agent"></a> [install\_qemu\_guest\_agent](#input\_install\_qemu\_guest\_agent) | Install and enable qemu-guest-agent via a cloud-init runcmd on first boot (Debian/Ubuntu family only; set false for other distros). Defaults to false so existing VMs are unaffected on upgrade: setting the resulting vendor\_data\_file\_id for the first time on an already-existing VM forces replacement. Only new VMs should opt in. Independent of agent\_enabled, which already defaults to true and controls Proxmox's QMP guest-agent channel (agent { enabled = ... }) regardless of whether the package is actually installed. | `bool` | `false` | no |
| <a name="input_ip_config"></a> [ip\_config](#input\_ip\_config) | IP configuration | <pre>object({<br/>    ipv4_address = optional(string, "dhcp")<br/>    ipv4_gateway = optional(string)<br/>    ipv6_address = optional(string)<br/>    ipv6_gateway = optional(string)<br/>  })</pre> | <pre>{<br/>  "ipv4_address": "dhcp"<br/>}</pre> | no |
| <a name="input_machine"></a> [machine](#input\_machine) | Machine settings | `string` | `""` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in MB | `number` | `2048` | no |
| <a name="input_name"></a> [name](#input\_name) | VM name/hostname | `string` | n/a | yes |
| <a name="input_network_devices"></a> [network\_devices](#input\_network\_devices) | Map of network devices | <pre>map(object({<br/>    bridge       = optional(string, "vmbr0")<br/>    mac_address  = optional(string)<br/>    disconnected = optional(bool, false)<br/>    firewall     = optional(bool, false)<br/>    model        = optional(string, "virtio")<br/>    vlan_id      = optional(number)<br/>  }))</pre> | <pre>{<br/>  "net0": {<br/>    "bridge": "vmbr0"<br/>  }<br/>}</pre> | no |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Target Proxmox node name | `string` | n/a | yes |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | Operating system type | `string` | `"l26"` | no |
| <a name="input_protection"></a> [protection](#input\_protection) | Enable VM protection to prevent accidental deletion | `bool` | `false` | no |
| <a name="input_snippets_datastore_id"></a> [snippets\_datastore\_id](#input\_snippets\_datastore\_id) | Datastore ID used to upload the generated vendor-data cloud-init snippet (must support the 'snippets' content type, e.g. a directory-backed store like "local"). Required (plan-time error otherwise) whenever additional\_runcmd is non-empty or install\_qemu\_guest\_agent is true. No default: cloud\_init\_datastore\_id is usually the wrong store for this (LVM-thin datastores such as "local-lvm" only support the 'images' content type, never 'snippets'). | `string` | `null` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | List of SSH public keys | `list(string)` | `[]` | no |
| <a name="input_start_on_boot"></a> [start\_on\_boot](#input\_start\_on\_boot) | Whether VM should start on host boot | `bool` | `true` | no |
| <a name="input_started"></a> [started](#input\_started) | Whether VM should be started after creation | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource tags | `list(string)` | <pre>[<br/>  "automation"<br/>]</pre> | no |
| <a name="input_vmid"></a> [vmid](#input\_vmid) | VM ID | `number` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | VM ID |
| <a name="output_ipv4_addresses"></a> [ipv4\_addresses](#output\_ipv4\_addresses) | IPv4 addresses assigned to the VM |
| <a name="output_ipv6_addresses"></a> [ipv6\_addresses](#output\_ipv6\_addresses) | IPv6 addresses assigned to the VM |
| <a name="output_mac_addresses"></a> [mac\_addresses](#output\_mac\_addresses) | MAC addresses of network interfaces |
| <a name="output_name"></a> [name](#output\_name) | VM name |
| <a name="output_network_interface_names"></a> [network\_interface\_names](#output\_network\_interface\_names) | Network interface names |
| <a name="output_vmid"></a> [vmid](#output\_vmid) | VM numeric ID |
<!-- END_TF_DOCS -->

## License

[MIT](LICENSE)
