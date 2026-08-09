#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'


options=("General" "Gaming" "Video production" "Artist" "Professional" "Dev")

echo "Select the device purpose"

for i in "${!options[@]}"; do
  echo "$((i+1)). ${options[$i]}"
done

echo ""

IFS=' ' read -p "Enter your choices seperated by space: " -a choices

selected_option=()
for choice in "${choices[@]}"; do
  if [[ "$choice" =~ ^[0-9]+$ ]]; then
    index=$((choice-1))
    selected_option+=("${options[$index]}")
  else
     echo "Warning: Invalid option '$choice' ignored."
  fi
done

echo -e "\nStarting to dowonload selection"

if [[ "${#selected_option[@]}" -eq 0 ]]; then
  echo "You didn't select any valid option"
  exit 1
fi

for opt in "${selected_option[@]}"; do
  case "$opt" in
    "General")

      ## Omarchy General
      sudo pacman --noconfirm -Syu
      
      curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh
      
      sudo pacman --noconfirm -S noto-fonts noto-fonts-extra
      sudo pacman --noconfirm -S anki
      sudo pacman --noconfirm -S kdeconnect
      sudo pacman --noconfirm -S flatpak
     
      yay -S --noconfirm --needed visual-studio-code-bin
      yay -S --noconfirm --needed pureref
      yay -S --noconfirm --needed preload
      
      sudo pacman --noconfirm -S syncthing
      systemctl --user enable --now syncthing.service
      sudo ufw allow 1714:1764/udp
      sudo ufw allow 1714:1764/tcp
      sudo ufw reload
      
      curl -fsSL https://ollama.com/install.sh | sh
      curl -fsSL https://antigravity.google/cli/install.sh | bash

      flatpak remote-add --if-not-exists flathub https://flathub.org
      flatpak install flathub org.telegram.desktop -y
      flatpak install flathub com.orcaslicer.OrcaSlicer -y
      flatpak install flathub io.github.flattool.Warehouse -y
      flatpak install flathub net.mkiol.SpeechNote -y
      flatpak install flathub com.discordapp.Discord -y
      flatpak install flathub com.github.tchx84.Flatseal -y
      flatpak install flathub com.rafaelmardojai.Blanket -y
      flatpak install flathub com.super_productivity.SuperProductivity -y
      flatpak install flathub org.kde.krita -y
      flatpak install flathub org.freecad.FreeCAD -y
    ;;
    "Gaming")
      ## Omarchy Gaming
      flatpak install flathub com.stremio.Stremio -y
      flatpak install flathub com.heroicgameslauncher.hgl -y
      flatpak install flathub org.prismlauncher.PrismLauncher -y
      flatpak install flathub org.nickvision.tubeconverter -y
      flatpak install flathub org.libretro.RetroArch -y
      flatpak install flathub com.pokemmo.PokeMMO -y
      sudo pacman -S steam
      # lib32-vulkan-radeon
    ;;
    "Video production")
      ## Omarchy Video Production
      flatpak install flathub org.kde.kdenlive -y
      sudo pacman --noconfirm -S ladspa noise-suppression-for-voice
      sudo pacman --noconfirm -S obs-studio
      yay -S --noconfirm --needed obs-multi-rtmp
    ;;
    "Artist")
      ## Omarchy Artist
      yay -S --noconfirm --needed opentabletdriver
      # Add to autostart
      systemctl --user start opentabletdriver
    ;;
    "Professional")
      ## Professional software used only for work
      yay -S --noconfirm --needed slack-desktop
      ;;
      "Dev")
      ## Development tools
      curl -LsSf https://astral.sh/uv/install.sh | sh
  esac
done
