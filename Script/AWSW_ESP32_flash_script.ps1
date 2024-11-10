# Automatic AWSW ESP32 flash script by AWSW on https://github.com/AWSW-de/AWSW-ESP32-flash-script
# DO NOT CHANGE ANYTHING FROM THIS LINE ON ! # # DO NOT CHANGE ANYTHING FROM THIS LINE ON ! # # DO NOT CHANGE ANYTHING FROM THIS LINE ON ! #

$ScriptVersion = "V1.0.0" # 10.11.2024

#####################################################################################################
# Was the script started with Administrator priviliges?:
#####################################################################################################
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
	Start-Process powershell.exe "-WindowStyle Maximized -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}


#####################################################################################################
# Welcome text outout
#####################################################################################################
$ScriptSteps = 8
clear
Write-Host "
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
"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "AWSW ESP32 Flash Script -" $ScriptVersion
Write-Host " " 
Write-Host "This script can flash your ESP32 board fully automatically without the need of installing Arduino IDE or any library."
Write-Host " "
Write-Host "Everything will be downloaded and executed for you... You just need to wait some minutes until the process is finished."
Write-Host " "
Write-Host "! IMPORTANT: You are using this script at your own risk. The manual way to do this is well described too !" 
Write-Host " "
Write-Host " " 



#####################################################################################################
# Show project selection menu:
#####################################################################################################
Write-Host " "
Write-Host "STEP 1 OF" $ScriptSteps "- Select your project to be flashed to the ESP32:"
Write-Host " "

Function CreateMenu{
    param(
        [parameter(Mandatory=$true)][String[]]$Selections,
        [switch]$IncludeExit,
        [switch]$IncludeErase,
        [string]$Title = $null
        )

    $Width = if($Title){$Length = $Title.Length;$Length2 = $Selections|%{$_.length}|Sort -Descending|Select -First 1;$Length2,$Length|Sort -Descending|Select -First 1}else{$Selections|%{$_.length}|Sort -Descending|Select -First 1}
    $Buffer = if(($Width*1.5) -gt 78){[math]::floor((78-$width)/2)}else{[math]::floor($width/4)}
    if($Buffer -gt 6){$Buffer = 6}
    $MaxWidth = $Buffer*2+$Width+$($Selections.count).length+2
    $Menu = @()
    $Menu += "╔"+"═"*$maxwidth+"╗"
    if($Title){
        $Menu += "║"+" "*[Math]::Floor(($maxwidth-$title.Length)/2)+$Title+" "*[Math]::Ceiling(($maxwidth-$title.Length)/2)+"║"
        $Menu += "╟"+"─"*$maxwidth+"╢"
    }
    For($i=1;$i -le $Selections.count;$i++){
        $Item = "$(if ($Selections.count -gt 9 -and $i -lt 10){" "})$i`. "
        $Menu += "║"+" "*$Buffer+$Item+$Selections[$i-1]+" "*($MaxWidth-$Buffer-$Item.Length-$Selections[$i-1].Length)+"║"
    }
    If($IncludeErase){
        $Menu += "║"+" "*$MaxWidth+"║"
        $Menu += "║"+" "*$Buffer+"E - Erase all ESP32 flash content only"+" "*($MaxWidth-$Buffer-38)+"║"
    }
    If($IncludeExit){
        $Menu += "║"+" "*$MaxWidth+"║"
        $Menu += "║"+" "*$Buffer+"X - Exit the script without flashing the ESP32"+" "*($MaxWidth-$Buffer-46)+"║"
    }
    $Menu += "╚"+"═"*$maxwidth+"╝"
    $menu
}

Do{
    #cls
    CreateMenu -Selections 'WordClock 16x8  - 2023 (ESP32 D1 mini)','WordClock 16x16 - 2023 (ESP32 D1 mini)','WordClock 16x8  - 2024 (ESP32 NodeMCU)','WordClock 16x16 - 2024 (ESP32 NodeMCU)' -Title 'Choose your AWSW project to flash to the ESP32:' -IncludeExit -IncludeErase # ,'WordCalendar    - 2024 (ESP32 NodeMCU)'
    $Response = Read-Host "Choose the project to flash in the next steps to the ESP32"
}While($Response -notin 1,2,3,4,5,'e','x')

$eraseESP = "0"

