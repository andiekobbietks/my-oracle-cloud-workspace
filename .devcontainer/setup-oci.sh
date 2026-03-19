echo "OCI CLI Setup Complete. Try running 'oci os ns get'"
#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  OCI Environment Setup Wizard"
echo "=========================================="

check_secrets() {
	local missing=()
	if [ -z "${OCI_CONFIG_CONTENT:-}" ]; then missing+=("OCI_CONFIG_CONTENT"); fi
	if [ -z "${OCI_PRIVATE_KEY:-}" ]; then missing+=("OCI_PRIVATE_KEY"); fi
	if [ ${#missing[@]} -eq 0 ]; then
		echo -e "${GREEN}✓ All required secrets detected${NC}"
		return 0
	fi
	echo -e "${RED}✗ Missing required secrets:${NC}"
	for s in "${missing[@]}"; do
		echo "  - $s"
	done
	echo ""
	echo "Add them at: https://github.com/$GITHUB_REPOSITORY/settings/secrets/actions"
	echo "Then rebuild the Codespace (Rebuild Container) after adding secrets."
	return 1
}

install_oci_cli() {
	if command -v oci &> /dev/null; then
		echo -e "${GREEN}✓ OCI CLI already installed: $(oci --version)${NC}"
		return 0
	fi
	echo -e "${BLUE}→ Installing OCI CLI...${NC}"
	for i in 1 2 3; do
		if bash -c "$(curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults; then
			echo -e "${GREEN}✓ OCI CLI installed successfully${NC}"
			return 0
		fi
		echo -e "${YELLOW}Retry $i/3...${NC}"
		sleep 5
	done
	echo -e "${RED}✗ Failed to install OCI CLI${NC}"
	return 1
}

setup_credentials() {
	echo -e "${BLUE}→ Setting up OCI credentials...${NC}"
	mkdir -p "$HOME/.oci"

	# Basic validation for config
	if ! echo "$OCI_CONFIG_CONTENT" | grep -q "\[DEFAULT\]"; then
		echo -e "${RED}✗ OCI_CONFIG_CONTENT looks invalid (missing [DEFAULT]).${NC}"
		return 1
	fi

	# Atomic write
	tmpdir=$(mktemp -d)
	trap 'rm -rf "$tmpdir"' EXIT
	echo "$OCI_CONFIG_CONTENT" > "$tmpdir/config"
	echo "$OCI_PRIVATE_KEY" > "$tmpdir/oci_api_key.pem"
	chmod 600 "$tmpdir/oci_api_key.pem"

	mv "$tmpdir/config" "$HOME/.oci/config"
	mv "$tmpdir/oci_api_key.pem" "$HOME/.oci/oci_api_key.pem"
	chmod 600 "$HOME/.oci/config" "$HOME/.oci/oci_api_key.pem"

	# Update key path dynamically
	sed -i "s|key_file=.*|key_file=$HOME/.oci/oci_api_key.pem|g" "$HOME/.oci/config" || true

	echo -e "${GREEN}✓ Credentials written to $HOME/.oci${NC}"

	echo -e "${BLUE}→ Testing OCI connection...${NC}"
	if oci os ns get >/dev/null 2>&1; then
		echo -e "${GREEN}✓ OCI connection successful${NC}"
	else
		echo -e "${YELLOW}⚠ OCI connection test failed. Check your secrets and network.${NC}"
	fi
}

main() {
	if check_secrets; then
		install_oci_cli || true
		setup_credentials || true
		echo -e "${GREEN}=== SETUP COMPLETE ===${NC}"
	else
		echo -e "${YELLOW}=== SETUP INCOMPLETE: secrets missing. Build continues so you can add secrets. ===${NC}"
		exit 0
	fi
}

main
