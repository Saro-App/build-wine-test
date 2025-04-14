#!/bin/sh

# Copyright (C) 2025 Ethan Uppal and Josh Chan
#
# This file is part of build-wine-test.
# build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.
# Rosetta is known as "OAH" internally

if ! /usr/bin/pgrep -q oahd;
    then softwareupdate --install-rosetta --agree-to-license;
    else echo "Rosetta already installed"
fi

# Install homebrew for both regular and rosetta
NONINTERACTIVE=1
if ! [ -f /opt/homebrew/bin/brew ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
    || { echo "Failed to install arm64 homebrew"; exit 1; };
    echo >> ~/.zprofile;
    echo eval '"$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile;
    eval "$(/opt/homebrew/bin/brew shellenv)";
fi;
if ! [ -f /usr/local/bin/brew ]; then
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
    || { echo "Failed to install x86_64 homebrew"; exit 1; };
    echo >> ~/.zprofile
    echo eval '"$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
fi;
