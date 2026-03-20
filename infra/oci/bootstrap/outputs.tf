output "vcn_id" {
  description = "VCN OCID"
  value       = oci_core_vcn.this.id
}

output "internet_gateway_id" {
  description = "Internet Gateway OCID"
  value       = oci_core_internet_gateway.this.id
}

output "route_table_id" {
  description = "Route Table OCID"
  value       = oci_core_route_table.this.id
}
