#!/usr/bin/env bash

# Nihon Installer v1.0.0

set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CHECK="${GREEN}✔${NC}"
CROSS="${RED}✖${NC}"
INFO="${CYAN}➜${NC}"
WARN="${YELLOW}⚠${NC}"

# Update these URLs to point to your hosted files
DYLIB_URL="https://github.com/zeronildev/Nihon-mac/raw/b9568b8f3720efe0a6b075c7c0724f13b6691fdb/libNihon.dylib"
UI_URL="https://github.com/zeronildev/NihonApp/raw/refs/heads/main/NihonApp.zip"
MODULES_URL="https://github.com/zeronildev/Nihon-mac/raw/refs/heads/main/Modules.zip"

if [ -w "/Applications" ]; then
    APP_DIR="/Applications"
    echo -e "${INFO} Installing Roblox to /Applications"
else
    APP_DIR="$HOME/Applications"
    mkdir -p "$APP_DIR"
    echo -e "${WARN} No write access to /Applications; using $APP_DIR instead."
fi

TEMP="$(mktemp -d)"

spinner() {
    local msg="$1"
    local pid="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r\033[K${CYAN}[${spin:i++%${#spin}:1}]${NC} %s" "$msg "
        sleep 0.1
    done

    wait "$pid"
    printf "\r\033[K"
    printf "${GREEN}${CHECK} %s - Completed${NC}\n" "$msg"
    return 0
}

banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat <<'EOF'
    ███╗   ██╗██╗██╗  ██╗ ██████╗ ███╗   ██╗
    ████╗  ██║██║██║  ██║██╔═══██╗████╗  ██║
    ██╔██╗ ██║██║███████║██║   ██║██╔██╗ ██║
    ██║╚██╗██║██║██╔══██║██║   ██║██║╚██╗██║
    ██║ ╚████║██║██║  ██║╚██████╔╝██║ ╚████║
    ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Welcome to Nihon Mac OS${NC}"
}

section() {
    echo
    echo -e "${BOLD}${CYAN}==> $1${NC}"
}

main() {
    banner

    killall -9 RobloxPlayer Nihon &>/dev/null || true
    
    rm -rf "$APP_DIR/Roblox.app" "$APP_DIR/Nihon.app"
    rm -rf ~/Nihon/modules/latest.json ~/Nihon/modules/luau-lsp ~/Nihon/modules/Server

    section "Fetching client version"
    local version="version-d0722e371e604117"  
    echo -e "${INFO} Version: ${BOLD}$version${NC}"

    section "Downloading Roblox - ($version)"
    (
        curl -fsSL "https://setup.rbxcdn.com/mac/$version-RobloxPlayer.zip" -o "$TEMP/RobloxPlayer.zip"
        unzip -oq "$TEMP/RobloxPlayer.zip" -d "$TEMP"
        mv "$TEMP/RobloxPlayer.app" "$APP_DIR/Roblox.app"
        xattr -cr "$APP_DIR/Roblox.app"
    ) & spinner "Downloading Roblox" $!

    section "Installing Nihon modules"
    (
        mkdir -p ~/Nihon/workspace ~/Nihon/autoexec ~/Nihon/themes ~/Nihon/modules ~/Nihon/modules/Server ~/Nihon/modules/luau-lsp

        curl -fsSL "$DYLIB_URL" -o "$TEMP/libNihon.dylib"
        curl -fsSL "$UI_URL" -o "$TEMP/NihonApp.zip"
        curl -fsSL "$MODULES_URL" -o "$TEMP/Modules.zip"

        unzip -o -qq "$TEMP/NihonApp.zip" -d "$TEMP"
        unzip -o -qq "$TEMP/Modules.zip" -d "$TEMP"

        mv "$TEMP/libNihon.dylib" "$APP_DIR/Roblox.app/Contents/Resources/libNihon.dylib"
        mv "$TEMP/Nihon.app" "$APP_DIR/Nihon.app"

        mv "$TEMP/Modules/Server" ~/Nihon/modules/Server/server
        mv "$TEMP/Modules/luau-lsp" ~/Nihon/modules/luau-lsp/luau-lsp

        "$TEMP/Modules/Patcher" "$APP_DIR/Roblox.app/Contents/Resources/libNihon.dylib" "$APP_DIR/Roblox.app/Contents/MacOS/libmimalloc.3.dylib" --strip-codesig --all-yes >/dev/null 2>&1
        mv "$APP_DIR/Roblox.app/Contents/MacOS/libmimalloc.3.dylib_patched" "$APP_DIR/Roblox.app/Contents/MacOS/libmimalloc.3.dylib"

        mkdir -p ~/Nihon/workspace ~/Nihon/autoexec ~/Nihon/themes ~/Nihon/modules
    ) & spinner "Installing Nihon" $!

    section "Finishing installation"
    (
        codesign --force --deep --sign - "$APP_DIR/Roblox.app" >/dev/null 2>&1
        codesign --force --deep --sign - "$APP_DIR/nihon.app" >/dev/null 2>&1
        rm -rf "$TEMP"
        rm -rf "$APP_DIR/Roblox.app/Contents/MacOS/RobloxPlayerInstaller.app" >/dev/null 2>&1
        tccutil reset Accessibility com.Roblox.RobloxPlayer >/dev/null 2>&1
    ) & spinner "Almost done!" $!

    echo
    echo -e "${GREEN}${BOLD}Installation complete!${NC}"
    echo -e "${INFO} Nihon has been installed to $APP_DIR"
    echo -e "${CHECK} Nihon is currently updated to the newest version and is working!"
    echo -e "${WARN} Please use an alt account for safety."
    
    open "$APP_DIR/Roblox.app"
    open "$APP_DIR/Nihon.app"
}

main
