#!/bin/bash
pip install --upgrade pip setuptools wheel
pip install requests beautifulsoup4 rich colorama termcolor
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
fi
echo "[+] تم إعداد المكتبات والأدوات بنجاح!"
