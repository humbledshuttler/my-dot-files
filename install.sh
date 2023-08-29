#!/bin/bash

c_dir=`basename "$PWD"`
if [ "$c_dir" != "my-dot-files" ]; then
	echo "run install.sh from root directory"
	exit 1
fi

APT=/usr/bin/apt
DNF=/usr/bin/dnf

# install zsh
if [ -f "$APT" ]; then
    echo "found apt. Installing zsh"
    sudo apt install -y zsh
fi

if [ -f "$DNF" ]; then
    echo "Found dnf. Installing dnf"
    sudo dnf install -y zsh
fi

# Check if tmux is already installed
if ! command -v tmux >/dev/null; then

  # Install tmux
  sudo apt update
  sudo apt install tmux

  # Tell the user that tmux has been installed
  echo "tmux has been installed."
fi

# Check if ctags is already installed
if ! command -v ctags >/dev/null; then

  # Install ctags
  sudo apt update
  sudo apt install ctags

  # Tell the user that ctags has been installed
  echo "ctags has been installed."
fi

working_dir=${PWD}

# Define the create_symlink function
function create_symlink() {
  # Get the source and destination paths
  source_path=$1
  destination_path=$2

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
create_symlink ${working_dir}/dotp10k.zsh ${HOME}/.p10k.sh

# install powerlevel10k
if ! test -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"; then

  echo "install powerlevel10k theme for zsh"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
  echo "powerlevel10k already installed"
fi



source ${HOME}/.zshrc
