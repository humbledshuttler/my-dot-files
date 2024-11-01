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

# Install Go if it's not already installed
if ! command -v go >/dev/null 2>&1; then
    if [ -f "$APT" ]; then
        echo "Found apt. Installing Go"
        sudo apt update
        sudo apt install -y golang
    elif [ -f "$DNF" ]; then
        echo "Found dnf. Installing Go"
        sudo dnf install -y golang
    fi
else
    echo "Go is already installed"
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

# Install Make if it's not already installed
if ! command -v make >/dev/null 2>&1; then
    if [ -f "$APT" ]; then
        echo "Found apt. Installing make"
        sudo apt update
        sudo apt install -y make
    elif [ -f "$DNF" ]; then
        echo "Found dnf. Installing make"
        sudo dnf install -y make
    fi
else
    echo "Make is already installed"
fi

# Install Vim if it's not already installed
if ! command -v vim >/dev/null 2>&1; then
    if [ -f "$APT" ]; then
        echo "Found apt. Installing vim"
        sudo apt update
        sudo apt install -y vim
    elif [ -f "$DNF" ]; then
        echo "Found dnf. Installing vim"
        sudo dnf install -y vim
    fi
else
    echo "Vim is already installed"
fi

working_dir=${PWD}

# Define the create_symlink function
create_symlink() {
    local source_path=$1
    local destination_path=$2

    if [ "$YES_TO_ALL" = "true" ]; then
        # Force overwrite if YES_TO_ALL is true
        ln -sf "$source_path" "$destination_path"
        echo "Symlink ${destination_path} created."
        return
    fi

    # Check if the destination file already exists
    if [ -e "$destination_path" ]; then
        read -p "File '$destination_path' already exists. Do you want to overwrite it? (y/n/a): " answer
        case ${answer:0:1} in
            y|Y )
                # Overwrite the file
                ln -sf "$source_path" "$destination_path"
                echo "Symlink ${destination_path} created."
                ;;
            a|A )
                # Say yes to all
                export YES_TO_ALL="true"
                ln -sf "$source_path" "$destination_path"
                echo "Symlink ${destination_path} created."
                ;;
            * )
                # Do not overwrite the file
                echo "Skipping ${destination_path}."
                ;;
        esac
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

sudo apt-get install -y fonts-powerline

# Install powerlevel10k
if ! test -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"; then
    echo "Install powerlevel10k theme for zsh"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo "powerlevel10k already installed"
fi

# Use Zsh to source the .zshrc file
zsh -c "source ${HOME}/.zshrc"