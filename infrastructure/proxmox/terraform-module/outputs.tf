output "template_name" {
  description = "Name of the created template"
  value       = try(proxmox_vm_qemu.template[0].name, null)
}

output "created_vms" {
  description = "List of VMs created from the template"
  value       = try([for v in proxmox_vm_qemu.vm_from_template : v.name], [])
}
