# Changelog

## v1.0.0 — 2026-05-07

### Added

- Initial release extracted from [dark-vex/infra-cd](https://github.com/dark-vex/infra-cd)
- `proxmox_virtual_environment_vm` resource with `prevent_destroy` lifecycle guard
- Support for CPU, memory, dynamic disks, network devices, cloud-init, EFI, CD-ROM
- Outputs: `id`, `vmid`, `name`, `ipv4_addresses`, `ipv6_addresses`, `mac_addresses`, `network_interface_names`
