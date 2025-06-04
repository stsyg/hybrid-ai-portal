#cloud-config
package_update: true
packages:
  - curl
  - ca-certificates
  - apt-transport-https
  - lsb-release
  - gnupg

runcmd:
  - curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
  - install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
  - sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list'
  - apt-get update
  - apt-get install -y azure-cli
  - az login --identity
  - bash -c 'TOKEN=$(az keyvault secret show --vault-name "${kv_name}" --name k3s-token --query value -o tsv) && curl -sfL https://get.k3s.io | K3S_URL=https://${cp_ip}:6443 K3S_TOKEN=$TOKEN sh -'
