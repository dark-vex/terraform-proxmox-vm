# Changelog

## Unreleased

### Added

- `additional_runcmd` input: extra `runcmd` entries rendered into a vendor-data
  cloud-init snippet, uploaded via a new `proxmox_virtual_environment_file.vendor_data`
  resource (only created when there's something to render). Intended for delivering
  first-boot callback scripts (e.g. self-registration) without displacing the
  module's own `user_account`/`user_data_file_id` handling.
- `install_qemu_guest_agent` input (default `false`): installs and enables
  `qemu-guest-agent` via the same vendor-data `runcmd` mechanism, Debian/Ubuntu-family
  images only. Defaults to `false`, not `true`, because setting `vendor_data_file_id`
  for the first time on an already-existing VM forces replacement — opt in per new VM.
- `snippets_datastore_id` input: datastore used for the vendor-data snippet upload.
  No default — `cloud_init_datastore_id` is usually the wrong store for this
  (LVM-thin datastores like `local-lvm` only support `images`, never `snippets`),
  so a plan-time precondition requires it to be set explicitly whenever either new
  input is active.
- `lifecycle.precondition` on the vendor-data resource: fails the plan if either new
  input is used together with a custom `cloud_init_file_id`, since cloud-init would
  otherwise silently ignore the vendor-data `runcmd` with no error. Deliberately
  conservative — rejects any non-null `cloud_init_file_id`, not just ones that
  actually define their own `runcmd`, since Terraform can't inspect that file's
  contents.
- `check` block warning if `additional_runcmd`/`install_qemu_guest_agent` is set
  without `cloud_init_datastore_id` — otherwise the requested runcmd silently never
  gets delivered, with no cloud-init drive to attach it to.

Both new inputs default to inert (`[]` / `false`), so existing callers see zero plan
changes on upgrade. Once vendor-data is enabled on a VM, changing either input,
`snippets_datastore_id`, or the VM's `name` again is itself a replacement-sensitive
change — see the README's cloud-init section.

## v1.0.0 — 2026-05-07

### Added

- Initial release extracted from [dark-vex/infra-cd](https://github.com/dark-vex/infra-cd)
- `proxmox_virtual_environment_vm` resource with `prevent_destroy` lifecycle guard
- Support for CPU, memory, dynamic disks, network devices, cloud-init, EFI, CD-ROM
- Outputs: `id`, `vmid`, `name`, `ipv4_addresses`, `ipv6_addresses`, `mac_addresses`, `network_interface_names`
