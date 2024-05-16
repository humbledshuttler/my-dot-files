#!/bin/bash

c_dir=$(basename "$PWD")
if [ "$c_dir" != "my-dot-files" ]; then
    echo "Run install.sh from the root directory"
    exit 1
fi

APT=/usr/bin/apt
DNF=/usr/bin/dnf

# Install Zsh if it's not already installed
if ! command -v zsh >/dev/null 2>&1; then
    if [ -f "$APT" ]; then
        echo "Found apt. Installing zsh"
        sudo apt update
        sudo apt install -y zsh
    elif [ -f "$DNF" ]; then
        echo "Found dnf. Installing zsh"
        sudo dnf install -y zsh
    fi
else
    echo "Zsh is already installed"
fi

# Check if tmux is already installed
if ! command -v tmux >/dev/null 2>&1; then
    # Install tmux
    if [ -f "$APT" ]; then
        sudo apt update
        sudo apt install -y tmux
    elif [ -f "$DNF" ]; then
        sudo dnf install -y tmux
    fi

    # Tell the user that tmux has been installed
    echo "tmux has been installed."
else
    echo "tmux is already installed"
fi

# Check if ctags is already installed
if ! command -v ctags >/dev/null 2>&1; then
    # Install universal-ctags or fall back to exuberant-ctags
    if [ -f "$APT" ]; then
        sudo apt update
        if apt-cache show universal-ctags >/dev/null 2>&1; then
            sudo apt install -y universal-ctags
        else
            sudo apt install -y exuberant-ctags
        fi
    elif [ -f "$DNF" ]; then
        sudo dnf install -y ctags
    fi

    # Tell the user that ctags has been installed
    echo "ctags has been installed."
else
    echo "ctags is already installed"
fi

working_dir=${PWD}

# Define the create_symlink function
create_symlink() {
    local source_path=$1
    local destination_path=$2

    # Check if the symlink already exists
    if [ -L "$destination_path" ]; then
        echo "Symlink ${destination_path} already exists."
    else
        # The symlink does not exist, so create it
        ln -s "$source_path" "$destination_path"
        echo "Symlink ${destination_path} created."
    fi
}

create_symlink ${working_dir}/dotoh-my-zsh ${HOME}/.oh-my-zsh
create_symlink ${working_dir}/dotzshrc ${HOME}/.zshrc

create_symlink ${working_dir}/dotvimrc ${HOME}/.vimrc
create_symlink ${working_dir}/dotvim ${HOME}/.vim

create_symlink ${working_dir}/dottmux.conf ${HOME}/.tmux.conf
create_symlink ${working_dir}/dottmux-plugins ${HOME}/.tmux-plugins
create_symlink ${working_dir}/dotgitconfig ${HOME}/.gitconfig
create_symlink ${working_dir}/dotp10k.zsh ${HOME}/.p10k.zsh

# Use sudo to create symbolic links in /usr/local/bin
for file in ${working_dir}/dev-tools/*; do
    sudo ln -s "$file" /usr/local/bin/
done

# Install powerlevel10k
if ! test -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"; then
    echo "Install powerlevel10k theme for zsh"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo "powerlevel10k already installed"
fi

# Use Zsh to source the .zshrc file
zsh -c "source ${HOME}/.zshrc"
