#!/bin/bash

set -e

# cd to the directory this script is located in
cd "$(dirname "$(readlink -f "${0}")")"

rm -f file-converter*.deb

echo "Remove old files"
rm -rf file-converter/usr/

echo "Create directories"
mkdir -p file-converter/usr/bin
mkdir -p file-converter/usr/share/icons/hicolor/256x256/apps
mkdir -p file-converter/usr/share/applications

echo "Make scripts executable and copy them"
chmod 755 ../../file-converter
cp -a ../../file-converter file-converter/usr/bin/
chmod 755 ../../file-converter-script.sh
cp -a ../../file-converter-script.sh file-converter/usr/bin/

echo "Copy icon"
cp -a ../../file-converter.png file-converter/usr/share/icons/hicolor/256x256/apps/

echo "Make executable and copy .desktop file"
chmod 755 ../../file-converter.desktop
cp -a ../../file-converter.desktop file-converter/usr/share/applications/

dpkg-deb --build file-converter

exit 0
