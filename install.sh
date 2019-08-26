#!/bin/sh


set -e

cp -r dotoh-my-zsh ${HOME}/.oh-my-zsh
cp ./dotzshrc ${HOME}/.zshrc

cp ./dotvimrc ${HOME}/.vimrc
cp ./dotvim ${HOME}/.vim

cp ./dottmux.conf ${HOME}/.tmux.conf
cp ./dottmux-plugins ${HOME}/.tmux-plugins

source ${HOME}/.zshrc
