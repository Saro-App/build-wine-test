# build-wine-test

## Building

It's as simple as cloning and running:
```sh
/bin/sh build.sh <absolute path to desired wine prefix>
```
Remember that you should `rm -rf <your prefix>` before rebuilding it.

## Testing

To test, `cd` into your prefix directory and run:

```sh
WINEPREFIX=/Users/ethan/gh/build-wine-test/testprefix/ DYLD_FALLBACK_LIBRARY_PATH="/usr/local/lib/" ./bin/wine winec
```
