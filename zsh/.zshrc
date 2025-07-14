bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

bindkey '^R' history-incremental-search-backward

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory

# enable color support of ls and also add handy aliases
  if [ -x /usr/bin/dircolors ]; then
      test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      alias ls='ls --color=auto'
      alias dir='dir --color=auto'
      alias vdir='vdir --color=auto'
      alias grep='grep --color=auto'
      alias fgrep='fgrep --color=auto'
      alias egrep='egrep --color=auto'
  fi

# some more ls aliases
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'

export EDITOR=nvim

eval "$(oh-my-posh init zsh --config ~/benbrougher-tech.omp.json)"
export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).
export PATH=$PATH:/home/ben/.local/bin

if [ -f ~/.private_env ]; then
    source ~/.private_env
fi

if [ -f ~/.profile ]; then
    source ~/.profile
fi

if [ -f /home/ben/.deno/env ]; then
    . "/home/ben/.deno/env"
fi

# add Pulumi to the PATH
if [ -d /home/ben/.pulumi/bin ]; then
    export PATH=$PATH:/home/ben/.pulumi/bin
fi

# opencode
export PATH=/home/ben/.opencode/bin:$PATH

# bun completions
[ -s "/home/ben/.bun/_bun" ] && source "/home/ben/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
