# You can pick any Debian/Ubuntu-based image. 😊
# the line below uses latest Ubuntu image
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y \
       zsh \
       graphviz \
       git \
       curl \
       ca-certificates \
       unzip \
       jq \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Set zsh as default shell for vscode user
RUN usermod --shell /usr/bin/zsh vscode

# Install Oh My Zsh for vscode user if not already present, set theme and completions
RUN if [ ! -d /home/vscode/.oh-my-zsh ]; then \
      su vscode -c 'export RUNZSH=no CHSH=no KEEP_ZSHRC=yes && bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'; \
    fi && \
    echo 'fpath+=(/usr/share/zsh-completions)' >> /home/vscode/.zshrc && \
    echo 'autoload -U compinit && compinit' >> /home/vscode/.zshrc && \
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="agnoster"/' /home/vscode/.zshrc && \
    chown vscode:vscode /home/vscode/.zshrc

# [Option] Install Azure CLI
ARG INSTALL_AZURE_CLI="true"
# [Option] Install Docker CLI
ARG INSTALL_DOCKER="true"

# Install Terraform & tflint
ARG TERRAFORM_VERSION
ARG TFLINT_VERSION

# Install kubectl (needed for K3s management)
RUN curl -sSL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Copy and run custom Terraform/tflint install script
COPY terraform-debian.sh /tmp/terraform-debian.sh
RUN sed -i 's/\r$//' /tmp/terraform-debian.sh \
    && bash /tmp/terraform-debian.sh "${TERRAFORM_VERSION}" "${TFLINT_VERSION}" \
    && rm -f /tmp/terraform-debian.sh

# Some people have git config pointed at a different gpg location
RUN ln -s /usr/bin/gpg /usr/local/bin/gpg

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>