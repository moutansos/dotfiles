# syntax=docker/dockerfile:1.7

FROM golang:bookworm AS golang

FROM mcr.microsoft.com/dotnet/sdk:latest

ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/ben \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    GOPATH=/home/ben/go \
    N_PREFIX=/home/ben/n \
    BUN_INSTALL=/home/ben/.bun \
    PATH=/usr/local/go/bin:/opt/nvim/bin:/home/ben/.bun/bin:/home/ben/.opencode/bin:/home/ben/n/bin:/home/ben/go/bin:/home/ben/.local/bin:${PATH}

RUN apt-get update \
    && curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm -f /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        fd-find \
        fzf \
        git \
        git-lfs \
        jq \
        less \
        locales \
        openssh-client \
        pkg-config \
        powershell \
        procps \
        ripgrep \
        stow \
        sudo \
        tmux \
        unzip \
        xz-utils \
        zsh \
    && locale-gen en_US.UTF-8 \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && if ! id -u ben >/dev/null 2>&1; then useradd --create-home --shell /bin/zsh ben; fi \
    && mkdir -p /home/ben \
    && chsh -s /bin/zsh ben \
    && usermod -aG sudo ben \
    && echo 'ben ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ben \
    && chmod 0440 /etc/sudoers.d/ben \
    && mkdir -p /home/ben/source/repos /home/ben/source/local /home/ben/.config /home/ben/.local/bin /home/ben/go \
    && chown -R ben:ben /home/ben \
    && rm -rf /var/lib/apt/lists/*

COPY --from=golang /usr/local/go /usr/local/go

RUN case "${TARGETARCH:-amd64}" in \
        amd64) nvim_arch='x86_64' ;; \
        arm64) nvim_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" -o /tmp/nvim.tar.gz \
    && rm -rf /opt/nvim \
    && tar -C /opt -xzf /tmp/nvim.tar.gz \
    && mv "/opt/nvim-linux-${nvim_arch}" /opt/nvim \
    && rm -f /tmp/nvim.tar.gz \
    && curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin \
    && chown -R ben:ben /home/ben/.cache

COPY --chown=ben:ben zsh/.zshrc /home/ben/.zshrc
COPY --chown=ben:ben zsh/benbrougher-tech.omp.json /home/ben/benbrougher-tech.omp.json
COPY --chown=ben:ben tmux/.tmux.conf /home/ben/.tmux.conf
COPY --chown=ben:ben op/config.json /home/ben/op-config.json

RUN mkdir -p /templates/source/repos /templates/source/local \
    && chown -R ben:ben /templates

USER ben
WORKDIR /home/ben/source

RUN curl -fsSL https://bun.sh/install | bash \
    && curl -fsSL https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-install | bash -s -- -y latest \
    && npm install -g npm@latest \
    && curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path \
    && git clone --depth=1 https://code.msyke.dev/mSyke/nvim-config /home/ben/.config/nvim \
    && git clone --depth=1 https://github.com/moutansos/op /templates/source/repos/op \
    && git config --global init.defaultBranch main \
    && cp /home/ben/op-config.json /templates/source/repos/op/config.json \
    && make -C /templates/source/repos/op/native \
    && printf '.nfs*\n' > /home/ben/.gitignore_global \
    && git config --global core.excludesfile /home/ben/.gitignore_global \
    && printf '#!/bin/bash\npwsh ~/source/repos/op/Open-Project.ps1 "$@"\n' > /home/ben/.local/bin/op \
    && chmod +x /home/ben/.local/bin/op

USER root

COPY container-files/init-source /usr/local/bin/init-source
COPY container-files/container-entrypoint /usr/local/bin/container-entrypoint

RUN chmod +x /usr/local/bin/init-source /usr/local/bin/container-entrypoint \
    && tar -C /home/ben -czf /opt/home-template.tar.gz .

USER ben

ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
CMD ["sleep", "infinity"]
