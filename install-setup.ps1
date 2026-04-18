#Requires -RunAsAdministrator
$script:reg_path = "HKCU:\SOFTWARE\wepb-fix"
function Set-Cfg { # Change values within the .cfg if we already did the installation correctly.
    $vp8_opt
    $vp8l_opt
    $vp8x_gif_opt
    $vp8x_opt
    Write-Host "VP8 (lossy, no transparency) .webp format conversion? (.png or .jpg)"
    $user_input = Read-Host -Prompt "Enter .png or .jpg (default: .jpg) "
    $cleaned_input = $user_input -replace '[^0-9A-Za-z_]' # Remove all non alphanumerical characters
    if($cleaned_input -eq "png"){
        $vp8_opt = ".png"
    }
    else{
	    $vp8_opt = ".jpg"
    }
    Write-Host "VP8L (lossless, can have transparency) .webp format conversion? (.png or .jpg)"
    $user_input = Read-Host -Prompt "Enter .png or .jpg (default: .png) "
    $cleaned_input = $user_input -replace '[^0-9A-Za-z_]' # Remove all non alphanumerical characters
    if($cleaned_input -eq "jpg"){
        $vp8l_opt = ".jpg"
    }
    else{
	    $vp8l_opt = ".png"
    }
    Write-Host "Allow VP8X .webp (extended format) with animation flag to be saved as gif?"
    $user_input = Read-Host -Prompt "Enter Y or N (default: Y) "
    $cleaned_input = $user_input -replace '[^0-9A-Za-z_]' # Remove all non alphanumerical characters
    if($cleaned_input -eq "n"){
	    $vp8x_gif_opt = "true"
    }
    else{
	    $vp8x_gif_opt = "true"
    }
    Write-Host "VP8X (non-animated) .webp format conversion? (.png or .jpg)"
    $user_input = Read-Host -Prompt "Enter .png or .jpg (default: .png) "
    $cleaned_input = $user_input -replace '[^0-9A-Za-z_]' # Remove all non alphanumerical characters
    if($cleaned_input -eq "jpg"){
        $vp8x_opt = ".jpg"
    }
    else{
	    $vp8x_opt = ".png"
    }
    # Force rewrite of the CFG file.
    $reg_install_path = Get-ItemPropertyValue -Path $reg_path -Name "Location" # reference the install folder path that was added to the registry, as we need this function to work outside of the first open
    $cfg_location =  $reg_install_path + "\config.cfg"
    Write-Host "Writing to $cfg_location..."
    Set-Content -Path $cfg_location -Value "vp8-format=$vp8_opt`nvp8l_format=$vp8l_opt`nvp8x_anim_gif=$vp8x_gif_opt`nvp8x_format=$vp8x_opt"
}

function Install-PS2EXE { # Function to verify PS2EXE is installed within powershell.
    Write-Host "Verifying ps2exe installation..."
    try {
        if (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue){ # Do we have the command?
            $ps2exe_installed = $true
        }
        else {
            $ps2exe_installed = $false
        }
    }
    catch { # Couldn't actually confirm.
        Write-Error "Can't determine if ps2exe is installed."
        $ps2exe_installed = $false
    }
    if(!$ps2exe_installed){ # Try to install if ps2exe is not present or couldn't confirm.
        Write-Host "Attempting install of ps2exe..."
        try{
            Install-Module ps2exe -Force
        }
        catch{
            Write-Error "Can't install ps2exe."
        }
        try { # Sanity check one last time for a ps2exe install.
            if (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue){
                $ps2exe_installed = $true
            }
            else {
                $ps2exe_installed = $false
            }
        }
        catch { # Major problems if hit this error.
            Write-Error "Can't determine if ps2exe is installed."
            Write-Host "There may be an issue with your Powershell installation or Admin permissions."
            $ps2exe_installed = $false
        }
        if(!$ps2exe_installed){ # Still isn't installed? Let's just exit and prompt the user to manually install it.
            Write-Error "Couldn't install ps2exe, or couldn't verify it's installation."
            $null = Read-Host "Exiting script. You may need to manually install ps2exe on your Powershell.`nPress any key to continue..."
            Exit
        }
    }
    $ps2exe_installed
}

