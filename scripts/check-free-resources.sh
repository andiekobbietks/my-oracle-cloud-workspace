#!/usr/bin/env bash
set -euo pipefail
COMP=${1:-${OCI_TENANCY_OCID:-}}
if [ -z "$COMP" ]; then
  echo "Usage: $0 <compartment-ocid> or set OCI_TENANCY_OCID" >&2
  exit 2
fi
echo "=== OCI ALWAYS FREE RESOURCE AUDIT for compartment $COMP ==="
echo "\n[COMPUTE INSTANCES]"
oci compute instance list --compartment-id "$COMP" --query "data[*].{Name:display-name,State:lifecycle-state,Shape:shape}" --output table || true
echo "\n[BOOT / BLOCK VOLUMES]"
oci bv boot-volume list --compartment-id "$COMP" --query "data[*].{Name:display-name,Size:size-in-gbs}" --output table || true
echo "\n[OBJECT STORAGE BUCKETS]"
NS=$(oci os ns get --query data --raw-output 2>/dev/null || echo "")
if [ -n "$NS" ]; then
  oci os bucket list --compartment-id "$COMP" --namespace-name "$NS" --query "data[*].{Name:name,Tier:storage-tier,Created:time-created}" --output table || true
else
  echo "Object Storage namespace unavailable or OCI not configured."
fi
echo "\n[AUTONOMOUS DATABASES (free-tier)]"
oci db autonomous-database list --compartment-id "$COMP" --query "data[?\"is-free-tier\"==\`true\`].{Name:display-name,State:lifecycle-state,DBName:db-name}" --output table || true
echo "\n[VCNs]"
oci network vcn list --compartment-id "$COMP" --query "data[*].{Name:display-name,CIDR:cidr-block,State:lifecycle-state}" --output table || true
echo "\n[PUBLIC IPs]"
oci network public-ip list --compartment-id "$COMP" --query "data[*].{IP:ip-address,Type:lifetime,Name:display-name}" --output table || true
echo "\n[LOAD BALANCERS]"
oci lb load-balancer list --compartment-id "$COMP" --query "data[*].{Name:display-name,Shape:shape,State:lifecycle-state}" --output table || true
echo "\n=== END OF AUDIT ==="
