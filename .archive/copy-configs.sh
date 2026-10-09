#!/bin/bash

cp -f .common.sh $HOME/.common.sh 2>/dev/null
cp -f .common.bz.sh $HOME/.common.bz.sh 2>/dev/null
cp -f .vimrc $HOME/.vimrc 2>/dev/null
cp -f .zshrc $HOME/.zshrc 2>/dev/null
cp -f .p10k.zsh $HOME/.p10k.zsh 2>/dev/null

mkdir -p $HOME/.config && cp -f starship.toml $HOME/.config/starship.toml 2>/dev/null
cp -f .dircolors $HOME/.dircolors 2>/dev/null

# Nvim configuration
mkdir -p $HOME/.config/nvim && cp -f init.vim $HOME/.config/nvim/init.vim 2>/dev/null

# Helix configuration
mkdir -p $HOME/.config/helix && cp -f helix/languages.toml $HOME/.config/helix/languages.toml 2>/dev/null

# copy bash_profile to $HOME/.bash_profile
cp -f .bash_profile $HOME/.bash_profile 2>/dev/null

cp -f .tmux.conf $HOME/.tmux.conf 2>/dev/null
mkdir -p $HOME/.tmux/themes/
cp -R ./tmux/themes/* $HOME/.tmux/themes
