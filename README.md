# build-wine-test

Remember to grab submodules after cloning:

```sh
git submodule update --init --recursive
```

## Building

### Dependencies

```sh
INSTALL=1 /bin/sh build_inotify_kqueue.sh
```

You can prefix any of these build scripts with a `TEST=1` environment variable to run tests if applicable.

### Wine

It's as simple as running:
```sh
/bin/sh build.sh <absolute path to desired wine prefix>
```
Remember that you should `rm -rf <absolute path to your prefix>` before rebuilding it.

### Cleanup

```sh
/bin/sh clean.sh
```

## Testing

To test, `cd` into your prefix directory and run:

```sh
WINEPREFIX=<absolute path to your prefix> DYLD_FALLBACK_LIBRARY_PATH="/usr/local/lib/" ./bin/wine winec
```
