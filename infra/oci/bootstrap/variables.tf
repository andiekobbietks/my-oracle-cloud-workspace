variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "compartment_id" {
  description = "Compartment OCID where resources will be created"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for a subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vcn_display_name" {
  description = "Human-friendly VCN name"
  type        = string
  default     = "bootstrap-vcn"
}

variable "subnet_display_name" {
  description = "Human-friendly Subnet name"
  type        = string
  default     = "bootstrap-subnet"
}

variable "vault_display_name" {
  description = "Vault display name"
  type        = string
  default     = "bootstrap-vault"
}
