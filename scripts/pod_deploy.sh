#!/usr/bin/env bash

source ~/.rvm/scripts/rvm
rvm use default
gem install cocoapods
pod trunk push
