Error: `configure: error: libgnutls 64-bit development files not found,  no schannel support.`

- https://forums.gentoo.org/viewtopic-p-8818894.html?sid=77ad69e49cdb837207d172ee5ecd044d
- https://forum.winehq.org/viewtopic.php?t=33196

`export PKG_CONFIG_PATH="/usr/local/Cellar/pkgconf/2.4.3/lib/pkgconfig/"`

Passing `--enable-win64` to configure does not help

Gonna try just passing CFLAGS/LDFLAGS with the pkgconfig directly

It's still getting the arm files???
```
configure:17039: checking for gnutls_cipher_init
configure:17039: arch -x86_64 cc -m64 -o conftest   -I/opt/homebrew/Cellar/gnutls/3.8.4/include -I/opt/homebrew/Cellar/nettle/3.10.1/include -I/opt/homebrew/Cellar/libtasn1/4.20.0/include -I/opt/homebrew/Cellar/libidn2/2.3.7/include -I/opt/homebrew/Cellar/p11-kit/0.25.5/include/p11-kit-1  conftest.c  -L/opt/homebrew/Cellar/gnutls/3.8.4/lib -lgnutls >&5
ld: warning: ignoring file '/opt/homebrew/Cellar/gnutls/3.8.4/lib/libgnutls.30.dylib': found architecture 'arm64', required architecture 'x86_64'
Undefined symbols for architecture x86_64:
  "_gnutls_cipher_init", referenced from:
      _main in conftest-794f47.o
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
configure:17039: $? = 1
```

Using `export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"` got it past the configure stage. It's in the make stage.
I have no hope it'll work.

Also gonna try `-j$(sysctl -n hw.logicalcpu)` if it makes it faster

Got it working, it even built in CI.
Next need to actually upload more artifacts, build for win64, figure out why stuff like --with-pcap works when we dont install libpcap

Also need to get libinotify and gstreamer working

Also working on gecko and mono


next we need to work on:
- gecko/mono -- I added these but idk if they work
- libinotify (gcenx's portfile for inotify)
- gstreamer (gcenx's portfile for wine-devel)
- all the graphics translations stuff
