#!/usr/bin/env bash

source ~/.rvm/scripts/rvm
rvm use default
gem install cocoapods --pre

cd "$TRAVIS_BUILD_DIR"

echo "Now in directory $TRAVIS_BUILD_DIR"

pod trunk push
