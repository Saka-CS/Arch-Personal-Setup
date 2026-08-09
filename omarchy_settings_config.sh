#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Generic changes
## Change The Caps Lock Key to esc
sudo tee /etc/udev/hwdb.d/90-caps-to-esc.hwdb >/dev/null <<'EOF'
# Internal laptop keyboard (AT/PS2) — caps scancode 0x3a
evdev:atkbd:*
evdev:input:b0011v0001p0001*
    KEYBOARD_KEY_3a=esc

# USB keyboards (HID) — caps scancode 0x70039
evdev:input:b0003v*p*
    KEYBOARD_KEY_70039=esc
EOF
sudo systemd-hwdb update
sudo udevadm trigger --action=change --subsystem-match=input
systemd-hwdb query evdev:input:b0003v0001p0001   # verify the mapping loaded



# Omarchy specific changes
# Install required software for settings change
# sudo pacman --noconfirm -S python-pipx
# pipx install hyprshade==4.0.1
# hyprshade install


# Disable sleep and screensaver
omarchy toggle idle
omarchy toggle screensaver

cat > ~/.config/hypr/hypridle.conf << "EOF"
general {
    lock_cmd = omarchy-system-lock                         # lock screen and 1password
    before_sleep_cmd = OMARCHY_LOCK_ONLY=true omarchy-system-lock    # lock before suspend without scheduling display off.
    after_sleep_cmd = sleep 1 && omarchy-system-wake                 # delay for PAM readiness, then turn on display.
    inhibit_sleep = 3                                      # wait until screen is locked
}

# Start screensaver after 2.5 minutes
# listener {
#     timeout = 150
#     on-timeout = pidof hyprlock || omarchy-launch-screensaver
# }

# Lock system after 5 minutes (screensaver resets idle timer, so have to just do half + 2s margin)
# listener {
#     timeout = 152
#     on-timeout = omarchy-system-lock
#     on-resume = omarchy-system-wake
# }
EOF

FONT_CONF_DIR="$HOME/.config/fontconfig/conf.d/"
FONT_CONF_FILE="${FONT_CONF_DIR}99-arabic-fonts.conf"

mkdir -p "${FONT_CONF_DIR}"

if [ ! -f "${FONT_CONF_FILE}" ]; then
  echo "Applying Arabic font display configuration..."

  cat > "${FONT_CONF_FILE}" << "EOF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Readable Arabic: prefer Noto Sans Arabic before the Noto Kufi fallback -->
  <alias>
    <family>Liberation Sans</family>
    <accept>
      <family>Noto Sans Arabic</family>
      <family>Noto Kufi Arabic</family>
    </accept>
  </alias>
  <alias>
    <family>Liberation Serif</family>
    <accept>
      <family>Noto Sans Arabic</family>
      <family>Noto Naskh Arabic</family>
    </accept>
  </alias>
  <alias>
    <family>iA Writer Mono S</family>
    <accept>
      <family>Noto Sans Arabic</family>
    </accept>
  </alias>
</fontconfig>
EOF
  fc-cache -f

  if [[ ! "$(fc-match "sans-serif:charset=0627" -f "%{family}")" == *"Noto Sans Arabic"* ]]; then
    echo "The Font is not set correctly"
    echo "$(fc-match "sans-serif:charset=0627")"
  fi
  
  if [[ ! "$(fc-match "iA Writer Mono S:charset=0627" -f "%{family}")" == *"Noto Sans Arabic"* ]]; then
    echo "The Font is not set correctly"
    echo "$(fc-match "iA Writer Mono S:charset=0627")"
  fi
  
  if [[ ! "$(fc-match sans-serif -f "%{family}")" == *"Liberation Sans"* ]]; then
    echo "The Font is not set correctly"
    echo "$(fc-match sans-serif)"
  fi
  
  echo "Completed the Arabic display font configuration"
else
  echo "Arabic is already configured"
fi


### Add the Arabic Layout to Fcitx5
# Stop fcitx5
fcitx5-remote -e
for _ in $(seq 1 200); do pgrep -x fcitx5 >/dev/null || break; sleep 0.1; done

# then confirm change before editing
if ! pgrep -x fcitx5; then
# Edit ~/.config/fcitx5/profile to add the new profile
cat > ~/.config/fcitx5/profile << 'EOF'
[Groups/0]
# Group Name
Name=Default
# Layout
Default Layout=us
# Default Input Method
DefaultIM=keyboard-us

[Groups/0/Items/0]
# Name
Name=keyboard-us
# Layout
Layout=

[Groups/0/Items/1]
# Name
Name=keyboard-ara
# Layout
Layout=

[GroupOrder]
0=Default

EOF

  # Start fcitx5
  omarchy restart xcompose

  for _ in $(seq 1 200); do fcitx5-remote --check >/dev/null 2>&1 && break; sleep 0.1; done

  # Verify:
  echo "before: $(fcitx5-remote -n)"
  fcitx5-remote -s keyboard-ara
  echo "after: $(fcitx5-remote -n)"
else
  echo "Could not configure Arabic keyboard layout. fcitx5 is still running"
fi


# Add the swith to Arabic Shortcut
if ! grep -q "Switch language" ~/.config/hypr/bindings.conf; then
cat >> ~/.config/hypr/bindings.conf << 'EOF'
# Switch language (English/Arabic) via fcitx5
bindd = SUPER ALT, L, Switch language, exec, bash -c 'im=$(fcitx5-remote -n); [ "$im" = "keyboard-ara" ] && fcitx5-remote -s keyboard-us || fcitx5-remote -s keyboard-ara'

EOF

fi


# # region Add monochromatic red shaders to the system
# # Add the auto start config file
# cat > ~/.config/hypr/hyprshade.toml << "EOF"
# [[shades]]
# name = "red-channel"
# start_time = 19:00:00
# end_time = 06:00:00
# EOF
# 
# 
# # Add the keyboard shortcut to toggle red shaaders
# if ! grep -q "Toggle red-channel shader" ~/.config/hypr/bindings.conf; then
#   cat >> ~/.config/hypr/bindings.conf << 'EOF'
# # Toggle red-channel shader (luma to red)
# bindd = SUPER, R, Red shader toggle, exec, hyprshade toggle red-channel
# 
# EOF
# fi
# 
# 
# # Autostart scheduled shader
# if ! grep -q "Autostart hypershade" ~/.config/hypr/autostart.conf; then
# cat >> ~/.config/hypr/autostart.conf << 'EOF'
# # Autostart hypershade
# exec-once = hyprshade auto
# 
# EOF
# fi
# # endregion

