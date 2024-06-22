#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set variables
export VER="0.21.0"

# List of prerequisite packages to install
requisites=(
    apt-transport-https
    build-essential
    ca-certificates
    curl
    file
    gnupg
    git
    lsb-release
    python3-pip
    python3-usb
    python3-venv
    rsync
    software-properties-common
    tldr
    wget
    xdg-utils
)

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "Error: $error_message" >&2
    echo "Error occurred: $error_message" >> "$LOG_FILE"
    exit 1
}

# Function to install packages using apt-get
install_package() {
    local package_name=$1
    echo "Installing $package_name..."
    apt-get install -y $package_name > /dev/null 2>&1 || handle_error "$package_name"
    echo "$package_name installed successfully!"
}

# Function to install multiple packages using apt-get
install_packages() {
    local packages=("$@")
    local packages_to_install="${packages[@]}"

    echo "Installing: ${packages_to_install}"
    apt-get install -y ${packages[@]} > /dev/null 2>&1 || handle_error "${packages[@]}"
    echo "All packages installed successfully!"
}

# Function to add a repository
add_repository() {
    local repo_info=$1
    local repo_file=$2
    echo "Adding repository: $repo_info"
    echo "$repo_info" | tee /etc/apt/sources.list.d/$repo_file.list > /dev/null
}

# Function to update apt package lists
apt_update() {
    echo "Updating package list..."
    apt-get update > /dev/null || handle_error "apt update"
    echo "Package list updated successfully."
}

# Check for root privileges
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script as root or use sudo"
    exit 1
fi

# Log file setup
LOG_FILE="/var/log/installation_script.log"
exec > >(tee -i "$LOG_FILE")
exec 2>&1

# Upgrade all packages
echo "Updating and upgrading all packages..."
apt_update && apt-get upgrade -y > /dev/null || handle_error "package upgrade"
echo "All packages upgraded successfully."

# Install essential packages listed in requisites
install_packages "${requisites[@]}"

# Add Universe repository
echo "Adding Universe repository..."
add-apt-repository universe -y > /dev/null

# Add Spotify GPG key and repository
echo "Adding Spotify GPG key..."
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg > /dev/null 2>&1 || handle_error "Spotify GPG key"
echo "Spotify GPG key added successfully."
add_repository "deb http://repository.spotify.com stable non-free" "spotify"
apt_update

# Install Spotify client
install_package "spotify-client"

# Install Flatpak if not installed and Flathub repository
install_package "flatpak"
echo "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null || handle_error "Flathub repository"
echo "Flathub repository added successfully."

# Install FreeTube
echo "Installing Freetube..."
wget -q https://github.com/FreeTubeApp/FreeTube/releases/download/v${VER}-beta/FreeTube_${VER}_amd64.deb
apt-get install -f ./FreeTube_${VER}_amd64.deb -y > /dev/null
echo "Freetube installed successfully."

# Install Tor Browser Launcher
install_package "torbrowser-launcher"

# Determine distribution codename for LibreWolf repository
distro=$(if echo " una bookworm vanessa focal jammy bullseye vera uma " | grep -q " $(lsb_release -sc) "; then lsb_release -sc; else echo focal; fi)

# Add LibreWolf repository and key
echo "Adding LibreWolf repository..."
wget -O- https://deb.librewolf.net/keyring.gpg | gpg --dearmor -o /usr/share/keyrings/librewolf.gpg > /dev/null
tee /etc/apt/sources.list.d/librewolf.sources << EOF > /dev/null
Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg
EOF
apt_update

# Add Mullvad repository and key
echo "Adding Mullvad repository and key..."
curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc || handle_error "Download Mullvad key failed"
echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/mullvad.list > /dev/null || handle_error "Add Mullvad repository failed"
apt_update
echo "Mullvad repository added successfully."

# Install Mullvad VPN client 
install_package "mullvad-vpn"

# Download and register Mullvad Browser
echo "Downloading Mullvad Browser..."
cd ~/Downloads
wget https://mullvad.net/en/download/browser/linux-x86_64/latest -O mullvad-browser.tar.xz > /dev/null
tar -xf mullvad-browser.tar.xz
rm mullvad-browser.tar.xz
cd mullvad-browser
echo "Registering Mullvad Browser as an app..."
xdg-settings set default-web-browser mullvad-browser.desktop > /dev/null
cd ~/Documents/dotfiles

# Install Zsh
install_package "zsh"

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" > /dev/null || handle_error "Oh My Zsh installation"
echo "Oh My Zsh installed successfully."

# Install Visual Studio Code (vscode)
echo "Installing Visual Studio Code (vscode)..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
apt_update && \
install_package "code" > /dev/null || handle_error "Visual Studio Code (vscode) installation"
echo "Visual Studio Code (vscode) installed successfully."

# Add Docker's official GPG key and repository
echo "Adding Docker's official GPG key and repository..."
apt-get update > /dev/null
install_package "ca-certificates curl"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc > /dev/null
chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding Docker repository..."
add_repository "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" "docker"
apt_update

# Install Docker components
echo "Installing Docker components..."
install_package "docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
echo "Docker components installed successfully."

# Script execution completed
echo "Installs completed. Log file can be found at $LOG_FILE."
