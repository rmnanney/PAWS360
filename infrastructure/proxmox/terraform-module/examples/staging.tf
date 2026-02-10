module "pve_staging" {
  source = "../"

  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password

  template_name   = "paws360-template"
  template_node   = "pve-node-1"
  template_storage= "local-lvm"

  create_template = false
  create_vms      = true

  vms = [
    { name = "web-staging-01.paws360.ryannanney.com"  , node = "pve-node-1", bridge = "vmbr0", ip = "ip=10.0.50.101/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "web-staging-02.paws360.ryannanney.com"  , node = "pve-node-2", bridge = "vmbr0", ip = "ip=10.0.50.102/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "db-staging-01.paws360.ryannanney.com"   , node = "pve-node-2", bridge = "vmbr0", ip = "ip=10.0.50.110/24,gw=10.0.50.1", cores=4, memory=8192},
    { name = "etcd-staging-01.paws360.ryannanney.com" , node = "pve-node-1", bridge = "vmbr0", ip = "ip=10.0.50.111/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "etcd-staging-02.paws360.ryannanney.com" , node = "pve-node-2", bridge = "vmbr0", ip = "ip=10.0.50.112/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "etcd-staging-03.paws360.ryannanney.com" , node = "pve-node-1", bridge = "vmbr0", ip = "ip=10.0.50.113/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "lb-staging-01.paws360.ryannanney.com"   , node = "pve-node-1", bridge = "vmbr0", ip = "ip=10.0.50.120/24,gw=10.0.50.1", cores=1, memory=2048},
    { name = "mon-staging-01.paws360.ryannanney.com"  , node = "pve-node-1", bridge = "vmbr0", ip = "ip=10.0.50.130/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "redis-staging-01.paws360.ryannanney.com" , node = "pve-node-2", bridge = "vmbr0", ip = "ip=10.0.50.140/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "redis-staging-02.paws360.ryannanney.com" , node = "pve-node-1", bridge = "vmbr0", ip = "ip=10.0.50.141/24,gw=10.0.50.1", cores=2, memory=4096},
    { name = "redis-staging-03.paws360.ryannanney.com" , node = "pve-node-2", bridge = "vmbr0", ip = "ip=10.0.50.142/24,gw=10.0.50.1", cores=2, memory=4096},
  ]
}
