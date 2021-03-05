variable "name" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "pinned_public_ip_subnet_eips" {
  type    = list(string)
  default = []
}

variable "paranoco_arch_version" {
  type = string
  default = "beryllium"
}