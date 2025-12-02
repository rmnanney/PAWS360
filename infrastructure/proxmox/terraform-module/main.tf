terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
  # provider configuration left minimal; control permission checks at the provider level if supported
}

resource "proxmox_vm_qemu" "template" {
  count       = var.create_template ? 1 : 0
  name        = var.template_name
  target_node = var.template_node
  # vmid omitted => provider will allocate

  cores   = var.template_cores
  sockets = var.template_sockets
  memory  = var.template_memory
  # Use a disk block instead of driver-specific scsi0 parameter
  disk {
    slot    = 0
    size    = var.template_disk_size
    storage = var.template_storage
    type    = "scsi"
    format  = "qcow2"
  }

  network {
    model  = var.template_net_model
    bridge = var.template_bridge
  }

  # boot expects a string, not a list
  boot = "order=scsi0"

  # enable QEMU guest agent as an argument
  agent = 1

  # enable cloud-init and inject user-data
  ciuser  = var.cloud_init_user
  sshkeys = var.cloud_init_sshkeys

  # mark as template so it can be cloned
  # mark-as-template behavior removed for provider compatibility (managed externally if needed)
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_vm_qemu" "vm_from_template" {
  count = var.create_vms ? length(var.vms) : 0

  name        = var.vms[count.index].name
  target_node = var.vms[count.index].node
  clone       = proxmox_vm_qemu.template[0].name

  cores  = lookup(var.vms[count.index], "cores", var.vm_default_cores)
  memory = lookup(var.vms[count.index], "memory", var.vm_default_memory)

  network {
    model  = var.template_net_model
    bridge = var.vms[count.index].bridge
  }

  # override cloud-init user-data through `user_data` if required
  ciuser  = var.cloud_init_user
  sshkeys = var.cloud_init_sshkeys
  # Optional static network via Proxmox cloud-init "ipconfig0" string
  ipconfig0 = lookup(var.vms[count.index], "ip", null)

  depends_on = [proxmox_vm_qemu.template]
}
