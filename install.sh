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

echo "Select system:"
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
            echo "Returned to Android."
            ;;
    esac
    break
done
EOF

chmod +x ~/asl/dual.sh

echo "fullscreen = true" >> ~/.termux/termux.properties
termux-reload-settings

proot-distro install debian

echo 'alias dual="bash ~/asl/dual.sh"' >> ~/.bashrc
source ~/.bashrc
