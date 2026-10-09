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

get_latest_from_github 'sharkdp/bat' 'x86_64-unknown-linux-musl.tar.gz' 2>/dev/null | tar xz -C "$INSTALL_PATH" --strip 1


