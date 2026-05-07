# Basic example

Creates a single virtual machine on Proxmox cloned from a cloud-init template.

```bash
export PROXMOX_VE_ENDPOINT="https://pve.example.com:8006/"
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD="secret"
terraform init
terraform plan
```
