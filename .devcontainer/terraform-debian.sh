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

# Install Terraform using official HashiCorp APT repo
export DEBIAN_FRONTEND=noninteractive
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor --batch --yes | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
ARCH=$(dpkg --print-architecture)
CODENAME=$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs)
echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update

if [ "${TERRAFORM_VERSION}" = "latest" ]; then
    apt-get install -y terraform
else
    # Try to install the specific version, fallback with error if not found
    if apt-cache madison terraform | grep -q "${TERRAFORM_VERSION}"; then
        apt-get install -y terraform="${TERRAFORM_VERSION}"
    else
        echo "ERROR: Terraform version ${TERRAFORM_VERSION} not found in APT repo."
        echo "Available versions:"
        apt-cache madison terraform
        exit 1
    fi
fi

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