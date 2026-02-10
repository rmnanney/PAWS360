module "pve_template" {
  source = "../"

  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password

  template_name   = "paws360-template"
  template_node   = "pve-node-1"
  template_storage= "local-lvm"

  create_template = true
  create_vms      = false
}
