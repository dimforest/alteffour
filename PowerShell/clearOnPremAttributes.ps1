<#
.SYNOPSIS
    Clears on-premises sync attributes from a Microsoft 365 user.

.DESCRIPTION
    This script uses the ADSyncTools module to clear on-premises sync attributes,
    including onPremisesImmutableId, and then checks that they were cleared
    using Microsoft Graph. It is used when you migrate an account from ADUC synced to only Entra. 

.REQUIREMENTS
    - *** YOU MUST PUT YOUR DOMAIN NAME IN LINE 28. 
    - ADSyncTools module must be installed and imported.
    - Microsoft.Graph module must be installed and connected via Connect-MgGraph.

.NOTES
    Author: gOyDp
    Date: 5/8/2025
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Username
)

Write-Host "Importing ADSyncTools..."
Import-Module ADSyncTools

$upn = "$Username@REPLACETHISDOMAIN.com"

Write-Host "Clearing attributes for $upn..."
try {
    Clear-ADSyncToolsOnPremisesAttribute -Identity $upn -All
    Write-Host "✔️ OnPremises attributes cleared successfully."
} catch {
    Write-Error "❌ Failed to clear attributes: $_"
    exit
}

Write-Host "Checking attributes for $upn..."
try {
    $user = Get-MgUser -UserId $upn -Select "OnPremisesImmutableId"
    if (-not $user.OnPremisesImmutableId) {
        Write-Host "✔️ onPremisesImmutableId is cleared."
    } else {
        Write-Warning "⚠️ onPremisesImmutableId is still set: $($user.OnPremisesImmutableId)"
    }
} catch {
    Write-Error "❌ Failed to retrieve user: $_"
}
