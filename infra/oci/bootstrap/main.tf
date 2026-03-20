// NOTE: This module is scaffolded to be safe by default. Example resource
// blocks are provided as commented snippets. Enable provider resources once
// you are ready to apply and have configured backend/state accordingly.

// Implement minimal Always‑Free-safe networking resources by default:
// - VCN (virtual cloud network)
// - Internet Gateway (non-billable network construct)
// - Route Table (for routing public traffic)
// These networking constructs do not incur compute charges on their own.

resource "oci_core_vcn" "this" {
	compartment_id = var.compartment_id
	cidr_block     = var.vcn_cidr
	display_name   = var.vcn_display_name
}

resource "oci_core_internet_gateway" "this" {
	compartment_id = var.compartment_id
	vcn_id         = oci_core_vcn.this.id
	display_name   = "${var.vcn_display_name}-igw"
}

resource "oci_core_route_table" "this" {
	compartment_id = var.compartment_id
	vcn_id         = oci_core_vcn.this.id
	display_name   = "${var.vcn_display_name}-routetable"

	route_rules = [
		{
			cidr_block        = "0.0.0.0/0"
			network_entity_id = oci_core_internet_gateway.this.id
			description       = "route to internet"
		}
	]
}

// Optional: subnet, compute, vault creation are intentionally omitted or
// left commented because not all of those resources are guaranteed to be
// Always Free across regions/tenancies. If you enable compute or vault,
// ensure you choose Always Free shapes and verify your tenancy eligibility.

