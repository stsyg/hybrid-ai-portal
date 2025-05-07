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
  - curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
  - sleep 10
  - TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
  - az login --identity
  - az keyvault secret set --vault-name ${kv_name} --name k3s-token --value $TOKEN
  - mkdir -p /home/${admin_username}/.kube
  - cp /etc/rancher/k3s/k3s.yaml /home/${admin_username}/.kube/config
  - chown -R ${admin_username}:${admin_username} /home/${admin_username}/.kube
  - chmod 600 /home/${admin_username}/.kube/config