#!/bin/bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

# Create .oci directory
mkdir -p ~/.oci

# Use the Secrets to recreate the config and key files
echo "$OCI_CONFIG_CONTENT" > ~/.oci/config
echo "$OCI_PRIVATE_KEY" > ~/.oci/oci_api_key.pem
chmod 600 ~/.oci/oci_api_key.pem

# Update config to point to the correct key location
sed -i 's|key_file=.*|key_file=~/.oci/oci_api_key.pem|g' ~/.oci/config

echo "OCI CLI Setup Complete. Try running 'oci os ns get'"
