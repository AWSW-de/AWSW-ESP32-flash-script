#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Automatic AWSW ESP32 flash script (Linux version)
# https://github.com/AWSW-de/AWSW-ESP32-flash-script
#
# Original Windows script: AWSW (https://github.com/AWSW-de)
# macOS version: @johnneerdael
# Linux version: @scinnod
#
# Licensed under GNU General Public License v3.0
# See LICENSE file in the repository root.
#

SCRIPT_VERSION="V1.7.0-Linux" # 13.07.2026

#####################################################################################################
# Check system requirements and permissions (no root needed!)
#####################################################################################################
check_requirements() {
    local all_ok=true
    
    # Check if Python3 is installed
    if ! command -v python3 &> /dev/null; then
        echo "⚠ Python3 is not installed."
        echo "  Please install it with: sudo apt-get install python3"
        all_ok=false
    else
        # Check if venv module OR virtualenv is available
        if ! python3 -m venv --help &> /dev/null && ! command -v virtualenv &> /dev/null; then
            echo "⚠ No virtual environment tool found."
            echo "  Please install one of:"
            echo "    • sudo apt-get install python3-venv  (recommended)"
            echo "    • pip install virtualenv"
            all_ok=false
        fi
    fi
    
    # Check if user is in dialout group (for serial port access)
    if ! groups | grep -q dialout; then
        echo "⚠ Your user is not in the 'dialout' group (needed for serial port access)."
        echo "  Please run: sudo usermod -a -G dialout $USER"
        echo "  Then log out and back in, or run: newgrp dialout"
        all_ok=false
    fi
    
    # Check if CP210x or CH341 driver is available
    # Note: On some kernels (e.g., Debian 12) drivers may be built-in rather than modules,
    # so modinfo may fail even though the driver works. We also check for loaded modules
    # and existing device files as fallbacks.
    local driver_found=false
    if modinfo cp210x &> /dev/null || modinfo ch341 &> /dev/null; then
        driver_found=true
    elif lsmod 2>/dev/null | grep -qE 'cp210x|ch341'; then
        driver_found=true
    elif ls /dev/ttyUSB* /dev/ttyACM* &> /dev/null; then
        # Device files exist, driver is working
        driver_found=true
    elif grep -qE 'cp210x|ch341' /proc/modules 2>/dev/null; then
        driver_found=true
    fi
    
    if [ "$driver_found" = false ]; then
        echo "⚠ USB-Serial drivers (cp210x, ch341) not detected."
        echo "  This check may be inaccurate if drivers are built into your kernel."
        echo "  If your ESP32 is detected when connected, you can safely ignore this."
        all_ok=false
    fi
    
    if [ "$all_ok" = false ]; then
        echo
        read -p "Some requirements may not be met. Continue anyway? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

#####################################################################################################
# Welcome text output
#####################################################################################################
SCRIPT_STEPS=6

clear
cat << "EOF"
    #    #     #  #####  #     #     #######  #####  ######   #####   #####   
   # #   #  #  # #     # #  #  #     #       #     # #     # #     # #     #  
  #   #  #  #  # #       #  #  #     #       #       #     #       #       #  
 #     # #  #  #  #####  #  #  #     #####    #####  ######   #####   #####   
 ####### #  #  #       # #  #  #     #             # #             # #        
 #     # #  #  # #     # #  #  #     #       #     # #       #     # #        
 #     #  ## ##   #####   ## ##      #######  #####  #        #####  #######  
                                                                             
 #######                                 #####                               
 #       #        ##    ####  #    #    #     #  ####  #####  # #####  ##### 
 #       #       #  #  #      #    #    #       #    # #    # # #    #   #   
 #####   #      #    #  ####  ######     #####  #      #    # # #    #   #   
 #       #      ######      # #    #          # #      #####  # #####    #   
 #       #      #    # #    # #    #    #     # #    # #   #  # #        #   
 #       ###### #    #  ####  #    #     #####   ####  #    # # #        #   
EOF

echo
echo "AWSW ESP32 Flash Script - $SCRIPT_VERSION"
echo
echo "This script runs in USER context and makes NO system changes."
echo "It uses a Python virtual environment for all dependencies."
echo
echo "! IMPORTANT: You are using this script at your own risk !"
echo

# Check requirements
check_requirements

#####################################################################################################
# Show project selection menu
#####################################################################################################
echo
echo "STEP 1 OF $SCRIPT_STEPS - Select your project to be flashed to the ESP32:"
echo

print_menu() {
    local width=83
    local title="Choose your AWSW project to flash to the ESP32:"
    
    echo "╔$(printf '═%.0s' $(seq 1 $width))╗"
    echo "║$(printf ' %.0s' $(seq 1 $(((width-${#title})/2))))$title$(printf ' %.0s' $(seq 1 $(((width-${#title})/2))))║"
    echo "╟$(printf '─%.0s' $(seq 1 $width))╢"
    echo "║  1. WordClock 16x8           - 2023           (ESP32 D1 mini)                     ║"
    echo "║  2. WordClock 16x16          - 2023           (ESP32 D1 mini)                     ║"
    echo "║  3. WordClock 16x8           - 2024/2025      (ESP32 NodeMCU)                     ║"
    echo "║  4. WordClock 16x16          - 2024/2025      (ESP32 NodeMCU)                     ║"
    echo "║  5. WordCalendar 16x16       - 2024/2025      (ESP32 NodeMCU)                     ║"
    echo "║  6. WordClock 14x14 Classic  - 2025           (ESP32 NodeMCU)                     ║"
    echo "║  7. 12x Smart Home button    - 2025           (ESP32 Lolin32)                     ║"
    echo "║  8. School Timetable         - 2025           (WaveShare ESP32)                   ║"
    echo "║  9. Matrix Pixel Clock 16x16 - 2026  	 (ESP32 NodeMCU)                      ║"
    echo "║                                                                                   ║"
    echo "║  E - Erase all ESP32 flash content only                                           ║"
    echo "║  X - Exit the script without flashing the ESP32                                   ║"
    echo "╚$(printf '═%.0s' $(seq 1 $width))╝"
}

while true; do
    print_menu
    echo
    read -p "Choose the project to flash in the next steps to the ESP32: " response
    case $response in
        1) 
            myURL="wordclock-16x8.awsw.de/d1mini"
            myProject="WordClock 16x8 - 2023"
            eraseESP="0"
            break
            ;;
        2)
            myURL="wordclock-16x16.awsw.de/d1mini"
            myProject="WordClock 16x16 - 2023"
            eraseESP="0"
            break
            ;;
        3)
            myURL="wordclock-16x8.awsw.de/nodemcu"
            myProject="WordClock 16x8 - 2024/2025"
            eraseESP="0"
            break
            ;;
        4)
            myURL="wordclock-16x16.awsw.de/nodemcu"
            myProject="WordClock 16x16 - 2024/2025"
            eraseESP="0"
            break
            ;;
        5)
            myURL="wordcalendar.awsw.de/nodemcu"
            myProject="WordCalendar - 2024/2025"
            eraseESP="0"
            break
            ;;
        6)
            myURL="wordclock-14x14.awsw.de/nodemcu"
            myProject="WordClock 14x14 Classic - 2025"
            eraseESP="0"
            break
            ;;
        7)
            myURL="smarthome12xbutton.awsw.de/lolin32"
            myProject="12x Smart Home button - 2025"
            eraseESP="0"
            break
            ;;
        8)
            myURL="schooltimetable.awsw.de/waveshareesp32"
            myProject="School Timetable - 2025"
            eraseESP="0"
            break
            ;;
        9)
            myURL="awsw.de/MatrixPixelClock16×16"
            myProject="Matrix Pixel Clock 16x16 - 2026"
            eraseESP="0"
            break
            ;;
        [eE])
            eraseESP="1"
            myProject="JUST ERASE THE ESP32 ONLY"
            break
            ;;
        [xX])
            exit 0
            ;;
    esac
