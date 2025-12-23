#!/bin/bash
set -e

RULES_DIR="/etc/snort/rules"
sudo mkdir -p "$RULES_DIR"

# Copy our lab rule into Snort rules directory
sudo cp /lab/local.rules "$RULES_DIR/local.rules"

# Ensure snort.conf includes local.rules
if ! sudo grep -q 'local.rules' /etc/snort/snort.conf; then
  echo "include \$RULE_PATH/local.rules" | sudo tee -a /etc/snort/snort.conf > /dev/null
fi

# Run snort (console alerts)
sudo snort -A console -q -c /etc/snort/snort.conf -i any
