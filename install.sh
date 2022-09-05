#!/bin/bash

c_dir=`basename "$PWD"`
if [ "$c_dir" != "my-dot-files" ]; then
	echo "run install.sh from root directory"
	exit 1
fi

# install zsh
sudo apt install -y zsh

working_dir=${PWD}

ln -sv ${working_dir}/dotoh-my-zsh ${HOME}/.oh-my-zsh
ln -sv ${working_dir}/dotzshrc ${HOME}/.zshrc

ln -sv ${working_dir}/dotvimrc ${HOME}/.vimrc
ln -sv ${working_dir}/dotvim ${HOME}/.vim

ln -sv ${working_dir}/dottmux.conf ${HOME}/.tmux.conf
ln -sv ${working_dir}/dottmux-plugins ${HOME}/.tmux-plugins
ln -sv ${working_dir}/dotgitconfig ${HOME}/.gitconfig
ln -sv ${working_dir}/dotp10k.zsh ${HOME}/.p10k.sh

# install powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k


source ${HOME}/.zshrc
