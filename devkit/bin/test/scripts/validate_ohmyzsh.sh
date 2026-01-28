set -e 

echo "Validating oh-my-zsh installation..."

test -f ~/.oh-my-zsh/oh-my-zsh.sh     && echo "✓ Main script exists" || echo "✗ Main script does not exist"
test -f ~/.oh-my-zsh/tools/upgrade.sh && echo "✓ Tools exist"        || echo "✗ Tools do not exist"
test -d ~/.oh-my-zsh/lib              && echo "✓ Library exists"     || echo "✗ Library does not exist"
test -d ~/.oh-my-zsh/themes           && echo "✓ Themes exist"       || echo "✗ Themes do not exist"
test -d ~/.oh-my-zsh/plugins          && echo "✓ Plugins exist"      || echo "✗ Plugins do not exist"