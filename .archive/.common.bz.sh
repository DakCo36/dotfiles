
if [ -e "$HOME/.common.sh" ]; then
    source $HOME/.common.sh
fi

export ZSH_COMPLETION_PATH=$HOME/.local/share/zsh/vendor-completions
export BASH_COMPLETION_PATH=$HOME/.local/share/bash/vendor-completions
### import fzf ###
# End of fzf ###

if [ ! -d $ZSH_COMPLETION_PATH ]; then
    mkdir -p $ZSH_COMPLETION_PATH
fi
if [ ! -d $BASH_COMPLETION_PATH ]; then
    mkdir -p $BASH_COMPLETION_PATH
fi

if [[ ! $fpath =~ $ZSH_COMPLETION_PATH ]]; then
    fpath=($ZSH_COMPLETION_PATH $fpath)
fi
if [[ ! $FPATH =~ $BASH_COMPLETION_PATH ]]; then
    FPATH="$BASH_COMPLETION_PATH:$FPATH"
fi

### PYENV ###
export PYENV_HOME="$HOME/.pyenv"
export PATH="$PYENV_HOME/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
### END OF PYENV ###

#export FZF_DEFAULT_OPTS='-m --bind=ctrl-space:toggle,tab:down,shift-tab:up'
#if command -v bfs 2>&1 > /dev/null; then
	#export FZF_DEFAULT_COMMAND='bfs -L'
#elif command -v fd 2>&1 > /dev/null; then
	#export FZF_DEFAULT_COMMAND='fd -L'
#fi
#export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND 2> /dev/null"
#export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND 2> /dev/null"

## Use fd-based completion for the better performance
#_fzf_compgen_path() {
  #fd --hidden --follow --exclude ".git" . "$1"
#}

## Use fd to generate the list for directory completion
#_fzf_compgen_dir() {
  #fd --type d --hidden --follow --exclude ".git" . "$1"
#}

