set -e

echo "Validating powerlevel10k installation..."

test -d ~/.oh-my-zsh/custom/themes/powerlevel10k                           && echo "✓ Theme directory exists"  || echo "✗ Theme directory not found"
test -f ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme   && echo "✓ Theme file exists"       || echo "✗ Theme file not found"
test -f ~/.p10k.zsh                                                        && echo "✓ P10k config exists"      || echo "✗ P10k config not found"
test -s ~/.p10k.zsh                                                        && echo "✓ P10k config is valid"    || echo "✗ P10k config is empty"