done

#####################################################################################################
# Automatic cleanup of old previously used folders
#####################################################################################################
clear
# Use local temporary folder in current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DESTINATION_FOLDER="$SCRIPT_DIR/.tmp"

echo
echo "STEP 2 OF $SCRIPT_STEPS - Automatic cleanup of old script code download folders:"
echo
echo "Automatic delete of folder: $DESTINATION_FOLDER"
rm -rf "$DESTINATION_FOLDER"
echo
sleep 3

# Ensure the destination folder exists
mkdir -p "$DESTINATION_FOLDER"

#####################################################################################################
# Setup Python virtual environment and install esptool (NO SYSTEM CHANGES)
#####################################################################################################
clear
echo
echo "STEP 3 OF $SCRIPT_STEPS - Setting up Python environment and installing esptool..."
echo

cd "$DESTINATION_FOLDER"

# Create virtual environment (try venv first, fall back to virtualenv)
echo "Creating Python virtual environment..."
if python3 -m venv esptoolenv 2>/dev/null; then
    echo "  Using python3 -m venv"
elif command -v virtualenv &> /dev/null && virtualenv -p python3 esptoolenv; then
    echo "  Using virtualenv"
else
    echo "Error: Failed to create virtual environment."
    echo "Please install one of:"
    echo "  • sudo apt-get install python3-venv  (recommended)"
    echo "  • pip install virtualenv"
    exit 1
