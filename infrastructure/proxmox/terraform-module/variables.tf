variable "pm_api_url" {
  description = "Proxmox API URL (example: https://pve.example.local:8006/api2/json)"
  type        = string
}

variable "pm_user" {
  description = "Proxmox user (eg. root@pam or user@pve)."
  type        = string
}

variable "pm_password" {
  description = "Proxmox password/token (use secret management)."
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Disable TLS verification for proxmox provider."
  type        = bool
  default     = false
}

variable "pm_minimum_permission_check" {
  description = "Whether to perform provider minimum permission check on the supplied user/token."
  type        = bool
  default     = true
}

variable "template_name" {
  description = "Name of the template VM to create."
  type        = string
  default     = "paws360-template"
}

variable "template_node" {
  description = "Proxmox node that will hold the template VM"
  type        = string
  default     = "pve-node-1"
}

variable "template_storage" {
  description = "Storage pool for template disk (e.g., local-lvm, proxmox-storage)"
  type        = string
  default     = "local-lvm"
}

variable "template_disk_size" {
  description = "Template root disk size (qcow2 string)."
  type        = string
  default     = "50G"
}


variable "template_cores" {
  type    = number
  default = 2
}

variable "template_sockets" {
  type    = number
  default = 1
}

variable "template_memory" {
  type    = number
  default = 4096
}

variable "template_net_model" {
  type    = string
  default = "virtio"
}

variable "template_bridge" {
  type    = string
  default = "vmbr0"
}

variable "cloud_init_user" {
  type    = string
  default = "admin"
}

variable "cloud_init_sshkeys" {
  type    = string
  default = ""
}

variable "prevent_template_destroy" {
  type    = bool
  default = true
}

variable "create_template" {
  type    = bool
  default = true
}

variable "create_vms" {
  type    = bool
  default = false
}

variable "vms" {
  type = list(object({
    name        = string
    node        = string
    bridge      = string
    ip          = optional(string)
    nameservers = optional(list(string))
    memory      = optional(number)
    cores       = optional(number)
  }))
  default = []
}

variable "vm_default_cores" {
  type    = number
  default = 2
}

variable "vm_default_memory" {
  type    = number
  default = 4096
}
