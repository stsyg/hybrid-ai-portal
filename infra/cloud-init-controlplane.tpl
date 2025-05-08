#cloud-config
package_update: true
packages:
  - curl
  - ca-certificates
  - apt-transport-https
  - lsb-release
  - gnupg

runcmd:
  # Prep for Azure CLI install
  - curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
  - install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
  - sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list'
  - apt-get update
  - apt-get install -y azure-cli

  # Install K3s control plane
  - curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
  - sleep 10

  # Save the K3s token to Azure Key Vault
  - TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
  - az login --identity
  - az keyvault secret set --vault-name ${kv_name} --name k3s-token --value $TOKEN

  # Prep kubeconfig for admin user
  - mkdir -p /home/${admin_username}/.kube
  - cp /etc/rancher/k3s/k3s.yaml /home/${admin_username}/.kube/config
  - chown -R ${admin_username}:${admin_username} /home/${admin_username}/.kube
  - chmod 600 /home/${admin_username}/.kube/config

  # Ensure ~/.azure exists before using az CLI as user
  - sudo -u ${admin_username} mkdir -p /home/${admin_username}/.azure
  - sudo -u ${admin_username} az login --identity

  #   # Assign Azure Connected Machine Onboarding role to this VM's managed identity
  # - VM_ID=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2021-02-01&format=text")
  # - PRINCIPAL_ID=$(az vm show --name $VM_ID --resource-group ${arc_cluster_rg} --query identity.principalId -o tsv)
  # - az role assignment create --assignee "$PRINCIPAL_ID" --role "Azure Connected Machine Onboarding" --scope "/subscriptions/${subscription_id}/resourceGroups/${arc_cluster_rg}"

  # Install required Arc CLI extensions as non-root
  - sudo -u ${admin_username} az extension add --name connectedk8s
  - sudo -u ${admin_username} az extension add --name k8s-configuration
  - sudo -u ${admin_username} az extension add --name k8s-extension
  - sudo -u ${admin_username} az extension add --name customlocation

  # Onboard to Azure Arc using managed identity
  - sudo -u ${admin_username} az connectedk8s connect --name ${arc_cluster_name} --resource-group ${arc_cluster_rg} --location ${arc_location} --tags Role="K3s-Arc"
