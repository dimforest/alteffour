param(
    [Parameter(Mandatory=$true)][string]$ProgramName,
    [Parameter(Mandatory=$false)][string]$ComputerName
    )

if ([string]::IsNullOrEmpty($ComputerName)) {
    $ComputerName = $env:COMPUTERNAME
}
if (test-connection -ComputerName $ComputerName -Quiet) {
    
    get-wmiobject Win32_Product -ComputerName $ComputerName | Where-Object {$_.Name -like "*$ProgramName*"} | Format-Table IdentifyingNumber,Name,Version
    
} else {
    Write-Host "$ComputerName is offline"
}
