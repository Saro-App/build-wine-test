## My attempt to build wine

### 1st attempt

- `brew install autoconf automake libtool`
- add programs/winedbg/distversion.h from https://github.com/theiodes/winecx-builder/blob/main/distversion.h
- `./configure`
  Build fails will check again later
  Maybe not because this was with aarch64 as the target

### 2nd attempt

- `brew install autoconf automake libtool`
- add programs/winedbg/distversion.h from https://github.com/theiodes/winecx-builder/blob/main/distversion.h
- Run build script with extra args
```bash
./configure --build=x86_64-apple-darwin --enable-archs=i386,x86_64 \
   --disable-tests \
   --with-gnutls --without-gssapi --with-gstreamer --with-inotify --with-gettext --with-freetype --with-ffmpeg --with-cups --with-coreaudio \
   --with-mingw --with-opencl --with-opengl --without-oss --with-pcap --with-pcsclite --with-pthread --with-sdl --with-unwind --with-vulkan \
   --without-v4l2 --without-wayland --without-x --without-usb --without-udev --without-netapi --without-sane --without-pulse --without-krb5 \
   --without-gettextpo --without-dbus --without-capi --without-alsa --without-gphoto
```
Configure fails, removing vulkan, gstreamer and inotify causes a redeclaration error

### 3rd attempt

- Same as second attempt
- makedep.c:

```c
#undef __arm__
#undef __arm64__
```
Fails because it requires this to be put in literally every file, and wine still doesn't completely know what its building for

### 4th attempt

- Set environment vars:
```bash
export MACOSX_DEPLOYMENT_TARGET=11.3
export CC="arch -x86_64 cc"
export CXX="arch -x86_64 c++"
export CPP="arch -x86_64 cpp"
```
- Same as second attempt
- Says more libraries are missing
