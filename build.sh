#!/bin/sh

# Copyright (C) 2025 Ethan Uppal and Josh Chan
#
# This file is part of build-wine-test.
# build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.

if [ -z "$1" ]
    then { echo "error: Pass destination prefix absolute path as argument"; exit 1; }
fi

/bin/sh init.sh

/opt/homebrew/bin/brew install --formula bison mingw-w64 pkgconfig wget
arch -x86_64 /usr/local/bin/brew install --formula freetype gnutls molten-vk sdl2 gstreamer ffmpeg
export PATH="/opt/homebrew/opt/bison/bin:$PATH"

# mkdir -p ~/.pkg-config
# echo 'PKG_CONFIG_PATH="/usr/local/opt/gnutls/lib/pkgconfig:$PKG_CONFIG_PATH"' > ~/.pkg-config/env
# source ~/.pkg-config/env
# arch -x86_64 pkg-config --list-all | grep gnutls || { echo "gnutls not found in pkg-config"; exit 1; }

export CC="arch -x86_64 cc"
export CXX="arch -x86_64 c++"
export CPP="arch -x86_64 cpp"
export CFLAGS="-m64"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
# export PKG_CONFIG_PATH="/usr/local/Cellar/pkgconf/2.4.3/lib/pkgconfig/"

mkdir -p build || { echo "Failed to create build directory"; exit 1; }
cd build || { echo "Failed to enter build directory"; exit 1; }

echo "Running configure..."
../wine/configure \
    --prefix="$1" \
    --host=x86_64-darwin \
    --build=x86_64-darwin \
    --enable-archs=i386,x86_64 \
    --enable-win64 \
    --disable-tests \
    --without-alsa \
    --without-capi \
    --with-coreaudio \
    --with-cups \
    --without-dbus \
    --with-freetype \
    --with-gettext \
    --without-gettextpo \
    --without-gphoto \
    --with-gnutls \
    --without-gssapi \
    --without-krb5 \
    --with-mingw \
    --without-netapi \
    --with-opencl \
    --with-opengl \
    --without-oss \
    --with-pcap \
    --with-pcsclite \
    --with-pthread \
    --without-pulse \
    --without-sane \
    --with-sdl \
    --with-gstreamer \
    --without-udev \
    --with-unwind \
    --without-usb \
    --without-v4l2 \
    --with-vulkan \
    --without-wayland \
    --without-x \
    --with-inotify \
    --with-ffmpeg \
    CFLAGS="$(arch -x86_64 /usr/local/bin/pkg-config gnutls freetype2 --cflags)" \
    LDFLAGS="$(arch -x86_64 /usr/local/bin/pkg-config gnutls freetype2 --libs)" \
    || { echo "Configure failed"; exit 1; }

echo "Running make..."
make -j$(sysctl -n hw.logicalcpu) || { echo "Make failed"; exit 1; }

echo "Build completed successfully. ez"

# We do this first because otherwise wine will make a popup saying "hey you don't have gecko/mono"
# Actually I have no clue???
/bin/sh ../download_gecko_mono.sh "$1"

make install -j$(sysctl -n hw.logicalcpu) || { echo "Installation failed"; exit 1; }
