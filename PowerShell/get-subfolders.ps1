# Specify the root directory
$rootDir = "D:\path\to\parent"

# Specify the output file path
$outputFile = "C:\Outputs\subfolders.txt"

# Get all subfolders that are three levels deep
$subfolders = Get-ChildItem -Path $rootDir -Directory -Recurse | Where-Object { 
    ($_.FullName.TrimEnd('\') -replace [regex]::Escape($rootDir), "").Split('\').Count -eq 3 
}

# Output only the names of the subfolders to a text file
$subfolders | ForEach-Object { $_.Name } | Out-File -FilePath $outputFile -Encoding UTF8

# Optional: Display a message confirming the operation
Write-Host "Subfolder names have been saved to $outputFile"