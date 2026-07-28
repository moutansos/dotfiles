# syntax=docker/dockerfile:1.7

FROM archlinux:latest

ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV HOME=/home/ben \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    GOPATH=/home/ben/go \
    N_PREFIX=/home/ben/n \
    BUN_INSTALL=/home/ben/.bun \
    PATH=/opt/nvim/bin:/opt/microsoft/powershell/7:/home/ben/.bun/bin:/home/ben/.opencode/bin:/home/ben/n/bin:/home/ben/go/bin:/home/ben/.local/bin:${PATH}

RUN pacman -Sy --noconfirm archlinux-keyring \
    && pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
        base-devel \
        ca-certificates \
        curl \
        dotnet-sdk \
        fd \
        fzf \
        git \
        git-lfs \
        go \
        jq \
        less \
        openssh \
        pkgconf \
        procps-ng \
        ripgrep \
        stow \
        sudo \
        tmux \
        unzip \
        which \
        xz \
        zsh \
    && yes | pacman -Scc \

    && if ! id -u ben >/dev/null 2>&1; then useradd --create-home --shell /bin/zsh ben; fi \
    && mkdir -p /home/ben \
    && chsh -s /bin/zsh ben \
    && usermod -aG wheel ben \
    && echo 'ben ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ben \
    && chmod 0440 /etc/sudoers.d/ben \
    && mkdir -p /home/ben/source/repos /home/ben/source/local /home/ben/.config /home/ben/.local/bin /home/ben/go \
    && chown -R ben:ben /home/ben

RUN case "${TARGETARCH:-amd64}" in \
        amd64) nvim_arch='x86_64'; pwsh_arch='x64' ;; \
        arm64) nvim_arch='arm64'; pwsh_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" -o /tmp/nvim.tar.gz \
    && rm -rf /opt/nvim \
    && tar -C /opt -xzf /tmp/nvim.tar.gz \
    && mv "/opt/nvim-linux-${nvim_arch}" /opt/nvim \
    && rm -f /tmp/nvim.tar.gz \
    && pwsh_version="$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -r .tag_name | sed 's/^v//')" \
    && curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v${pwsh_version}/powershell-${pwsh_version}-linux-${pwsh_arch}.tar.gz" -o /tmp/powershell.tar.gz \
    && mkdir -p /opt/microsoft/powershell/7 \
    && tar -C /opt/microsoft/powershell/7 -xzf /tmp/powershell.tar.gz \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -sf /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh \
    && rm -f /tmp/powershell.tar.gz \
    && curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin \
    && chown -R ben:ben /home/ben/.cache

COPY --chown=ben:ben zsh/.zshrc /home/ben/.zshrc
COPY --chown=ben:ben zsh/benbrougher-tech.omp.json /home/ben/benbrougher-tech.omp.json
COPY --chown=ben:ben tmux/.tmux.conf /home/ben/.tmux.conf
COPY --chown=ben:ben op/config.json /home/ben/op-config.json

USER ben
WORKDIR /home/ben

RUN curl -fsSL https://bun.sh/install | bash \
    && curl -fsSL https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-install | bash -s -- -y latest \
    && npm install -g npm@latest \
    && curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path \
    && git clone --depth=1 https://code.msyke.dev/mSyke/nvim-config /home/ben/.config/nvim \
    && git clone --depth=1 https://github.com/moutansos/op /home/ben/source/repos/op \
    && git config --global init.defaultBranch main \
    && cp /home/ben/op-config.json /home/ben/source/repos/op/config.json \
    && make -C /home/ben/source/repos/op/native \
    && printf '.nfs*\n' > /home/ben/.gitignore_global \
    && git config --global core.excludesfile /home/ben/.gitignore_global \
    && printf '#!/bin/bash\npwsh ~/source/repos/op/Open-Project.ps1 "$@"\n' > /home/ben/.local/bin/op \
    && chmod +x /home/ben/.local/bin/op

USER root

COPY containers/files/container-entrypoint /usr/local/bin/container-entrypoint

RUN chmod +x /usr/local/bin/container-entrypoint \
    && tar -C /home/ben -czf /opt/home-template.tar.gz .

USER ben

ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
CMD ["sleep", "infinity"]
