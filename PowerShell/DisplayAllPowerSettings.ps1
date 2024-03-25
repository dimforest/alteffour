 #
 # Found on some Microsoft support forums where people complained that Power Settings were missing in the power plans definitions.
 #
 # Source: https://answers.microsoft.com/en-us/windows/forum/all/windows-10-unable-to-access-complete-power-options/4aa305ed-d788-4356-b7b5-9b752fdd0944
 #
 # This will display ALL the power settings, even those you absolutely don't need.
 #
 # Run this script in a PowerShell ISE that you launched with "Run as Admin", otherwise it won't work.
 #
 
$sting77 = "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
$querylist =  reg query $sting77

foreach ($regfolder in $querylist){
    $querylist2 = reg query $regfolder

    foreach($2ndfolder in $querylist2){
        $active2 = $2ndfolder -replace "HKEY_LOCAL_MACHINE" , "HKLM:"
        Get-ItemProperty -Path $active2
        Set-ItemProperty -Path "$active2" -Name "Attributes" -Value '2'
    }

    $active = $regfolder -replace "HKEY_LOCAL_MACHINE" , "HKLM:"
    Get-ItemProperty -Path $active
    Set-ItemProperty -Path "$active" -Name "Attributes" -Value '2'
}