#!/usr/bin/env bash
# ▄▄▄▄▄▄                                           ▄▄▄▄      ▄▄▄▄                                      ▄▄▄▄                           ██
# ▀▀██▀▀                         ██                ▀▀██      ▀▀██                                    ▄█▀▀▀▀█                          ▀▀                 ██
#   ██     ██▄████▄  ▄▄█████▄  ███████    ▄█████▄    ██        ██       ▄████▄    ██▄████            ██▄        ▄█████▄   ██▄████   ████     ██▄███▄   ███████
#   ██     ██▀   ██  ██▄▄▄▄ ▀    ██       ▀ ▄▄▄██    ██        ██      ██▄▄▄▄██   ██▀                 ▀████▄   ██▀    ▀   ██▀         ██     ██▀  ▀██    ██
#   ██     ██    ██   ▀▀▀▀██▄    ██      ▄██▀▀▀██    ██        ██      ██▀▀▀▀▀▀   ██                      ▀██  ██         ██          ██     ██    ██    ██
# ▄▄██▄▄   ██    ██  █▄▄▄▄▄██    ██▄▄▄   ██▄▄▄███    ██▄▄▄     ██▄▄▄   ▀██▄▄▄▄█   ██                 █▄▄▄▄▄█▀  ▀██▄▄▄▄█   ██       ▄▄▄██▄▄▄  ███▄▄██▀    ██▄▄▄
# ▀▀▀▀▀▀   ▀▀    ▀▀   ▀▀▀▀▀▀      ▀▀▀▀    ▀▀▀▀ ▀▀     ▀▀▀▀      ▀▀▀▀     ▀▀▀▀▀    ▀▀                  ▀▀▀▀▀      ▀▀▀▀▀    ▀▀       ▀▀▀▀▀▀▀▀  ██ ▀▀▀       ▀▀▀▀
#                                                                                                                                            ██

# Env var for where the repo was cloned
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# add slangc to PATH
PATH=/opt/shader-slang/bin:$PATH

# Define the software that would be installed
prep_stage=(
    xdg-user-dirs
    wget
    curl
    inotify-tools
    stow
    vulkan-headers
    cpptrace
    plocate
    qt5-wayland
    qt5ct
    qt6-wayland
    qt6ct-kde
    qt6-multimedia
    qt5-svg
    qt5-quickcontrols2
    qt5-graphicaleffects
    gtk3
    gtk4
    gtk4-layer-shell
    pipewire
    wireplumber
    jq
    wl-clipboard
    cliphist
    pacman-contrib
    cmake
)

#software for nvidia GPU only
nvidia_stage=(
    linux-headers
    nvidia-dkms
    nvidia-settings
    libva
    libva-nvidia-driver-git
)

#the main packages
install_stage=(
    flatpak
    ufw
    playerctl
    man-db
    man-pages
    kanata-bin
    fd
    bat
    topgrade
    git-delta
    rust
    niri-git
    xwayland-satellite
    cups-pk-helper
    kimageformats
    rust-analyzer
    jdk-openjdk
    vesktop
    npm
    vlc
    auto-cpufreq
    banana-cursor-bin
    shader-slang-bin
    python-sphinx_design
    kitty-git
    quickshell-git
    dms-shell-git
    inter-font
    dsearch-git
    sddm
    sddm-theme-elegant-archlinux-git
    matugen
    cava
    wtype
    imagemagick
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    swappy
    otf-font-awesome
    helium-browser-bin
    shellcheck
    fzf
    tealdeer
    zsh
    trash-cli
    starship-git
    yazi
    resvg
    ueberzugpp
    ffmpegthumbnailer
    unarchiver
    poppler
    fastfetch
    shell-color-scripts-git
    tmux
    sesh-bin
    ripgrep
    neovim
    tree-sitter-cli
    ascii-image-converter
    lazygit-git
    docker
    lazydocker
    zoxide
    eza
    toilet
    toilet-fonts
    fortune-mod
    pay-respects-git
    cowsay
    adw-gtk-theme
    neo-candy-icons
    libreoffice-fresh
    thunderbird
    mpv
    pamixer
    pulsecontrol-git
    brightnessctl
    bluez
    bluez-utils
    overskride
    gvfs
    file-roller
    nerd-fonts
    noto-fonts-emoji
    nwg-look
)

