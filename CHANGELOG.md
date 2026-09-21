# Changelog

## v1.3.0 — 2026-09-21

### Fixed

- Removed the `file_format = optional(string, "raw")` type-level default on `disks` entries.
  This default forced `file_format = "raw"` into every apply for `path_in_datastore` (raw
  physical-disk passthrough) disks even though such disks have no `file_format` in their live
  Proxmox config, producing a permanent, unreconcilable plan diff (`+ file_format = "raw"`) that
  — combined with the provider resending the full disk list, `path_in_datastore` included, on
  any disk-list change — made every apply on a VM with a passthrough disk fail for non-root API
  tokens ("Only root can pass arbitrary filesystem paths."). `file_format` is now
  `optional(string)` (no default), matching the `efi_disk` variable's existing behavior. For
  regular (non-passthrough) disks with existing state this is inert — an existing disk's real,
  already-applied format is preserved from state with no plan diff on upgrade.

### Changed

- Brand-new (not-yet-created) non-passthrough disks on storage backends whose Proxmox-side
  default format isn't `raw` (e.g. `dir`/NFS-backed storages, which default to `qcow2`) will now
  get that storage's natural default format instead of always being forced to `raw`. If you rely
  on `raw` for new disks on such storage, set `file_format = "raw"` explicitly in your `disks`
  entry.

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
