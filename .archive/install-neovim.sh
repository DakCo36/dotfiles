#!/bin/bash
if ! [ -z INSTALL_PATH ]; then
	INSTALL_PATH="$HOME/.local"
fi

get_latest_from_github() {
	# $1: user/repo
    # name_tag_suffix

	curl https://api.github.com/repos/$1/releases/latest |
		grep browser_download_url |
		grep -Po 'https://.*?'$2 | 
		xargs curl -L
}


get_latest_from_github 'neovim/neovim' 'nvim-linux64.tar.gz' 2>/dev/null | tar xz -C "$INSTALL_PATH" --strip 1

# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 2>/dev/null


# Install python plugins
pyenv --version 1> /dev/null 2> /dev/null
CHECK_PYENV=$(echo $?)
echo "pyenv --version: $CHECK_PYENV"

if [ $CHECK_PYENV == 0 ]; then
    pyenv update
    pyenv install -s 3.9.12  # TODO Install LTS automatically
    pyenv global 3.9.12
    python -m pip install pynvim
else
    echo "Pyenv is not installed"
fi
