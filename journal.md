## My attempt to build wine

### First attempt

- brew install autoconf automake libtool
- add programs/winedbg/distversion.h from https://github.com/theiodes/winecx-builder/blob/main/distversion.h
- ./configure
  Build fails will check again later
  Maybe not because this was with aarch64 as the target

### Second attempt

- brew install autoconf automake libtool
- add programs/winedbg/distversion.h from https://github.com/theiodes/winecx-builder/blob/main/distversion.h
- ./configure --build=x86_64-apple-darwin \
   --enable-archs=i386,x86_64 \
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
   --without-x
  Configure fails, removing vulkan, gstreamer and inotify causes a redeclaration error
