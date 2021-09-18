#!/bin/bash

# Generate an x86_64 AppImage
# The real converter should be installed previously on the system
# This is just the GUI. The real work is done by commands available on the system.

# cd to the directory this script is located in
cd "$(dirname "$(readlink -f "${0}")")"

echo "Remove old AppDir"
rm -rf AppDir

echo "Create new AppDir"
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/lib

echo "Make scripts executable and copy them"
chmod 755 ../../file-converter
cp -a ../../file-converter AppDir/usr/bin/
chmod 755 ../../file-converter-script.sh
cp -a ../../file-converter-script.sh AppDir/usr/bin/

echo "Copy icon"
cp -a ./file-converter.png AppDir/
cp -a ./file-converter.png AppDir/usr/share/icons/hicolor/256x256/apps/

echo "Make executable and copy .desktop file"
chmod 755 file-converter.desktop
cp -a ./file-converter.desktop AppDir/
cp -a ./file-converter.desktop AppDir/usr/share/applications/

# AppRun was downloaded from:
# https://github.com/AppImage/AppImageKit/releases/download/13/AppRun-x86_64
# MD5SUM: 91b81afc501f78761adbf3bab49b0590
# SHA256: fd0e2c14a135e7741ef82649558150f141a04c280ed77a5c6f9ec733627e520e
echo "Make executable and copy AppRun"
chmod 755 AppRun-x86_64
cp -a ./AppRun-x86_64 AppDir/AppRun

echo "Extract yad deb into AppDir"
dpkg-deb -xv ./yad_0.40.0-1_amd64.deb AppDir

# =====================================================================================================
# yad deb details:
# ----------------
# From: https://packages.debian.org/buster/amd64/yad/download
# Exact mirror and exact filename: http://ftp.debian.org/debian/pool/main/y/yad/yad_0.40.0-1_amd64.deb
# More information on yad_0.40.0-1_i386.deb:
# Exact Size :      172704 Byte (168.7 kByte)
# MD5 checksum :    7f5949ef8a0293a2a4d8022867556dab
# SHA256 checksum : 3a562d014a422e4975013635fd86d8958b8f448a5323674603b976aa9220ac4a
# =====================================================================================================

echo ""
echo "Generate AppImage using appimagetool"
echo ""

# appimagetool was downloaded from :
# https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage
# MD5SUM: 8897f478bb7b701fcd107503a08f62c4
# SHA256: df3baf5ca5facbecfc2f3fa6713c29ab9cefa8fd8c1eac5d283b79cab33e4acb

ARCH=x86_64 ./appimagetool-x86_64.AppImage AppDir

exit 0
