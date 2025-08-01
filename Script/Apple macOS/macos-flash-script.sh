#!/bin/bash

# Automatic AWSW ESP32 flash script by AWSW (macOS version)
# Based on https://github.com/AWSW-de/AWSW-ESP32-flash-script

SCRIPT_VERSION="V1.5.0-macOS" # 01.08.2025

#####################################################################################################
# Welcome text output
#####################################################################################################
SCRIPT_STEPS=8

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
echo "This script can flash your ESP32 board fully automatically without the need of installing Arduino IDE or any library."
echo
echo "Everything will be downloaded and executed for you... You just need to wait some minutes until the process is finished."
echo
echo "! IMPORTANT: You are using this script at your own risk !"
echo

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
    echo "║  1. WordClock 16x8          - 2023           (ESP32 D1 mini)                      ║"
    echo "║  2. WordClock 16x16         - 2023           (ESP32 D1 mini)                      ║"
    echo "║  3. WordClock 16x8          - 2024/2025      (ESP32 NodeMCU)                      ║"
    echo "║  4. WordClock 16x16         - 2024/2025      (ESP32 NodeMCU)                      ║"
    echo "║  5. WordCalendar 16x16      - 2024/2025      (ESP32 NodeMCU)                      ║"
    echo "║  6. WordClock 14x14 Classic - 2025           (ESP32 NodeMCU)                      ║"
    echo "║  7. 12x Smart Home button   - 2025           (ESP32 Lolin32)                      ║"
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
DESTINATION_FOLDER="$HOME/Downloads/AWSW-CODE-TEMP-FOLDER"

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
# Install required tools using Homebrew
#####################################################################################################
clear
echo
echo "STEP 3 OF $SCRIPT_STEPS - Installing required tools"
echo

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Installing Python and esptool..."
brew install python3 esptool

#####################################################################################################
# Get the code bin files
#####################################################################################################
clear
echo
echo "STEP 4 OF $SCRIPT_STEPS - Downloading the code binary files for: $myProject"
echo

if [ "$eraseESP" = "0" ]; then
    echo "Downloading Code.ino.bin..."
    curl -o "$DESTINATION_FOLDER/Code.ino.bin" "http://$myURL/Code.ino.bin"
    sleep 0.5
    
    echo "Downloading Code.ino.bootloader.bin..."
    curl -o "$DESTINATION_FOLDER/Code.ino.bootloader.bin" "http://$myURL/Code.ino.bootloader.bin"
    sleep 0.5
    
    echo "Downloading Code.ino.partitions.bin..."
    curl -o "$DESTINATION_FOLDER/Code.ino.partitions.bin" "http://$myURL/Code.ino.partitions.bin"
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
    local port=$(ls /dev/cu.usbserial-* 2>/dev/null || ls /dev/cu.SLAB_USBtoUART 2>/dev/null || ls /dev/cu.wchusbserial* 2>/dev/null)
    echo "$port"
}

#####################################################################################################
# Attach ESP32 to computer
#####################################################################################################
clear
echo
echo "STEP 6 OF $SCRIPT_STEPS - User action required:"
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

echo
echo "Please attach your ESP32 now to this computer. If it was connected, disconnect and connect it again now."
echo
read -p "After attaching the board to the computer, press ENTER to continue..."
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
echo "STEP 7 OF $SCRIPT_STEPS - JUST WAIT - Flashing the ESP32 now: $myProject"
echo
echo "PLEASE JUST WAIT !!!"
echo
echo "Everything is done automatically."
echo

ESP_PORT=$(get_esp_port)
if [ -z "$ESP_PORT" ]; then
    echo "Error: No ESP32 device found. Please check the connection and try again."
    exit 1
fi

cd "$DESTINATION_FOLDER"

if [ "$eraseESP" = "1" ]; then
    echo "Erasing the ESP32 now..."
    echo
    for i in {5..1}; do
        echo "Erase flash in $i seconds... Please just wait..."
        sleep 1
    done
    esptool.py --chip esp32 --port "$ESP_PORT" erase_flash
    sleep 5
else
    echo "Flashing the ESP32 now..."
    echo
    for i in {5..1}; do
        echo "Start flashing in $i seconds... Please just wait..."
        sleep 1
    done
    esptool.py --chip esp32 --port "$ESP_PORT" \
        write_flash 0x1000 Code.ino.bootloader.bin \
        0x8000 Code.ino.partitions.bin \
        0x10000 Code.ino.bin
    sleep 5
fi

#####################################################################################################
# Cleanup and finish
#####################################################################################################
clear
echo
echo "STEP 8 OF $SCRIPT_STEPS - Complete!"
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

# Cleanup
rm -rf "$DESTINATION_FOLDER"

read -p "Press ENTER to exit..."
