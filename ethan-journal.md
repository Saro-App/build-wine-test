Error: `configure: error: libgnutls 64-bit development files not found,  no schannel support.`

- https://forums.gentoo.org/viewtopic-p-8818894.html?sid=77ad69e49cdb837207d172ee5ecd044d
- https://forum.winehq.org/viewtopic.php?t=33196

`export PKG_CONFIG_PATH="/usr/local/Cellar/pkgconf/2.4.3/lib/pkgconfig/"`

Passing `--enable-win64` to configure does not help

Gonna try just passing CFLAGS/LDFLAGS with the pkgconfig directly