flatpaks=(
    io.github.flattool.Ignition
    com.github.tchx84.Flatseal
    com.spotify.Client
)

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
INSTLOG=$SCRIPT_DIR/install.log

######
# functions go here

# function that would show a progress bar to the user
show_progress() {
    while ps | grep "$1" &>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo -en " Done!\n"
}

clear

# attempt to discover if this is a VM or not
echo -e "$CNT - Checking for Physical or VM..."
ISVM=$(hostnamectl | grep Chassis)
echo -e "Using $ISVM"
if [[ $ISVM == *"vm"* ]]; then
    echo -e "$CWR - Please note that VMs are not fully supported and if you try to run this on
    a Virtual Machine there is a high chance this will fail."
fi

# let the user know that we will use sudo
echo -e "$CNT - This script will run some commands that require sudo. You will be prompted to enter your password.
If you are worried about entering your password then you may want to review the content of the script.
IMPORTANT: yay will panic if a package it is trying to install conflicts with an already installed package.
Feel free to look through the package list and remove any packages that would conflict (AUR packages that may be development branches of official packages)."

# give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting..."
    sudo touch /tmp/sudo.tmp
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

# find the Nvidia GPU
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    ISNVIDIA=true
else
    ISNVIDIA=false
fi

### Disable wifi powersave mode ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to disable WiFi powersave? (y,n) ' WIFI
if [[ $WIFI == "Y" || $WIFI == "y" ]]; then
    LOC="/etc/NetworkManager/conf.d/wifi-powersave.conf"
    echo -e "$CNT - The following file has been created $LOC.\n"
    echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a $LOC &>>"$INSTLOG"
    echo -en "$CNT - Restarting NetworkManager service, Please wait."
    sudo systemctl restart NetworkManager &>>"$INSTLOG"

    #wait for services to restore (looking at you DNS)
    for _ in {1..6}; do
        echo -n "."
        sleep 1
    done
    echo -en "Done!\n"
    echo -e "\e[1A\e[K$COK - NetworkManager restart completed."
fi

echo -e "$CNT - Installing reflector"
sudo pacman -S reflector --needed --noconfirm &>>"$INSTLOG" || exit
echo -e "\e[1A\e[K$COK - Reflector installed."
echo -e "$CNT - Updating mirrorlist"
while ! sudo reflector -f 30 -l 30 --number 20 --sort rate --verbose --save /etc/pacman.d/mirrorlist &>>"$INSTLOG"; do
    true
done
echo -e "\e[1A\e[K$COK - Mirrorlist updated."
sudo pacman -S --needed base-devel &>>"$INSTLOG" || exit

#### Check for package manager ####
if ! command -v yay &>/dev/null; then
    echo -en "$CNT - Installing yay."
    git clone https://aur.archlinux.org/yay.git &>>"$INSTLOG"
    cd yay || exit
    if makepkg -si --noconfirm; then
        echo -e "\e[1A\e[K$COK - yay installed"
        cd ..

        # update the yay database
        echo -en "$CNT - Running a system update."
        yay -Syyu --noconfirm &>>"$INSTLOG" &
        show_progress $!
        echo -e "\e[1A\e[K$COK - System updated."
    else
        # if this is hit then a package is missing, exit to review log
        echo -e "\e[1A\e[K$CER - yay install failed, please check the install.log"
        exit
    fi
else
    echo -en "$CNT - Running a system update."
    yay -Syyu --noconfirm &>>"$INSTLOG" &
    show_progress $!
    echo -e "\e[1A\e[K$COK - System updated."
fi

sudo cp "$SCRIPT_DIR"/cleancache.hook /usr/share/libalpm/hooks
sudo cp "$SCRIPT_DIR"/clearcache /usr/share/libalpm/scripts

