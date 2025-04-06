# build-wine-test

1. Run `/bin/sh silicon-bootstrap.sh <path to desired wine prefix>`.
    If you don't want to clean, do `/bin/sh build.sh <path to desired wine prefix>`.

2. From `sources/wine`, run `make install -j$(sysctl -n hw.logicalcpu)` to setup the prefix.


## Important

`silicon-bootstrap.sh` should be used for bootstapping. For incremental rebuilds, just run `build.sh`.

## Wait!!!

Wait, you actually have to apply some patches:
- `dlls_win32u_freetype_c.patch` to dlls/win32u/freetype.c
- Paste `dll_ntdll_unix_process_c` to replace dlls/ntdll/unix/process.c

TODO automate this

## License

Copyright (C) 2025 Ethan Uppal and Josh Chan

This file is part of build-wine-test.
build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.
