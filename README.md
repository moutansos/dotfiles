# mSyke's dotfiles

## Run:

```sh
export TARGET_DIR=~
stow kitty -t $TARGET_DIR
stow sway -t $TARGET_DIR
stow zsh -t $TARGET_DIR
stow tmux -t $TARGET_DIR
stow qutebrowser -t $TARGET_DIR
```

## Containers

Dev images live under `containers/`:

- `containers/ubuntu` → `dotfiles-dev-ubuntu`
- `containers/arch` → `dotfiles-dev-arch`

```sh
./build.sh --docker-build                  # build all
./build.sh --docker-build --image arch     # build one
./build.sh --docker-run --image ubuntu     # build and run
```
