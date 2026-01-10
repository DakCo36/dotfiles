#!/bin/bash

WORKING_DIR=$(pwd)


if ! [ -f $HOME/.local/bin/zsh ]; then
    echo "Download zsh"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)"  # < <(printf '2\nn\n')
fi

if ! [ -d $HOME/.oh-my-zsh ]; then
    echo "Download oh-my-zsh"
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"  # < <(printf 'y\n')
fi

if ! [ -d $HOME/.oh-my-zsh/custom/themes/powerlevel10k ]; then
	git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
fi

sed -ie '/^ZSH_THEME/s/robbyrussell/powerlevel10k\/powerlevel10k/g' ~/.zshrc 
if [ -f .p10k.zsh ]; then
	ln -sf $WORKING_DIR/.p10k.zsh $HOME/.p10k.zsh
fi

if ! (grep -q -E "^\# Enable Powerlevel10k" $HOME/.zshrc); then
	sed -i '1i # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.' $HOME/.zshrc
	sed -i '2i # Initialization code that may require console input (password prompts, [y/n]' $HOME/.zshrc
	sed -i '3i # confirmations, etc.) must go above this block; everything else may go below.' $HOME/.zshrc
	sed -i '4i if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then' $HOME/.zshrc
	sed -i '5i \ \ \ \ source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"' $HOME/.zshrc
	sed -i '6i fi' $HOME/.zshrc 
fi

if ! (grep -q -E "^\# To customize prompt*" $HOME/.zshrc); then	
	echo "# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> $HOME/.zshrc	
	echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> $HOME/.zshrc
fi

if ! [ -d $HOME/.zgenom ]; then
	git clone https://github.com/jandamm/zgenom.git "${HOME}/.zgenom"
	if ! (grep -q -E "^\# load zgenom" $HOME/.zshrc); then
		echo "# load zgenom" >> $HOME/.zshrc
		echo "[[ ! -f ${HOME}/.zgenom/zgenom.zsh ]] || source \"${HOME}/.zgenom/zgenom.zsh\"" >> $HOME/.zshrc
	fi
else
	echo "$HOME/.zgenom directory already exists"
fi

# Install starship theme 
# echo "Download starship"
# curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir $HOME/.local/bin
# 
# 
# echo "Success installing zsh"
# echo "Change default shell in /etc/passwd to $HOME/.local/bin/zsh"
