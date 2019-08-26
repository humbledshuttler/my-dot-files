#!/bin/sh


set -e

cp -r dotoh-my-zsh ${HOME}/.oh-my-zsh
cp ./dotzshrc ${HOME}/.zshrc

source ${HOME}/.zshrc
