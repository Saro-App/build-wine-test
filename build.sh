#!/bin/sh

# Copyright (C) 2025 Ethan Uppal and Josh Chan
#
# This file is part of build-wine-test.
# build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.

ls -a

softwareupdate --install-rosetta --agree-to-license

# Install homebrew for both regular and rosetta
NONINTERACTIVE=1
if ! [ -f /opt/homebrew/bin/brew ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
    || { echo "Failed to install arm64 homebrew"; exit 1; };
    echo >> ~/.zprofile;
    echo eval '"$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile;
    eval "$(/opt/homebrew/bin/brew shellenv)";
fi;
if ! [ -f /usr/local/bin/brew ]; then
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
    || { echo "Failed to install x86_64 homebrew"; exit 1; };
    echo >> ~/.zprofile
    echo eval '"$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
fi;

/opt/homebrew/bin/brew install --formula bison mingw-w64 pkgconfig wget
arch -x86_64 /usr/local/bin/brew install --formula freetype gnutls molten-vk sdl2
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

URL="https://media.codeweavers.com/pub/crossover/source/crossover-sources-25.0.0.tar.gz"
TAR_FILE="crossover-sources-25.0.0.tar.gz"
EXPECTED_SHA256="b0f3c1263bb1d7bfb8afa63493550be832ca55cd5f3d0bd2c9077991638d4e44"

if [ ! -d "sources/wine" ]; then
  echo "Downloading $TAR_FILE..."
  wget -q "$URL" -O "$TAR_FILE" || { echo "Failed to download $TAR_FILE"; exit 1; }

  echo "Verifying checksum..."
  ACTUAL_SHA256=$(sha256sum "$TAR_FILE" | awk '{ print $1 }')
  if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
      echo "Checksum verification failed! Expected: $EXPECTED_SHA256, Got: $ACTUAL_SHA256"
      exit 1
  else
      echo "Checksum verified successfully."
  fi

  echo "Extracting $TAR_FILE..."
  tar -xzf "$TAR_FILE" || { echo "Failed to extract $TAR_FILE"; exit 1; }
else
  echo "Sources directory exists, skipping download and extraction."
fi

cd sources/wine || { echo "Failed to enter wine directory"; exit 1; }

echo "Downloading distversion.h patch..."
wget -q https://raw.githubusercontent.com/winedbg/build-wine-test/refs/heads/main/distversion.h -O programs/winedbg/distversion.h  || { echo "Failed to download distversion.h patch"; }

echo "Running configure..."
./configure \
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
    --without-udev \
    --with-unwind \
    --without-usb \
    --without-v4l2 \
    --with-vulkan \
    --without-wayland \
    --without-x \
    CFLAGS="$(arch -x86_64 /usr/local/bin/pkg-config gnutls freetype2 -cflags)" \
    LDFLAGS="$(arch -x86_64 /usr/local/bin/pkg-config gnutls freetype2 --libs)" \
    || { echo "Configure failed"; exit 1; }
# Note ffmpeg, libinotify, gstreamer removed

echo "Running make..."
make -j$(sysctl -n hw.logicalcpu) || { echo "Make failed"; exit 1; }

echo "Build completed successfully.p"
