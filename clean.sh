#!/bin/sh

SOURCES="sources"
TAR="crossover-sources-25.0.0.tar.gz"

echo "Removing the sources tar."
rm -f $TAR

echo "Removing the sources directory."
rm -rf $SOURCES
