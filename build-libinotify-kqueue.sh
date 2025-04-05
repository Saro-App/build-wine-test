#!/bin/sh

# Copyright (C) 2025 Ethan Uppal and @Melonchanism
# 
# This file is part of build-wine-test.
# build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.

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