fi

# Verify venv was created properly
if [ ! -f "esptoolenv/bin/activate" ]; then
    echo "Error: Virtual environment creation failed - activate script not found."
    echo "Please install: sudo apt-get install python3-venv"
    exit 1
fi

echo "Activating virtual environment..."
source esptoolenv/bin/activate

# Verify pip is available
if ! command -v pip &> /dev/null; then
    echo "Installing pip in virtual environment..."
    python3 -m ensurepip --upgrade
fi

echo "Installing esptool in virtual environment..."
pip install --upgrade pip 2>&1 | grep -v "WARNING"
pip install esptool

echo "✓ Esptool installed successfully in isolated environment."
echo "  Python version: $(python3 --version)"
echo "  Esptool location: $(which esptool.py)"
sleep 2

#####################################################################################################
# Get the code bin files
#####################################################################################################
clear
echo
echo "STEP 4 OF $SCRIPT_STEPS - Downloading the code binary files for: $myProject"
echo

if [ "$eraseESP" = "0" ]; then
    # Security warning about HTTP downloads
    echo "⚠ SECURITY NOTICE:"
    echo "  Firmware files are downloaded over HTTP (not HTTPS)."
    echo "  This means the connection is not encrypted and files are not verified."
    echo "  Only proceed if you trust your network and the source."
    echo
    read -p "Continue with download? (y/n): " download_confirm
    if [[ ! "$download_confirm" =~ ^[Yy]$ ]]; then
        echo "Download cancelled by user."
        exit 0
    fi
    echo
    
    # Check if wget or curl is available
    DOWNLOAD_CMD=""
    if command -v wget &> /dev/null; then
        DOWNLOAD_CMD="wget -q --show-progress -O"
    elif command -v curl &> /dev/null; then
        DOWNLOAD_CMD="curl -L -o"
    else
        echo "Error: Neither wget nor curl is installed."
        echo "Please install one of them:"
        echo "  Debian/Ubuntu: sudo apt-get install wget"
        echo "  Fedora: sudo dnf install wget"
        echo "  Arch: sudo pacman -S wget"
        exit 1
    fi
    
    echo "Downloading Code.ino.bin..."
    $DOWNLOAD_CMD "$DESTINATION_FOLDER/Code.ino.bin" "http://$myURL/Code.ino.bin" || {
        echo "Error: Failed to download Code.ino.bin"
        exit 1
    }
    sleep 0.5
    
    echo "Downloading Code.ino.bootloader.bin..."
    $DOWNLOAD_CMD "$DESTINATION_FOLDER/Code.ino.bootloader.bin" "http://$myURL/Code.ino.bootloader.bin" || {
        echo "Error: Failed to download Code.ino.bootloader.bin"
        exit 1
    }
    sleep 0.5
    
    echo "Downloading Code.ino.partitions.bin..."
    $DOWNLOAD_CMD "$DESTINATION_FOLDER/Code.ino.partitions.bin" "http://$myURL/Code.ino.partitions.bin" || {
        echo "Error: Failed to download Code.ino.partitions.bin"
        exit 1
    }
    
    # Verify files were downloaded and have reasonable size
    for file in Code.ino.bin Code.ino.bootloader.bin Code.ino.partitions.bin; do
        if [ ! -f "$DESTINATION_FOLDER/$file" ]; then
            echo "Error: $file was not downloaded successfully."
            exit 1
        fi
        file_size=$(stat -f%z "$DESTINATION_FOLDER/$file" 2>/dev/null || stat -c%s "$DESTINATION_FOLDER/$file" 2>/dev/null)
        if [ "$file_size" -lt 100 ]; then
            echo "Error: $file seems too small ($file_size bytes). Download may have failed."
            exit 1
        fi
    done
    
    echo "✓ All firmware files downloaded successfully."
    echo
    sleep 3
