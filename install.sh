#!/bin/bash

c_dir=`basename "$PWD"`
if [ "$c_dir" != "my-dot-files" ]; then
	echo "run install.sh from root directory"
	exit 1
fi

set -e

sudo apt install -y zsh

working_dir=${PWD}

ln -sv ${working_dir}/dotoh-my-zsh ${HOME}/.oh-my-zsh
ln -sv ${working_dir}/dotzshrc ${HOME}/.zshrc

ln -sv ${working_dir}/dotvimrc ${HOME}/.vimrc
ln -sv ${working_dir}/dotvim ${HOME}/.vim

ln -sv ${working_dir}/dottmux.conf ${HOME}/.tmux.conf
ln -sv ${working_dir}/dottmux-plugins ${HOME}/.tmux-plugins

source ${HOME}/.zshrc
