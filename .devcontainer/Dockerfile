FROM debian:9-slim

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Set up non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY scripts/non-root-user.sh /tmp
RUN bash /tmp/non-root-user.sh "${USERNAME}" "${USER_UID}" "${USER_GID}" && rm /tmp/non-root-user.sh

# Terraform and tflint versions
ARG TERRAFORM_VERSION=0.12.29
ARG TFLINT_VERSION=0.8.2

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog icu-devtools 2>&1 \
    # install git iproute2, required tools installed
    && apt-get install -y \
    git \
    openssh-client \
    less \
    curl \
    procps \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    bash-completion \
    sudo \
    lsb-release 2>&1 \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install the Azure CLI
COPY scripts/install-az.sh /tmp
RUN /tmp/install-az.sh && rm /tmp/install-az.sh

# Install Terraform and tflint
RUN mkdir -p /tmp/dc-downloads \
     && curl -sSL -o /tmp/dc-downloads/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
     && unzip /tmp/dc-downloads/terraform.zip \
     && mv terraform /usr/local/bin \
     && terraform -install-autocomplete \
     # Install tflint
     && curl -sSL -o /tmp/dc-downloads/tflint.zip https://github.com/wata727/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
     && unzip /tmp/dc-downloads/tflint.zip \
     && mv tflint /usr/local/bin \
     # Clean up downloaded files
     && cd ~ \ 
     && rm -rf /tmp/dc-downloads

# Save command line history 
RUN echo "export HISTFILE=/home/vscode/commandhistory/.bash_history" >> "/home/vscode/.bashrc" \
     && echo "export PROMPT_COMMAND='history -a'" >> "/home/vscode/.bashrc" \
     && mkdir -p /home/vscode/commandhistory \
     && touch /home/vscode/commandhistory/.bash_history \
     && chown -R vscode /home/vscode/commandhistory

# Bash customization
RUN \
    ## Git command prompt
    git clone https://github.com/magicmonty/bash-git-prompt.git /home/vscode/.bash-git-prompt --depth=1 \
    && echo "if [ -f \"/home/vscode/.bash-git-prompt/gitprompt.sh\" ]; then GIT_PROMPT_ONLY_IN_REPO=1 && GIT_PROMPT_FETCH_REMOTE_STATUS=0 && source /home/vscode/.bash-git-prompt/gitprompt.sh; fi" >> "/home/vscode/.bashrc" \
    ## Add aliases
    && echo "alias tf=terraform" >> "/home/vscode/.bashrc"

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
