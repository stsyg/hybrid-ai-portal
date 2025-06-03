#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/master/script-library/docs/terraform.md
# Maintainer: The VS Code and Codespaces Teams
#
# Syntax: ./terraform-debian.sh [terraform version] [tflint version] [terragrunt version]

TERRAFORM_VERSION=${1:-"latest"}
TFLINT_VERSION=${2:-"latest"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ "${TERRAFORM_VERSION}" = "latest" ] || [ "${TERRAFORM_VERSION}" = "lts" ] || [ "${TERRAFORM_VERSION}" = "current" ]; then
    TERRAFORM_VERSION=$(curl -fLsS https://releases.hashicorp.com/terraform/ | grep -oE '>terraform_[0-9]+\.[0-9]+\.[0-9]+<' | sed 's/^>terraform_\(.*\)<$/\1/' | sort -V | tail -n 1)
fi

if [ -z "$TERRAFORM_VERSION" ]; then
    echo "ERROR: Failed to resolve Terraform version."
    exit 1
fi

echo "Resolved TERRAFORM_VERSION: $TERRAFORM_VERSION"

if [ "${TFLINT_VERSION}" = "latest" ] || [ "${TFLINT_VERSION}" = "lts" ] || [ "${TFLINT_VERSION}" = "current" ]; then
    LATEST_RELEASE=$(curl -fLsS -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/terraform-linters/tflint/releases?per_page=1&page=1")
    TFLINT_VERSION=$(echo ${LATEST_RELEASE} | grep -oE 'tag_name":\s*"v[^"]+' | sed -n '/tag_name":\s*"v/s///p')
fi

# Install curl, unzip if missing
if ! dpkg -s curl ca-certificates unzip > /dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        apt-get update
    fi
    apt-get -y install --no-install-recommends curl ca-certificates unzip
fi

# Always install Terraform via manual download (no APT repo logic)
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" = "amd64" ]; then
    TF_ARCH="amd64"
else
    echo "ERROR: Only amd64 architecture is supported by this script." >&2
    exit 1
fi

TF_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip"
TF_SHA256_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"
mkdir -p /tmp/tf-downloads && cd /tmp/tf-downloads
curl -fLsS -o terraform.zip "$TF_URL"
curl -fLsS -o SHA256SUMS "$TF_SHA256_URL"
if command -v sha256sum >/dev/null 2>&1; then
    grep "terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" SHA256SUMS | sha256sum -c -
fi
unzip terraform.zip
mv -f terraform /usr/local/bin/
cd -
rm -rf /tmp/tf-downloads

# Download and install tflint (no official SHA256, so just download)
if [ "${TFLINT_VERSION}" != "none" ]; then
    echo "Downloading tflint..."
    curl -fLsS -o tflint.zip https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip
    unzip tflint.zip
    mv -f tflint /usr/local/bin/
fi

rm -rf /tmp/tf-downloads
cd -
echo "Done!"