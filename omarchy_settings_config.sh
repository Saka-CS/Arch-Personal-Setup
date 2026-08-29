#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'


# Omarchy specific changes
# Install required software for settings change
# sudo pacman --noconfirm -S python-pipx
# pipx install hyprshade==4.0.1
# hyprshade install

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

