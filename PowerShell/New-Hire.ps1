<# 
    .SYNOPSIS
    Create new AD User from information provided.

    .DESCRIPTION
    This script creates a new user using information provided at the command-line as well as prompted information.  It sets the ProxyAddresses information as well as Department, Manager, Password, Email Address, and Username.
    The prompted information is requested via two lists; one for manager name and the other for department.

    .EXAMPLE
    .\New-Hire.ps1 -FirstName John -LastName Doe -Title "Test User" -Company "Widgets R Us"
    This example creates a new user named John Doe with a title of "Test User" for the company "Widgets R Us"

    .PARAMETER FirstName
    Stores the new user's first name

    .PARAMETER LastName
    Stores the new user's last name

    .PARAMETER Title
    Stores the new user's title

    .PARAMETER Company
    Stores the new user's company name

#>

# Set employee AD info
    param(
        [Parameter(Mandatory=$true)][string]$FirstName,
        [Parameter(Mandatory=$true)][string]$LastName,
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$false)][string]$Company = "Default Company Name"
    )

# Create User Name
    $UserName = $FirstName.ToLower() + "." + $LastName.toLower()

# Set Initial password
    $Pass = read-host -AsSecureString "Please type the new user's initial password: "
    
# Create Email
    $EmailDomain = "@emaildomain.com"
    $Email = $UserName + $EmailDomain

# Display department list
    [int]$xMenuChoiceA = 0
    while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 10 ){
    # set this greater than number to the number of options listed
    Write-host "1. Accounting"
    # duplicate as needed

# Prompt for department
    [Int]$xMenuChoiceA = read-host "Please choose new user's department:" }
    Switch( $xMenuChoiceA ){
        1{$Department = "Accounting"; $TargetOU = "path to department OU"}
        # Duplicate the above line for as many departments as you listed
    }

# Prompt for manager

    [Int]$xMenuChoiceB = 0
    while ( $xMenuChoiceB -lt 1 -or $xMenuChoiceB -gt 1 ) {
        # set this greater than number to the number of options listed
        write-host "1 - Boss man"
        # duplicate as needed

    [Int]$xMenuChoiceB = read-host "Please choose the new user's manager:"}
    switch ( $xMenuChoiceB ) {
        1{$Manager = "Boss Man UPN"}
        # Duplicate the above line for as many managers as you listed
    }

# Create New User in Active Directory
    write-host "Creating new AD User $UserName..."
    New-ADUser -SamAccountName $UserName -AccountPassword $Pass -GivenName $FirstName -Surname $LastName -CannotChangePassword 0 -ChangePasswordAtLogon 1 -Department $Department -Company $Company -EmailAddress $Email -Enabled 1 -ScriptPath $UserName -Name ($FirstName, $LastName -Join " ") -DisplayName ($FirstName, $LastName -Join " ") -UserPrincipalName $Email -Title $Title -Manager $Manager -Path $TargetOU

# Set ProxyAddress
    Write-Host "Setting ProxyAddresses attribute..."
    $user = Get-ADUser -Identity $UserName -Properties SamAccountName, EmailAddress, ProxyAddresses
    $user.ProxyAddresses.add("SMTP:$Email")
    Set-ADUser -Instance $user
    
# Add user to appropriate group membership
    Write-Host "Setting security group membership..."
    Add-ADGroupMember -Identity "Dept - $Department" -Members $UserName


    Write-Host "Don't forget to check/verify user is in correct departmental OU"

 
# Notify Manager of email creation
#    Send-MailMessage -to "dave.kay@baronweather.com" -Subject ("IT Setup Complete for " + $Firstname + " " + $Lastname) -body ("IT Setup is complete for " + $Firstname + " " + $Lastname + " as a " + $Title +" in the " + $Department + " " + "Department." + "`r`n`n") -smtpserver vortex.baronservices.com -from it-dept@baronweather.com
