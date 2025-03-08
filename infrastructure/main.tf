terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# SSH Key Resource
resource "hcloud_ssh_key" "openedx_key" {
  name       = "openedx-key"
  public_key = file(var.ssh_public_key_path)
}

# Network Setup
resource "hcloud_network" "openedx_network" {
  name     = "openedx-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "openedx_subnet" {
  network_id   = hcloud_network.openedx_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Security Groups
resource "hcloud_firewall" "openedx_fw" {
  name = "openedx-firewall"

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Production VMs
resource "hcloud_server" "openedx_production" {
  count       = var.production_vm_count
  name        = "openedx-prod-${count.index + 1}"
  server_type = var.production_server_type
  image       = var.server_image
  location    = element(var.locations, count.index % length(var.locations))
  ssh_keys    = [hcloud_ssh_key.openedx_key.id]
  firewall_ids = [hcloud_firewall.openedx_fw.id]
  
  network {
    network_id = hcloud_network.openedx_network.id
    ip         = "10.0.1.${count.index + 10}"
  }

  user_data = templatefile("${path.module}/cloud-init-production.yml", {
    vm_index = count.index + 1
    couchdb_user = var.couchdb_user
    couchdb_password = var.couchdb_password
    other_node_ips = [for i in range(var.production_vm_count) : "10.0.1.${i + 10}" if i != count.index]
    domain_name = var.domain_name  # Add this line
  })

  depends_on = [
    hcloud_network_subnet.openedx_subnet
  ]
}

# Backup VM
resource "hcloud_server" "openedx_backup" {
  name        = "openedx-backup"
  server_type = var.backup_server_type
  image       = var.server_image
  location    = var.backup_location
  ssh_keys    = [hcloud_ssh_key.openedx_key.id]
  firewall_ids = [hcloud_firewall.openedx_fw.id]
  
  network {
    network_id = hcloud_network.openedx_network.id
    ip         = "10.0.1.100"
  }

  user_data = templatefile("${path.module}/cloud-init-backup.yml", {
    couchdb_user = var.couchdb_user
    couchdb_password = var.couchdb_password
    production_node_ips = [for i in range(var.production_vm_count) : "10.0.1.${i + 10}"]
  })

  depends_on = [
    hcloud_network_subnet.openedx_subnet
  ]
}

# Output information
output "production_ips" {
  value = hcloud_server.openedx_production[*].ipv4_address
  description = "Public IP addresses of production VMs"
}

output "backup_ip" {
  value = hcloud_server.openedx_backup.ipv4_address
  description = "Public IP address of backup VM"
}

output "internal_network" {
  value = hcloud_network.openedx_network.ip_range
  description = "Internal network range"
}

