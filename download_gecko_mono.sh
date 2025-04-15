#!/bin/sh

# Copyright (C) 2025 Ethan Uppal and Josh Chan
#
# This file is part of build-wine-test.
# build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.

echo "Installing Gecko and Mono"
mkdir -p "$1/share/wine/gecko"
mkdir -p "$1/share/wine/mono"

GECKO_VERSION="2.47.4"
MONO_VERSION="10.0.0"

curl -o "$1/share/wine/gecko/wine-gecko-${GECKO_VERSION}-x86_64.msi" \
    https://dl.winehq.org/wine/wine-gecko/${GECKO_VERSION}/wine-gecko-${GECKO_VERSION}-x86_64.msi \
    || { echo "Failed to install Gecko"; exit 1; }

curl -o "$1/share/wine/mono/wine-mono-${MONO_VERSION}-x86.msi" \
    https://dl.winehq.org/wine/wine-mono/${MONO_VERSION}/wine-mono-${MONO_VERSION}-x86.msi \
    || { echo "Failed to install Mono"; exit 1; }
