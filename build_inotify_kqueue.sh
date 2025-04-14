#!/bin/sh

# Copyright (C) 2025 Ethan Uppal and Josh Chan
#
# This file is part of build-wine-test.
# build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.

# This script is based off of
# - https://github.com/NixOS/nixpkgs/blob/1750f3c1c89488e2ffdd47cab9d05454dddfb734/pkgs/by-name/li/libinotify-kqueue/package.nix#L44
# - https://github.com/Gcenx/macports-wine/blob/main/devel/libinotify/Portfile

/bin/sh init.sh

brew install autoconf automake libtool

export CC="arch -x86_64 cc"
export CXX="arch -x86_64 c++"
export CPP="arch -x86_64 cpp"

mkdir -p build-dependencies/libinotify-kqueue || { echo "Failed to create build directory"; exit 1; }
cd build-dependencies/libinotify-kqueue || { echo "Failed to enter build directory"; exit 1; }

# Uh it seems this file is needded
cp ../../libinotify-kqueue/libinotify.sym .

echo "libinotify: Running autoreconf in source directory..."
(cd ../../libinotify-kqueue && autoreconf -fvi) || { echo "Autoreconf failed"; exit 1; }

echo "libinotify: Running configure..."
../../libinotify-kqueue/configure \
    --prefix=/usr/local \
    || { echo "Configure failed"; exit 1; }

echo "libinotify: Running make..."
make -j$(sysctl -n hw.logicalcpu) || { echo "Make failed"; exit 1; }

if [ "$TEST" = "1" ]; then
    make test -j$(sysctl -n hw.logicalcpu) 2>&1 | tee test.log
    grep -qE "Failed: [1-9][0-9]*" test.log && { echo "Tests failed"; exit 1; }
fi

if [ "$INSTALL" = "1" ]; then
    # INSTALL is treated as a binary override so we re-override
    make install -j$(sysctl -n hw.logicalcpu) INSTALL="/usr/bin/install"
fi
