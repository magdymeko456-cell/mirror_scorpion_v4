#!/bin/bash
termux-change-repo
pkg update -y && pkg upgrade -y
termux-setup-storage
pkg install -y python git curl wget proot clang make cmake libjpeg-turbo libpng openssl
apt-get clean
pkg clean
echo "[+] تم الانتهاء من إصلاح بيئة ترمكس بنجاح!"
