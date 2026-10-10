#!/bin/bash
# .bash_profile

# Source bashrc

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs

# Run zsh as login shell
# Ref: https://mug896.github.io/bash-shell/login_non-login.html
# Ref: https://www.delftstack.com/howto/linux/difference-between-a-login-shell-and-a-non-login-shell/#:~:text=a%20login%20shell.-,What%20is%20a%20Non%2DLogin%20Shell%20in%20UNIX%2DBased%20Systems,start%20a%20non%2Dlogin%20shell.
export SHELL="$HOME/.local/bin/zsh"
exec $SHELL -l