switch ($Response)
{
    1 { $myURL = "wordclock-16x8.awsw.de/d1mini"
        $myProject = "WordClock 16x8 - 2023"}
    2 { $myURL = "wordclock-16x16.awsw.de/d1mini"
        $myProject = "WordClock 16x16 - 2023"}
    3 { $myURL = "wordclock-16x8.awsw.de/nodemcu"
        $myProject = "WordClock 16x8 - 2024"}
    4 { $myURL = "wordclock-16x16.awsw.de/nodemcu"
        $myProject = "WordClock 16x16 - 2024"}
    5 { $myURL = "wordcalendar.awsw.de/nodemcu"
        $myProject = "WordCalendar - 2024"}
    e { $eraseESP = "1" } 
    x { Exit }
}


#####################################################################################################
# Automatic cleanup of old previously with script used folders:
#####################################################################################################
clear
# Destination folders:
$DestinationFolder1 = "$env:USERPROFILE\Downloads\AWSW-CODE-TEMP-FOLDER"
# Remove existing folders:
Write-Host " "
Write-Host "STEP 2 OF" $ScriptSteps "- Automatic cleanup of old script code download folders:"
Write-Host " "
Write-Host "Automatic delete of folder: $DestinationFolder1"
Remove-Item $DestinationFolder1 -Recurse -ErrorAction Ignore
Write-Host " "
Sleep 3
# Ensure the destination folder exists
If (-not (Test-Path $DestinationFolder1)) {
    New-Item -Path $DestinationFolder1 -ItemType Directory
} 


#####################################################################################################
# Get the code bin files:
#####################################################################################################
clear
Write-Host " "
Write-Host "STEP 3 OF" $ScriptSteps "- Downloading Python and the code binary files for:" $myProject
Write-Host " "
Write-Host " "
$ProgressPreference = 'SilentlyContinue'
Sleep 3
Write-Host "Downloading Python 3.1.3 installer..."
Invoke-WebRequest -Uri ("https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe") -OutFile "$DestinationFolder1\python-3.13.0-amd64.exe"
Sleep 0.5
if($eraseESP -eq "0") {
Write-Host "Downloading Code.ino.bin..."
Invoke-WebRequest -Uri ("http://" + $myURL + "/Code.ino.bin") -OutFile "$DestinationFolder1\Code.ino.bin"
Sleep 0.5
Write-Host "Downloading Code.ino.bootloader.bin..."
Invoke-WebRequest -Uri ("http://" + $myURL + "/Code.ino.bootloader.bin") -OutFile "$DestinationFolder1\Code.ino.bootloader.bin"
Sleep 0.5
Write-Host "Downloading Code.ino.partitions.bin..."
Invoke-WebRequest -Uri ("http://" + $myURL + "/Code.ino.partitions.bin") -OutFile "$DestinationFolder1\Code.ino.partitions.bin"
Write-Host " "
Sleep 3
}


#####################################################################################################
# Automatic download and install ESP32 board driver:
#####################################################################################################
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
clear
Write-Host " "
Write-Host "STEP 4 OF" $ScriptSteps "- Automatic download and install ESP32 board driver..."
Write-Host " "
Sleep 3
Invoke-WebRequest -Uri "https://www.silabs.com/documents/public/software/CP210x_Universal_Windows_Driver.zip" -OutFile "$DestinationFolder1\CP210x_Universal_Windows_Driver.zip"
New-Item -Path "$DestinationFolder1\CP210x-Driver" -ItemType Directory
Unzip "$DestinationFolder1\CP210x_Universal_Windows_Driver.zip" "$DestinationFolder1\CP210x-Driver"
Sleep 1
Get-ChildItem "$DestinationFolder1\CP210x-Driver" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install }
Sleep 5


#####################################################################################################
# Installing Python and PIP onto this computer:
#####################################################################################################
$PythonWasInstalled = "unclear"
#redirect stderr into stdout
$p = &{python -V} 2>&1
# check if an ErrorRecord was returned
$PythonVersion = if($p -is [System.Management.Automation.ErrorRecord])
{
    # grab the version string from the error message
    $p.Exception.Message
    $PythonWasInstalled = "no"
}     
else  
{
    # otherwise return as is
    $p
    $PythonWasInstalled = "yes"
}
#$PythonWasInstalled
#$PythonVersion
#pause