fi

#####################################################################################################
# Find ESP32 port
#####################################################################################################
clear
echo
echo "STEP 5 OF $SCRIPT_STEPS - Detecting ESP32 device"
echo

get_esp_port() {
    # Try various common ESP32 USB serial device names
    local port=$(ls /dev/ttyUSB* 2>/dev/null | head -n 1)
    if [ -z "$port" ]; then
        port=$(ls /dev/ttyACM* 2>/dev/null | head -n 1)
    fi
    if [ -z "$port" ]; then
        port=$(ls /dev/cu.usbserial-* 2>/dev/null | head -n 1)
    fi
    echo "$port"
}

# Wait for user to connect device
cat << "EOF"
    #    #     #  #####  #     #     #######  #####  ######   #####   #####   
   # #   #  #  # #     # #  #  #     #       #     # #     # #     # #     #  
  #   #  #  #  # #       #  #  #     #       #       #     #       #       #  
 #     # #  #  #  #####  #  #  #     #####    #####  ######   #####   #####   
 ####### #  #  #       # #  #  #     #             # #             # #        
 #     # #  #  # #     # #  #  #     #       #     # #       #     # #        
 #     #  ## ##   #####   ## ##      #######  #####  #        #####  #######  
EOF

echo
echo "Please attach your ESP32 now to this computer."
echo "If it was already connected, disconnect and reconnect it now."
echo

# List available serial devices
echo "Available serial devices:"
ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "No devices found yet."
echo

read -p "After attaching the board to the computer, press ENTER to continue..."
echo

# Wait a moment for device to be recognized
sleep 2

ESP_PORT=$(get_esp_port)
if [ -z "$ESP_PORT" ]; then
    echo "Warning: No ESP32 device automatically detected."
    echo
    echo "Available serial ports:"
    ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "No devices found."
    echo
    read -p "Please enter the ESP32 port manually (e.g., /dev/ttyUSB0): " ESP_PORT
    
    if [ -z "$ESP_PORT" ] || [ ! -e "$ESP_PORT" ]; then
        echo "Error: Invalid port specified or device not found."
        exit 1
    fi
fi

echo "Using ESP32 port: $ESP_PORT"
echo

for i in {5..1}; do
    echo "Start flashing in $i seconds... Please just wait..."
    sleep 1
done

#####################################################################################################
# Flash ESP32
#####################################################################################################
clear
echo
echo "STEP 6 OF $SCRIPT_STEPS - JUST WAIT - Flashing the ESP32 now: $myProject"
echo
echo "PLEASE JUST WAIT !!!"
echo
echo "Everything is done automatically."
echo

cd "$DESTINATION_FOLDER"

