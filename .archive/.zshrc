# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git)

# source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
if [ -f $HOME/.common.bz.sh ]; then
    source $HOME/.common.bz.sh
fi

export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"

export ZSH="$HOME/.oh-my-zsh"

# load zgenom
[ ! -d "${HOME}/.zgenom" ] && git clone --depth 1 https://github.com/jandamm/zgenom.git "${HOME}/.zgenom"
source "${HOME}/.zgenom/zgenom.zsh" > /dev/null

FZF_BASE=$HOME/.vim/plugged/fzf
### zgenom ###
zgenom autoupdate

if ! zgenom saved; then

	# echo "Creating a zgenom save"
	zgenom oh-my-zsh

	# plugins
	zgenom oh-my-zsh plugins/git
    # zgenom oh-my-zsh plugins/fzf
	zgenom oh-my-zsh plugins/sudo
	zgenom oh-my-zsh plugins/python
	zgenom oh-my-zsh plugins/systemd
    zgenom oh-my-zsh plugins/docker
    # zgenom oh-my-zsh plugins/virtualenvwrapper
    zgenom oh-my-zsh plugins/pip
    zgenom oh-my-zsh plugins/vi-mode
    zgenom oh-my-zsh plugins/command-not-found
	# just load the completions for docker-compose
	zgenom oh-my-zsh --completions plugins/docker-compose

    zgenom load lukechilds/zsh-nvm
    zgenom load Aloxaf/fzf-tab 
    zgenom load zsh-users/zsh-syntax-highlighting
    zgenom load zsh-users/zsh-history-substring-search
    zgenom load zsh-users/zsh-autosuggestions
    zgenom load zsh-users/zsh-completions
    # zgenom load RobSis/zsh-completions-generator
    zgen load MichaelAquilina/zsh-autoswitch-virtualenv

	# Install ohmyzsh osx plugin if on macOS
	#[[ "$(uname -s)" = Darwin ]] && zgenom ohmyzsh plugins/macos
    zgenom save
    zgenom compile "$HOME/.zshrc"
fi
### Install Path ###
export INSTALL_PATH="$HOME/.local"
export PATH="$INSTALL_PATH/bin:$PATH"

if command apt --version 1> /dev/null 2>&1; then
	# debian
	# Usually personal computer
	alias shutdown='sudo shutdown -h now'
	alias reboot='sudo reboot'
	alias start='nautilus'
elif command yum --version 1> /dev/null 2>&1; then
	# red-hat
fi

alias emacs='emacs -nw'
if command nvim --version 1>/dev/null 2>&1; then
    alias vim='nvim'
fi

eval "$(dircolors $HOME/.dircolors)"

### STARSHIP ###
# eval "$(starship init zsh)"
### END OF STARSHIP ###

# To customize prompt, run `p10k configure` or edit ~/workspace/configs/.p10k.zsh.
# [[ ! -f ~/workspace/configs/.p10k.zsh ]] || source ~/workspace/configs/.p10k.zsh

### NVM ###
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
### END OF NVM ###

alias cd='pushd'
alias back='popd'

# Enable fzf-tab
# enable-fzf-tab

##### Bind key #####
bindkey '^ ' autosuggest-accept
##### End of Bind key #####

if [ ! -f ~/.fzf.zsh ]; then
    $FZF_BASE/install --all    
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -x "$(command -v neofetch)" ] && neofetch

# export PATH="$HOME/.rbenv/bin:$PATH"
# eval "$(rbenv init -)"
