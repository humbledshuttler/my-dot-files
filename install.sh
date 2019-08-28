#!/bin/bash

set -e

sudo apt install -y zsh

cp -r dotoh-my-zsh ${HOME}/.oh-my-zsh
cp ./dotzshrc ${HOME}/.zshrc

cp ./dotvimrc ${HOME}/.vimrc
cp -r ./dotvim ${HOME}/.vim

cp ./dottmux.conf ${HOME}/.tmux.conf
cp -r ./dottmux-plugins ${HOME}/.tmux-plugins

source ${HOME}/.zshrc
