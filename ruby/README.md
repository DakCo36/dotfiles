# Dotfiles Ruby installer

## Shell components

### Oh My Posh (Linux)
- Component: `Component::OhMyPoshComponent`
- Installs the latest Linux AMD64 Oh My Posh binary to `$HOME/.local/bin/oh-my-posh` using `curl`.
- Seeds a starter theme at `$HOME/.poshthemes/default.omp.json` from `ruby/data/oh_my_posh/default.omp.json`.
- Designed for Ubuntu/Linux shells; Windows installation is not handled here.
