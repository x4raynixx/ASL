#!/data/data/com.termux/files/usr/bin/bash

pkg update -y
pkg install -y proot-distro termux-api termux-tools

mkdir -p ~/asl

cat > ~/asl/freeze_android.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
termux-volume music 0
termux-notification-remove all
settings put global auto_sync 0
settings put global window_animation_scale 0
settings put global transition_animation_scale 0
settings put global animator_duration_scale 0
for pkg in com.facebook.katana com.whatsapp com.instagram.android; do
    am force-stop \$pkg 2>/dev/null
done
pm trim-caches 100M
exit 0
EOF

chmod +x ~/asl/freeze_android.sh

cat > ~/asl/unfreeze_android.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
settings put global auto_sync 1
settings put global window_animation_scale 1
settings put global transition_animation_scale 1
settings put global animator_duration_scale 1
exit 0
EOF

chmod +x ~/asl/unfreeze_android.sh

cat > ~/asl/dual.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

if [[ "$1" == "debian" && "$2" == "reset" ]]; then
    echo "${YELLOW}Are you sure you want to RESET Debian? All data will be lost!${RESET}"
    read -p "Type YES to confirm: " confirm
    if [[ "$confirm" == "YES" ]]; then
        echo "${CYAN}[*] Resetting Debian...${RESET}"
        proot-distro remove debian
        echo "${CYAN}[*] Reinstalling Debian...${RESET}"
        proot-distro install debian > /dev/null 2>&1
        echo "${GREEN}[✓] Debian reset complete.${RESET}"
    else
        echo "${YELLOW}Aborted.${RESET}"
    fi
    exit 0
fi

echo "${CYAN}Select system:${RESET}"
select os in "Android" "Debian"; do
    case $os in
        "Debian")
            bash ~/asl/freeze_android.sh
            clear
            echo "[    0.0001] Booting Debian aarch64"
            sleep 0.3
            echo "[    0.0143] Initializing memory subsystem..."
            sleep 0.3
            echo "[    0.4302] Mounting root filesystem..."
            sleep 0.4
            echo "[    0.6420] Starting user session..."
            sleep 1
            proot-distro login debian
            ;;
        "Android")
            bash ~/asl/unfreeze_android.sh
            echo "${GREEN}Returned to Android.${RESET}"
            ;;
    esac
    break
done
EOF

chmod +x ~/asl/dual.sh

cat > ~/asl/uninstall.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
echo "This will uninstall ASL and Debian."
read -p "Are you sure? (yes to confirm): " answer
if [[ "\$answer" == "yes" ]]; then
    proot-distro remove debian
    rm -rf ~/asl
    sed -i '/alias dual=/d' ~/.bashrc
    echo "[✓] Uninstalled."
else
    echo "Aborted."
fi
EOF

chmod +x ~/asl/uninstall.sh

echo "fullscreen = true" >> ~/.termux/termux.properties
termux-reload-settings

if ! proot-distro list | grep -q '^debian'; then
    echo "[*] Installing Debian..."
    proot-distro install debian > /dev/null 2>&1
    echo "[✓] Debian installed."
else
    echo "[✓] Debian already installed."
fi

echo 'alias dual="bash ~/asl/dual.sh"' >> ~/.bashrc
source ~/.bashrc

echo "[✓] ASL setup complete. Use: dual"