clear
Write-Host " "
Write-Host "STEP 5 OF" $ScriptSteps "- Setup Python and PIP as flash environment..."
Write-Host " "
Write-Host " "
Start-Process -FilePath "$DestinationFolder1\python-3.13.0-amd64.exe" -ArgumentList "/passive InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
Sleep 1

if ($PythonWasInstalled -eq "no") {
    Write-Host " "
    Write-Host " "
    Write-Host "The script needs to be restarted to be able to use the new to this machine installed Pyhon installation."
    Write-Host " "
    Write-Host "Press ENTER to end script now and restart it again then."
    Write-Host " "
    pause
	Exit
}

if ($PythonWasInstalled -eq "yes") {
    Write-Host "Installed Python version:"
    python -V 
    Write-Host " "
    Write-Host " "
    Write-Host "Instaling PIP and activate the ESP32 flash tool environment..."
    Write-Host " "
    cd $DestinationFolder1
    Sleep 1
    python -m venv esptoolenv
    Sleep 1
    esptoolenv\Scripts\activate
    Sleep 1
    pip install esptool
    Sleep 1
    python -m pip install --upgrade pip
    Sleep 3
}


#####################################################################################################
# Attach ESP32 to computer:
#####################################################################################################
clear
Write-Host " "
Write-Host "STEP 6 OF" $ScriptSteps "- User action required:"
Write-Host " "
Write-Host "
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
"
Write-Host " "
Write-Host "Downloading the code files, Python, PIP and installing required ESP32 board driver was done."
Write-Host " "
Write-Host "NOW: Please attach your ESP32 now to this computer. If it was connected, disconnect and connect it again now."
Write-Host " "
Write-Host "After attaching the board to the computer, press ENTER and then JUST WAIT to let the script flash the code."
Write-Host " "
pause
Write-Host " "
Write-Host " "
for ($i = 5; $i -gt 0; $i--) {
    Write-Host "Start flashing in $i seconds... Please just wait..."
    Sleep 1
}


#####################################################################################################
# Flash ESP32:
#####################################################################################################
clear
Write-Host " "
Write-Host "STEP 7 OF" $ScriptSteps "- JUST WAIT - Erasing and then flashing the ESP32 now:"
Write-Host " "
Write-Host " "
Write-Host "PLEASE JUST WAIT !!!"
Write-Host " "
Write-Host "Everything is done automatically."
Write-Host " "
Write-Host " "
if ($Response -eq "e") {
Write-Host "Erasing the ESP32 now..."
Write-Host " "
for ($i = 5; $i -gt 0; $i--) {
    Write-Host "Erase flash in $i seconds... Please just wait..."
    Sleep 1
}
esptool --chip esp32 erase_flash #--port COM9
Sleep 5
} else {
 if($eraseESP -eq "0") {
    Write-Host " "
    Write-Host " "
    Write-Host " "
    Write-Host "Flashing the ESP32 now..."
    Write-Host " "
    for ($i = 5; $i -gt 0; $i--) {
        Write-Host "Start flashing in $i seconds... Please just wait..."
        Sleep 1
    }
    esptool write_flash 0x1000 .\Code.ino.bootloader.bin 0x8000 .\Code.ino.partitions.bin 0x10000 .\Code.ino.bin #--port COM9
    Sleep 5
 }
}


#####################################################################################################
# Delete temporary download folder again and restart ESP32:
#####################################################################################################
clear
Write-Host " "
Write-Host "STEP 8 OF" $ScriptSteps "- User action required:"
Write-Host " "
Write-Host "
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
"

  if($eraseESP -eq "1") {
    Write-Host " "
    Write-Host "The ESP32 is now erased."
    Write-Host " "
    Write-Host " "
    Write-Host "Kind regards AWSW =)"
    Write-Host " "
    Write-Host " "
  }

  if($eraseESP -eq "0") {
    Write-Host " "
    Write-Host "Done! The ESP32 is now flashed with the selected project:" $myProject
    Write-Host " "
    Write-Host " "
    Write-Host "Now you can start the WiFi setup in case you flashed a new ESP now."
    Write-Host " "
    Write-Host " "
    Write-Host "Enjoy your" $myProject "!"
    Write-Host " "
    Write-Host "Kind regards AWSW =)"
    Write-Host " "
    Write-Host " "
  }
pause