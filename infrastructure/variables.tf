variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "production_vm_count" {
  description = "Number of production VMs"
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Domain name for the Open edX installation"
  type        = string
  default     = "yourdomain.com"  # Set your default domain or leave blank
}

variable "production_server_type" {
  description = "Server type for production VMs"
  type        = string
  default     = "cpx41" # 8 GB RAM, 4 vCPUs, 160 GB SSD
}

variable "backup_server_type" {
  description = "Server type for backup VM"
  type        = string
  default     = "cpx21" # 4 GB RAM, 2 vCPUs, 80 GB SSD
}

variable "server_image" {
  description = "OS image for all servers"
  type        = string
  default     = "ubuntu-22.04"
}

variable "locations" {
  description = "Hetzner locations for production VMs"
  type        = list(string)
  default     = ["nbg1", "fsn1", "hel1"] # Nuremberg, Falkenstein, Helsinki
}

variable "backup_location" {
  description = "Hetzner location for backup VM"
  type        = string
  default     = "fsn1" # Falkenstein
}

variable "couchdb_user" {
  description = "Username for CouchDB"
  type        = string
  default     = "admin"
}

variable "couchdb_password" {
  description = "Password for CouchDB"
  type        = string
  sensitive   = true
}

