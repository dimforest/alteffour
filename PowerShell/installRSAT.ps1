$RSATFeatures = (
    "Rsat.ServerManager.Tools~~~~0.0.1.0",
    "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0",
    "Rsat.Dns.Tools~~~~0.0.1.0",
    "Rsat.DHCP.Tools~~~~0.0.1.0",
    "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
)

foreach ($feature in $RSATFeatures) {
    If ((Get-WindowsCapability -Online -Name $feature).State -ne "Installed") {
        Write-Output "$feature not found, installing..."
        Add-WindowsCapability -online -name $feature
    }
}

Write-Output "Done, all required features found or installed."
