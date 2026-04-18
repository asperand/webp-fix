$reg_path = "HKCU:\SOFTWARE\wepb-fix"
$install_location = Get-ItemPropertyValue -Path $reg_path -Name "Location"
if($?){ #If we can actually get the install location from the registry
    try{Remove-Item -path $install_location}
    catch{Write-Host "Issue removing install folder."}
}
try{Remove-Item -Path $reg_path -Force} # Clean up any created registry entries.
catch{Write-Host "Issue removing registry entry $reg_path."}

cmd /c ftype webp=
if ($LASTEXITCODE -ne 0) {
    Write-Host "A problem occurred attempting to remove ftype."
}
else{
    Write-Host "Removed ftype successfully"
}
cmd /c assoc .webp=
if ($LASTEXITCODE -ne 0) {
    Write-Host "A problem occurred attempting to remove assoc."
}
else{
    Write-Host "Removed assoc successfully"
}
