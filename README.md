# Hybrid AI Portal aka HAIP

A self-hosted LLM web portal powered by Ollama on Azure Arc-enabled K3s.

## Authentication with Azure CLI

Before deploying any infrastructure, ensure you are authenticated to Azure using the device login flow.

### Step-by-Step

1. Open a terminal and run:

```sh
az login --use-device-code
```

2. You’ll be given a code and a URL. Open the URL in your browser and enter the code to sign in.

3. After successful login, confirm the account and tenant:

```sh
az account show
```


