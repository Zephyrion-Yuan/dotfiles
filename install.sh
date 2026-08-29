#!/bin/sh

set -eu

dotfiles_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
backup_stamp=$(date '+%Y%m%d-%H%M%S')

link_config() {
    source_path=$1
    target_path=$2

    mkdir -p "$(dirname -- "$target_path")"

    if [ -e "$target_path" ] && [ "$target_path" -ef "$source_path" ]; then
        printf 'already linked: %s\n' "$target_path"
        return
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        backup_path="${target_path}.pre-dotfiles-${backup_stamp}"
        mv "$target_path" "$backup_path"
        printf 'backed up:     %s -> %s\n' "$target_path" "$backup_path"
    fi

    ln -s "$source_path" "$target_path"
    printf 'linked:        %s -> %s\n' "$target_path" "$source_path"
}

for app in alacritty nvim wezterm yazi; do
    link_config "$dotfiles_dir/home/.config/$app" "$HOME/.config/$app"
done

# Herdr keeps live session state and logs beside its config, so link only the
# portable config file rather than replacing the entire runtime directory.
link_config "$dotfiles_dir/home/.config/herdr/config.toml" \
    "$HOME/.config/herdr/config.toml"

link_config "$dotfiles_dir/home/.bashrc" "$HOME/.bashrc"

printf '\nDotfiles installed. Existing files were retained as *.pre-dotfiles-%s.\n' \
    "$backup_stamp"