function Install-Script { # Create an exe from the provided webp-fix powershell script and "install" it to a folder of the user's choosing.
    $script:output_location = Read-Host -Prompt "Please enter a valid and full install directory (default: C:\Program Files\webp-fix)"
    if($output_location -eq ""){ # No input? Default option.
        $output_location =  "C:\Program Files\webp-fix"
    }
    ### TODO: How can we verify this is a valid path format without checking if it exists? Regex maybe?
    try { # Check if the location already exists.
        if(!(Test-Path -Path $output_location -PathType Container)){
            New-Item -Path $output_location -ItemType Directory -Force | Out-Null
        }
    }
    catch { # Catch any funky errors
        Write-Error "Couldn't read or create install directory."
    }
    $script:output_file = Join-path $output_location -ChildPath "webp-fix.exe" # Make this available script-wide so we can create the assoc later.
    if(Install-PS2EXE){ # Make sure PS2EXE is installed before running this.
        $input_file = Join-Path $PSScriptRoot -ChildPath "webp-fix.ps1" # get our script file from within the "install" folder
        if(!(Test-Path -path $input_file -PathType Leaf)){ # Let's make sure that the user has all the files needed in order. If not, exit immediately.
            Write-Error "webp-fix.ps1 Doesn't exist. Ensure your install folder contains it."
            $null = Read-Host "Exiting script. Press any key to continue..."
            Exit
        }
        try { # Try to create an exe file using ps2-exe.
            Invoke-ps2exe -inputfile $input_file -outputFile $output_file
        }
        catch {
            Write-Error "Couldn't create an EXE using ps2exe."
        }
    }
    else{ # This fires if no ps2exe exists.
        Write-Error "Couldn't verify if ps2exe is installed correctly."
        $null = Read-Host "Exiting script. Press any key to continue..."
        Exit
    }
    if(Test-Path -path $output_file -PathType Leaf){ # Check if we created the exe.
        Write-Host "Installed webp-fix.exe correctly."
        Add-InstallRegistry # Add a registry entry indicated that we completed the install correctly.
    }  
    else{ # Whoops, what happened? TODO: is it possible to fix this if something gets messed up along the install?
        Write-Error "It seems like webp-fix.exe wasn't installed correctly. Please verify your Program Files folder."
        $null = Read-Host -NoNewLine "Exiting script. Press any key to continue..."
        Exit
    }
}

function Add-InstallRegistry { # Add a registry entry to confirm that the program was installed and it's location
    try{
        
	    New-Item -Path $reg_path -Force
        New-ItemProperty -Path $reg_path -Name "Installed" -Value 1 -PropertyType DWORD -Force
        New-ItemProperty -Path $reg_path -Name "Location" -Value $output_location -PropertyType String -Force
    }
    catch{
        Write-Error "Couldn't create registry value(s)."
    }
}
function Add-AssocRegistry { # Add a registry entry to confirm that the program was associated with .webp
    try{
        New-itemProperty -Path $reg_path -Name "Assoc" -Value 1 -PropertyType DWORD -Force
    }
    catch{
        Write-Error "Couldn't create registry value."
    }
}
function Confirm-InstallRegistry { # Confirm a registry entry was already created (program installed successfully)
    try{
        Test-Path $reg_path
    }
    catch{
        Write-Host "Install Registry path not found. Continuing with installation."
        $False
    }
}

function Confirm-AssocRegistry{ # Confirm a registry entry was already created (assoc happened successfully)
    Get-Item $reg_path.Property -contains "Assoc" -ErrorAction SilentlyContinue
}
function Set-Assoc {
    $problem = $False
    # try to use assoc/ftype
    Write-Host "Trying command: cmd /c assoc .webp=webp"
    cmd /c assoc .webp=webp
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message "A problem occurred attempting to invoke command prompt."
        $problem = $True
    }
    $output_file_cmd = '"' + $output_file + '"'
    Write-Host "Trying command: cmd /c ftype webp=$output_file"
    cmd /c ftype webp=$output_file_cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "A problem occurred attempting to invoke command prompt."
        $problem = $True
    }
    if($problem) {
        #TODO: Try other method? for now, we will print an error and exit.
        Write-Error "Couldn't create a file association with webp-fix."
        $null = Read-Host "Exiting script. Press any key to continue..."
        Exit
    }
    else{
        Add-AssocRegistry
    }
}

if(Confirm-InstallRegistry -and Confirm-AssocRegistry){ # If our program has already been installed, and the file association has been created, that means the user just wants to change the cfg.
    Write-Host "Previous install found. Editing config..."
    Set-Cfg
}
else{ # Otherwise, it's our first time and we need to install and create a cfg.
    Install-Script
    Set-Assoc
    Set-Cfg
}
