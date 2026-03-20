output "vcn_id" {
  description = "VCN OCID (once created)"
  value       = try(oci_core_vcn.this.id, "")
}

output "subnet_id" {
  description = "Subnet OCID (once created)"
  value       = try(oci_core_subnet.this.id, "")
}

output "vault_id" {
  description = "Vault OCID (once created)"
  value       = try(oci_kms_vault.this.id, "")
}
