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
| [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_agent_enabled"></a> [agent\_enabled](#input\_agent\_enabled) | Enable QEMU guest agent | `bool` | `true` | no |
| <a name="input_bios_type"></a> [bios\_type](#input\_bios\_type) | BIOS type | `string` | `"seabios"` | no |
| <a name="input_boot_order"></a> [boot\_order](#input\_boot\_order) | Boot order (es. 'cdn' per CD-ROM, disco, network) | `list(string)` | <pre>[<br/>  "scsi0"<br/>]</pre> | no |
| <a name="input_cdrom"></a> [cdrom](#input\_cdrom) | Configurazione del CD-ROM | <pre>object({<br/>    file_id   = string<br/>    interface = optional(string, "ide2")<br/>  })</pre> | `null` | no |
| <a name="input_cloud_init_datastore_id"></a> [cloud\_init\_datastore\_id](#input\_cloud\_init\_datastore\_id) | Datastore per il disco Cloud-Init. Se null, Cloud-Init viene disabilitato. | `string` | `null` | no |
| <a name="input_cloud_init_dns"></a> [cloud\_init\_dns](#input\_cloud\_init\_dns) | Cloud-init DNS configuration | <pre>object({<br/>    domain  = optional(string)<br/>    servers = optional(list(string))<br/>  })</pre> | `{}` | no |
| <a name="input_cloud_init_file_id"></a> [cloud\_init\_file\_id](#input\_cloud\_init\_file\_id) | Cloud-init user data file ID | `string` | `null` | no |
| <a name="input_cloud_init_password"></a> [cloud\_init\_password](#input\_cloud\_init\_password) | Cloud-init password | `string` | `null` | no |
| <a name="input_cloud_init_user"></a> [cloud\_init\_user](#input\_cloud\_init\_user) | Cloud-init username | `string` | `"ubuntu"` | no |
| <a name="input_cpu_architecture"></a> [cpu\_architecture](#input\_cpu\_architecture) | CPU architecture | `string` | `"x86_64"` | no |
| <a name="input_cpu_cores"></a> [cpu\_cores](#input\_cpu\_cores) | Number of CPU cores | `number` | `1` | no |
| <a name="input_cpu_sockets"></a> [cpu\_sockets](#input\_cpu\_sockets) | Number of CPU sockets | `number` | `1` | no |
| <a name="input_cpu_type"></a> [cpu\_type](#input\_cpu\_type) | CPU type (e.g., host, x86-64-v2-AES) | `string` | `"host"` | no |
| <a name="input_description"></a> [description](#input\_description) | VM description | `string` | `""` | no |
| <a name="input_disks"></a> [disks](#input\_disks) | Mappa dei dischi virtuali | <pre>map(object({<br/>    backup       = optional(bool, true)<br/>    datastore_id = string<br/>    interface    = string # Es. scsi0, scsi1 (FONDAMENTALE che sia univoco)<br/>    size         = number<br/>    file_format  = optional(string, "raw")<br/>    file_id      = optional(string)<br/>    iothread     = optional(bool, true)<br/>    ssd          = optional(bool, true)<br/>    discard      = optional(string, "on")<br/>  }))</pre> | `{}` | no |
| <a name="input_efi_disk"></a> [efi\_disk](#input\_efi\_disk) | n/a | <pre>object({<br/>    datastore_id      = string<br/>    file_format       = optional(string)<br/>    type              = optional(string)<br/>    pre_enrolled_keys = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_ip_config"></a> [ip\_config](#input\_ip\_config) | IP configuration | <pre>object({<br/>    ipv4_address = optional(string, "dhcp")<br/>    ipv4_gateway = optional(string)<br/>    ipv6_address = optional(string)<br/>    ipv6_gateway = optional(string)<br/>  })</pre> | <pre>{<br/>  "ipv4_address": "dhcp"<br/>}</pre> | no |
| <a name="input_machine"></a> [machine](#input\_machine) | Machine settings | `string` | `""` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in MB | `number` | `2048` | no |
| <a name="input_name"></a> [name](#input\_name) | VM name/hostname | `string` | n/a | yes |
| <a name="input_network_devices"></a> [network\_devices](#input\_network\_devices) | Map of network devices | <pre>map(object({<br/>    bridge       = optional(string, "vmbr0")<br/>    mac_address  = optional(string)<br/>    disconnected = optional(bool, false)<br/>    firewall     = optional(bool, false)<br/>    model        = optional(string, "virtio")<br/>    vlan_id      = optional(number)<br/>  }))</pre> | <pre>{<br/>  "net0": {<br/>    "bridge": "vmbr0"<br/>  }<br/>}</pre> | no |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Target Proxmox node name | `string` | n/a | yes |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | Operating system type | `string` | `"l26"` | no |
| <a name="input_protection"></a> [protection](#input\_protection) | Enable VM protection to prevent accidental deletion | `bool` | `false` | no |
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
