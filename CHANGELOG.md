# Changelog

## v1.2.0 — 2026-09-18

### Added

- `path_in_datastore` field on `disks` entries to support raw physical-disk
  passthrough (`datastore_id = ""`), matching the `bpg/proxmox` provider's native
  passthrough semantics. `size` is now optional on `disks` entries (must be left
  unset for a passthrough entry; exactly one of `size`/`path_in_datastore` is
  enforced via variable validation). Non-breaking — no action required for existing
  configurations; every field that changed was a required→optional relaxation or a
  new optional field, and both new validations evaluate trivially true for any
  existing `disks` map.

## v1.1.0 — 2026-09-18

### Added

- `memory_floating` variable to set the Proxmox ballooning minimum (`memory.floating`)

## v1.0.0 — 2026-05-07

### Added

- Initial release extracted from [dark-vex/infra-cd](https://github.com/dark-vex/infra-cd)
- `proxmox_virtual_environment_vm` resource with `prevent_destroy` lifecycle guard
- Support for CPU, memory, dynamic disks, network devices, cloud-init, EFI, CD-ROM
- Outputs: `id`, `vmid`, `name`, `ipv4_addresses`, `ipv6_addresses`, `mac_addresses`, `network_interface_names`
