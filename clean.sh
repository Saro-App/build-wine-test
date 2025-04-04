#!/bin/sh

SOURCES="sources"
DEPENDENCIES="dependencies"
TAR="crossover-sources-25.0.0.tar.gz"

echo "Removing the sources tar..."
rm -f $TAR

echo "Removing the sources directory..."
rm -rf $SOURCES

echo "Removing the dependencies directory..."
rm -rf $DEPENDENCIES
