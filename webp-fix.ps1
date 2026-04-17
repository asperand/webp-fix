### TODO: This will be an exe where files will be opened with it. How can we get the file that is being opened with it?
### TODO: How can we tell if a file has certain properties (i.e. animation -> gif, transparency -> png)
function Read-WebpFile{ # Get the file that the program was opened with.
    $file_path = $args[1]
    $file_stream = [System.IO.File]::OpenRead($file_path)
    $header_buf = New-Object byte[] 20
    $bytes_read = $file_stream.Read($header_buf, 0, $header_buf.Length)
    $header_type_as_bytes = $header_buf[12..15] #Trim data stream to just the header type
    $header_type = [System.Text.Encoding]::UTF8.GetString($header_type_as_bytes) # Convert to string (UTF8)
    switch($header_type){
        "VP8 "{ # VP8 is lossy and does not require transparency. Check in on the CFG to see if we can convert to JPG, then make the conversion.
            $file_stream.Close() # Close fs to make sure we can rename the file
            Get-ChildItem $file_path | Rename-Item -NewName {$_.Basename + $vp8_opt}
        } 
        "VP8L"{ # VP8L is lossless, and could have transparency. but if the user still wants a JPG, we can abide by these wishes.
            $file_stream.Close()
            Get-ChildItem $file_path | Rename-Item -NewName {$_.Basename + $vp8l_opt}
        } 
        "VP8X" { # We need to do some extra work on this header to determine if it's animated. Otherwise, we can convert this into a PNG.
            $vp8x_data = $header_buf[16] # Grab this byte for info. 
            $vp8x_data_as_str = [System.Convert]::ToString($vp8x_data, 2).PadLeft(8, '0') # I tried doing -band -shl with this, but it didn't seem to work. TODO: I'll come back to this and actually do this bitwise rather than this quick and dirty string stuff.
            if($vp8x_data_as_str[6] -eq "1"){ # Is the anim bit set?
                $file_stream.Close()
                if($vp8x_gif_opt){ # Did the user enable gif saving for animated images?
                    Get-ChildItem $file_path | Rename-Item -NewName {$_.Basename + ".gif"}
                }
                else{ # If not, save as whatever their option is.
                    Get-ChildItem $file_path | Rename-Item -NewName {$_.Basename + $vp8x_opt}
                }
            }
            else{ # This fires when the VP8X does not have the animation flag on. Saves as whatever their option is for VP8X.
                $file_stream.Close()
                Get-ChildItem $file_path | Rename-Item -NewName {$_.Basename + $vp8x_opt}
            }

        } 
    }
}

function Read-Cfg { # Load our cfg options into memory
    try{$local:cfg_file = Get-Content "config.cfg"}
    catch{ # default if can't get file
        $script:vp8_opt = ".jpg"
        $script:vp8l_opt = ".png"
        $script:vp8x_gif_opt = $true
        $script:vp8x_opt = ".png"
    }
    $cfg_lines = $cfg_file -split '\r?\n' 
    $cfg_options = $cfg_lines | ForEach-Object{$_.Split('=')[1]}
    $script:vp8_opt = $cfg_options[0]
    $script:vp8l_opt = $cfg_options[1]
    $script:vp8x_gif_opt = [System.Convert]::ToBoolean($cfg_options[2])
    $script:vp8x_opt = $cfg_options[3]
}

Read-Cfg
Read-WebpFile

