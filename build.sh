#!/bin/sh

/bin/sh clean.sh

export CC="arch -x86_64 cc"
export CXX="arch -x86_64 c++"
export CPP="arch -x86_64 cpp"
export CFLAGS="-m64"

echo "Installing dependencies..."

mkdir -p dependencies

brew install bison
export PATH="/opt/homebrew/opt/bison/bin:$PATH"

brew install mingw-w64 gettext

/bin/sh build-libinotify-kqueue.sh || { echo "Failed to install 'libinotify-kqueue'"; exit 1; }

URL="https://media.codeweavers.com/pub/crossover/source/crossover-sources-25.0.0.tar.gz"
TAR_FILE="crossover-sources-25.0.0.tar.gz"
EXPECTED_SHA256="b0f3c1263bb1d7bfb8afa63493550be832ca55cd5f3d0bd2c9077991638d4e44"

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

cd sources || { echo "Failed to enter directory 'crossover-sources-25.0.0'"; exit 1; }
cd wine || { echo "Failed to enter 'wine' directory"; exit 1; }

echo "Running configure..."
./configure \
    --host=x86_64-darwin \
    --build=x86_64-darwin \
    --enable-archs=x86_64 \
    --disable-tests \
    --without-alsa \
    --without-capi \
    --with-coreaudio \
    --with-cups \
    --without-dbus \
    --with-ffmpeg \
    --with-freetype \
    --with-gettext \
    --without-gettextpo \
    --without-gphoto \
    --with-gnutls \
    --without-gssapi \
    --with-gstreamer \
    --with-inotify \
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
    || { echo "Configure failed"; exit 1; }

echo "Running make..."
make || { echo "Make failed"; exit 1; }

echo "Build completed successfully."
