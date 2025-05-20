#!/data/data/com.termux/files/usr/bin/bash

pkg update -y > /dev/null
pkg install -y proot-distro termux-api termux-tools > /dev/null

mkdir -p ~/asl

# freeze_android.sh
cat > ~/asl/freeze_android.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
tput civis
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
tput cnorm
exit 0
EOF
chmod +x ~/asl/freeze_android.sh

# unfreeze_android.sh
cat > ~/asl/unfreeze_android.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
tput civis
settings put global auto_sync 1
settings put global window_animation_scale 1
settings put global transition_animation_scale 1
settings put global animator_duration_scale 1
tput cnorm
exit 0
EOF
chmod +x ~/asl/unfreeze_android.sh

# dual.sh
cat > ~/asl/dual.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

if [[ "$PREFIX" != "/data/data/com.termux/files/usr" ]]; then
  echo "Use this only in Termux."
  exit 1
fi

G=$(tput setaf 2)
Y=$(tput setaf 3)
C=$(tput setaf 6)
R=$(tput sgr0)

freeze_android() {
  tput civis
  termux-volume music 0
  termux-notification-remove all
  settings put global auto_sync 0
  settings put global window_animation_scale 0
  settings put global transition_animation_scale 0
  settings put global animator_duration_scale 0
  for pkg in com.facebook.katana com.whatsapp com.instagram.android; do
    am force-stop "$pkg" 2>/dev/null
  done
  pm trim-caches 100M
  tput cnorm
}

unfreeze_android() {
  tput civis
  settings put global auto_sync 1
  settings put global window_animation_scale 1
  settings put global transition_animation_scale 1
  settings put global animator_duration_scale 1
  tput cnorm
}

start_debian() {
  freeze_android
  clear
  echo "[    0.0001] Booting Debian aarch64"
  sleep 0.3
  echo "[    0.0143] Initializing memory..."
  sleep 0.3
  echo "[    0.4302] Mounting rootfs..."
  sleep 0.4
  echo "[    0.6420] Starting session..."
  sleep 1
  proot-distro login debian --shared-tmp
  unfreeze_android
  echo "${G}Returned to Android.${R}"
}

reset_debian() {
  echo "${Y}Reset Debian? All data will be lost.${R}"
  read -p "Type YES to confirm: " c
  if [[ "$c" == "YES" ]]; then
    echo "${C}[*] Resetting...${R}"
    proot-distro remove debian > /dev/null 2>&1
    echo "${C}[*] Reinstalling...${R}"
    proot-distro install debian > /dev/null 2>&1
    echo "${G}[✓] Reset done.${R}"
  else
    echo "${Y}Aborted.${R}"
  fi
}

echo "${C}Select system:${R}"
select os in "Android" "Debian"; do
  case $os in
    "Debian")
      if [[ "$1" == "debian" && "$2" == "reset" ]]; then
        reset_debian
      else
        start_debian
      fi
      ;;
    "Android")
      unfreeze_android
      echo "${G}Returned to Android.${R}"
      ;;
    *)
      echo "${Y}Invalid choice.${R}"
      ;;
  esac
  break
done
EOF
chmod +x ~/asl/dual.sh

# uninstall.sh
cat > ~/asl/uninstall.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
echo "Uninstall ASL and Debian."
read -p "yes to confirm: " a
if [[ "\$a" == "yes" ]]; then
    proot-distro remove debian
    rm -rf ~/asl
    rm -f \$PREFIX/bin/dual
    sed -i '/alias dual=/d' ~/.bashrc
    echo "[✓] Uninstalled."
else
    echo "Aborted."
fi
EOF
chmod +x ~/asl/uninstall.sh

# termux fullscreen
echo "fullscreen = true" >> ~/.termux/termux.properties
termux-reload-settings

# install debian if needed
if ! proot-distro list | grep -q '^debian'; then
    echo "[*] Installing Debian..."
    proot-distro install debian > /dev/null 2>&1
    echo "[✓] Installed."
else
    echo "[✓] Debian exists."
fi

# deploy dual
cp ~/asl/dual.sh \$PREFIX/bin/dual
chmod +x \$PREFIX/bin/dual
sed -i '/alias dual=/d' ~/.bashrc

echo "[✓] Setup complete. Run: dual"