# Prep Stage - Bunch of needed items
for SOFTWR in "${prep_stage[@]}"; do
    yay -S --noconfirm --needed "$SOFTWR" || exit
done

# Setup Nvidia if it was found
if [[ "$ISNVIDIA" == true ]]; then
    echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
    for SOFTWR in "${nvidia_stage[@]}"; do
        yay -S --noconfirm --needed "$SOFTWR" || exit
    done

    # update config
    sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
    echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>>"$INSTLOG"
fi

# Stage 1 - main components
for SOFTWR in "${install_stage[@]}"; do
    yay -S --needed --noconfirm "$SOFTWR" || exit
done

# Install flatpaks
for SOFTWR in "${flatpaks[@]}"; do
    flatpak install "$SOFTWR" -y || exit
done

# Download package db for pay-respects
yay -Fy --noconfirm

# Switch to zsh
chsh -s "$(which zsh)"

# Find existing symlinks and ask user if they want it removed
clear
echo -e "$CNT - Existing symlinks to your configs will need to be removed for
stow to work properly. If you have an existing symlink, remove it if it is for
something in this repo. The interactive menu is below."
find ~/.config -type l -exec rm -i {} +
find ~/.local/bin -type l -exec rm -i {} +
[[ -L ~/.zshrc ]] && rm ~/.zshrc
[[ -L ~/.zshenv ]] && rm ~/.zshenv
[[ -L ~/.gitconfig ]] && rm ~/.gitconfig
[[ -L ~/.tmux.conf ]] && rm ~/.tmux.conf
[[ -L ~/.Xresources ]] && rm ~/.Xresources

# generate symlinks for dotfiles
cd "$SCRIPT_DIR" || exit
{
    xdg-user-dirs-update
    stow --adopt --no-folding --target="$HOME" common
    git reset --hard
} &>>"$INSTLOG"

# Start the bluetooth service
echo -e "$CNT - Starting the Bluetooth Service..."
sudo systemctl enable --now bluetooth.service &>>"$INSTLOG"

# Enable auto-cpufreq service
echo -e "$CNT - Enabling the auto-cpufreq Service..."
sudo systemctl enable --now auto-cpufreq &>>"$INSTLOG"

# Sync dsearch
dsearch index sync

# Configure sddm theme
sudo /usr/share/sddm/themes/elegant-archlinux/customize.sh

# This colorscript needs .Xresources which you don't need in wayland
colorscript blacklist hex

# Disable and clean power-profiles-daemon if installed
sudo systemctl disable power-profiles-daemon &>>"$INSTLOG"
yay -Q power-profiles-daemon &>/dev/null && yay -Rns power-profiles-daemon &>>"$INSTLOG"

WLDIR=/usr/share/wayland-sessions
if [ -d "$WLDIR" ]; then
    echo -e "$COK - $WLDIR found"
else
    echo -e "$CWR - $WLDIR NOT found, creating..."
    sudo mkdir $WLDIR
fi

# Set up plocate
echo -e "$CNT - Updating plocate database"
sudo updatedb &>>"$INSTLOG"

# Set up ufw
echo -e "$CNT - Setting up UFW"
{
    sudo ufw limit 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable
} &>>"$INSTLOG"

# Set up tpm for tmux
echo -e "$CNT - Setting up tmux plugins"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm &>>"$INSTLOG"
systemctl --user enable tmux.service

### Script is done ###
echo -e "$CNT - Script had completed!"
if [[ "$ISNVIDIA" == true ]]; then
    echo -e "$CAT - Since we attempted to setup an Nvidia GPU the script will now end and you should reboot.
    Please type 'reboot' at the prompt and hit Enter when ready."
    exit 0
fi

echo -e "$CNT - If you are using a laptop, consider using the kanata service to remap your laptop keyboard for easier access to modifier keys. Just run these commands after ensuring that the device specified in config.kbd is the correct one:
sudo cp $SCRIPT_DIR/kanata.service /etc/systemd/system
sudo cp $SCRIPT_DIR/config.kbd /etc
sudo systemctl enable kanata.service
"

exit 0
