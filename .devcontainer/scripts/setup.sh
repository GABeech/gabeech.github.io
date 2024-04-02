#!/bin/bash
CASCADIA_VERSION="2102.25"
if [[ ! -d cascadia ]]
then
    mkdir cascadia
fi
if [[ ! -d ~/.fonts ]]
then
    mkdir ~/.fonts
fi
if [[ ! -f "cascadia/CascadiaCode-$CASCADIA_VERSION.zip" ]]
then
    cd cascadia
    wget "https://github.com/microsoft/cascadia-code/releases/download/v2102.25/CascadiaCode-$CASCADIA_VERSION.zip"
    unzip "CascadiaCode-$CASCADIA_VERSION.zip"
    cp ttf/*.ttf ~/.fonts/
fi

gem install jekyll bundler
bundle install