# Ensure virtual environment is activated
source esptoolenv/bin/activate

# Function to try flashing with smart permission handling
flash_esp32() {
    local flash_cmd="$1"
    local error_log=$(mktemp)
    
    # Activate virtual environment to get esptool in PATH
    cd "$DESTINATION_FOLDER"
    source esptoolenv/bin/activate
    
    # Try flashing without sudo first
    if eval "$flash_cmd" 2>"$error_log"; then
        rm -f "$error_log"
        return 0
    else
        # Check if it's a permission error
        if grep -qi "permission denied\|could not open" "$error_log"; then
            echo
            echo "⚠ Permission denied accessing serial port $ESP_PORT"
            echo
            echo "You have two options:"
            echo "  1. Add yourself to 'dialout' group (recommended, permanent solution):"
            echo "     sudo usermod -a -G dialout $USER"
            echo "     Then log out and back in."
            echo
            echo "  2. Run the flash command with sudo (just this once):"
            echo
            read -p "Run flash command with sudo now? (y/n): " use_sudo
            
            if [[ "$use_sudo" =~ ^[Yy]$ ]]; then
                echo
                echo "Running flash command with sudo:"
                echo "  sudo $flash_cmd"
                echo
                # Run with sudo, preserving the virtual environment's PATH
                if sudo -E PATH="$PATH" bash -c "$flash_cmd"; then
                    rm -f "$error_log"
                    return 0
                else
                    echo "Error: Flash command failed even with sudo."
                    rm -f "$error_log"
                    return 1
                fi
            else
                echo "Flashing aborted. Please fix permissions and try again."
                rm -f "$error_log"
                return 1
            fi
        else
            # Other error
            cat "$error_log"
            rm -f "$error_log"
            return 1
        fi
    fi
}

if [ "$eraseESP" = "1" ]; then
    echo "Erasing the ESP32 now..."
    echo
    for i in {5..1}; do
        echo "Erase flash in $i seconds... Please just wait..."
        sleep 1
    done
    
    flash_cmd="esptool.py --chip esp32 --port \"$ESP_PORT\" erase_flash"
    if ! flash_esp32 "$flash_cmd"; then
        exit 1
    fi
    sleep 5
else
    echo "Flashing the ESP32 now..."
    echo
    for i in {5..1}; do
        echo "Start flashing in $i seconds... Please just wait..."
        sleep 1
    done
    
    flash_cmd="esptool.py --chip esp32 --port \"$ESP_PORT\" write_flash 0x1000 Code.ino.bootloader.bin 0x8000 Code.ino.partitions.bin 0x10000 Code.ino.bin"
    if ! flash_esp32 "$flash_cmd"; then
        exit 1
    fi
    sleep 5
fi

#####################################################################################################
# Cleanup and finish
#####################################################################################################
clear
echo
echo "Process complete!"
echo
cat << "EOF"
    #    #     #  #####  #     #     #######  #####  ######   #####   #####   
   # #   #  #  # #     # #  #  #     #       #     # #     # #     # #     #  
  #   #  #  #  # #       #  #  #     #       #       #     #       #       #  
 #     # #  #  #  #####  #  #  #     #####    #####  ######   #####   #####   
 ####### #  #  #       # #  #  #     #             # #             # #        
 #     # #  #  # #     # #  #  #     #       #     # #       #     # #        
 #     #  ## ##   #####   ## ##      #######  #####  #        #####  #######  
EOF

if [ "$eraseESP" = "1" ]; then
    echo
    echo "The ESP32 is now erased."
    echo
    echo "Kind regards AWSW =)"
    echo
else
    echo
    echo "Done! The ESP32 is now flashed with the selected project: $myProject"
    echo
    echo "Now you can start the WiFi setup in case you flashed a new ESP now."
    echo
    echo "Enjoy your $myProject!"
    echo
    echo "Kind regards AWSW =)"
    echo
fi

# Deactivate virtual environment
deactivate

echo
read -p "Press ENTER to exit..."
