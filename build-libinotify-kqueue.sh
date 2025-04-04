#!/bin/sh

CURRENT_DIR="$(pwd)"
BUILD_DIR="dependencies"

set -e

cd $BUILD_DIR

echo "Cloning libinotify-kqueue..."
git clone --branch 20211018 --depth 1 https://github.com/libinotify-kqueue/libinotify-kqueue.git
cd libinotify-kqueue

echo "Installing build dependencies (via brew)..."
brew install autoconf automake gcc libtool

echo "Running autoreconf..."
autoreconf -fiv

echo "Configuring libinotify-kqueue..."
./configure

echo "Building libinotify-kqueue..."
make

echo "Installing libinotify-kqueue to /usr/local..."
sudo make install

cd "$CURRENT_DIR"
