<#
.SYNOPSIS
This script facilitates the termination process for employees in a cloud environment, focusing on Microsoft Graph and Exchange Online operations.

.DESCRIPTION
The script offers a menu-driven interface to perform various tasks related to terminating an employee's access and managing their mailbox in a cloud environment. 
It connects to Microsoft Graph and Exchange Online to execute tasks such as removing the user from groups, clearing their mailbox from mobile devices, converting their mailbox, and more.

.REQUIREMENTS
- This script requires the ExchangeOnlineManagement module to be installed. You can install it using the following command:
  Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber

- Ensure that you have appropriate permissions to connect to Microsoft Graph and Exchange Online and perform the necessary operations.
-- Note: I understand that storing credential like this inside of the script is not ideal. It's better than typing the full email address each time.

- Make sure to enter your credentials in the specified section within the script before running it. See Line 33.

.NOTES
Author: gOyDp
Date: 2024-03-25
Version: 1.0
#>

####### Function to catch errors
######
function Handle-Error {
    param (
        [string]$ErrorMessage
    )
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
}

###### Use this section to enter your credentials for the script.
######
$global:domainName = "DOMAIN.com"
$global:yourUsername = "adminUsername"
$global:TenantId = "NNN-TENANTID-NNN"
$global:yourUPN = ($yourUsername, $domainName) -join "@";

###### Setting the variables to be used later. 
######
$global:disabledUser = $null
$global:disabledUserUPN = $null
$global:MgUser = $null
$global:MgUserId = $null
$global:MgUserDisplayName = $null
$global:scriptTitle = 'Terminate Employee From Cloud Environment'

###### This will get the username of the user who is going to be terminate and then build the UPN.
######
function Get-UserDetails {
    
    Clear-Host
    Write-Host "================ $global:scriptTitle ================" -ForegroundColor Magenta
    Write-Host ""
    
$global:disabledUser = (Read-Host -Prompt 'Enter the username of the employee being terminated')
$global:disabledUserUPN = ($global:disabledUser, $global:domainName) -join "@";
}

###### This is a function to get the user object, Id and Display Name for that username that was entered.
######
function Get-MgUserDetails {
    
        try {
        $global:MgUser = Get-MgUser -Filter "userPrincipalName eq '$global:disabledUserUPN'"
        $global:MgUserId = $global:MgUser.id
        $global:MgUserDisplayName = $global:MgUser.DisplayName
            } catch {
        Handle-Error -ErrorMessage "Failed to retrieve user information. $_"
        return
            }
}

##### Run the functions Get-UserDetails and Get-MgUserDetails
#####
Get-UserDetails
Get-MgUserDetails

###### Function 1: This is used to connect to MgGraph and ExchangeOnline.
###### 
function Connect-MgGraphAndExchangeOnline {
    [CmdletBinding()]
    param (
        [string[]]$Scopes = @("User.ReadWrite.All", "Group.ReadWrite.All"),
        [switch]$UseDeviceAuthentication
    )

    $scopesString = $Scopes -join ','
    $mgGraphCommand = "Connect-MgGraph -Scopes `"$scopesString`" -TenantId `"$($global:TenantId)`" -NoWelcome"
    $exchangeOnlineCommand = "Connect-ExchangeOnline -UserPrincipalName $($global:yourUPN)"

    if ($UseDeviceAuthentication) {
        $mgGraphCommand += " -UseDeviceAuthentication"
    }

    # Connect to Exchange Online
    Invoke-Expression $exchangeOnlineCommand

    # Connect to MgGraph
    Invoke-Expression $mgGraphCommand

    Write-Host "Connected to Microsoft Graph with scopes: $scopesString" -ForegroundColor Blue
    Write-Host "Connected to Exchange Online as user: $($global:yourUPN)" -ForegroundColor Green
    Write-Host ""
}

###### Function 2: Get list of mobile devices associated with the user. Ask if you want to clear the account.
######  
function Clear-MailboxFromMobileDevices {
    $mobileDevices = Get-MobileDevice -Mailbox $global:disabledUserUPN | Select-Object FriendlyName, DeviceAccessState, Guid

    $menuOptions = @()

    for ($i = 0; $i -lt $mobileDevices.Count; $i++) {
        $menuOptions += New-Object PSObject -Property @{
            Number = $i + 1
            FriendlyName = $mobileDevices[$i].FriendlyName
            Guid = $mobileDevices[$i].Guid
        }
    }

    $menuOptions += New-Object PSObject -Property @{
        Number = $menuOptions.Count + 1
        FriendlyName = "Clear account from all devices"
        Guid = $null
    }

    $selectedOption = $menuOptions | Out-GridView -Title "Select a mobile device" -PassThru

    if ($null -eq $selectedOption) {
        Write-Host "No option selected. Exiting..."
        return
    }
    elseif ($selectedOption.Guid -eq $null) {
        $mobileDevices | ForEach-Object {
            Clear-MobileDevice -Identity $_.Guid -AccountOnly
        }
    }
    else {
        Clear-MobileDevice -Identity $selectedOption.Guid -AccountOnly
    }
}

###### Function 3: This is intended to remove the user from any groups, excluding distribution groups.
######
function RemoveUserFromGroups {

    try {
        $disabledUsersGroups = Get-MgUserMemberOf -UserId $global:MgUserId | Where-Object { $_.groupTypes -notcontains "DynamicMembership" }
    } catch {
        Handle-Error -ErrorMessage "Failed to retrieve user's group memberships. $_"
        return
    }

    # Remove the user from all groups
    foreach ($group in $disabledUsersGroups) {
        try {
            Remove-MgGroupMemberByRef -GroupId $group.id -DirectoryObjectId $global:MgUserId
            Write-Host "Removed user from $($group.displayName)" -ForegroundColor Green
        } catch {
            Handle-Error -ErrorMessage "Failed to remove user from $($group.displayName). $_"
        }
    }
}

##### Function 4: This will ask if you need to convert the mailbox and grant access. 
#####
function Convert-MailboxAndGrantAccess {

    ##### Ask which option you'd like to complete. 
    #####
    Write-Host "================ User Mailbox Functions ================" -ForegroundColor Magenta
    Write-Host "Select an option below:"
    Write-Host "1: Convert mailbox to shared and grant access"
    Write-Host "2: Convert mailbox but do NOT grant access"
    Write-Host "3: Do not convert or grant access"

    $option = Read-Host "Enter your choice (1/2/3):"

    # Process the user's choice
    switch ($option) {
        '1' {
            ##### Convert mailbox to shared
            try {
                Write-Host "Converting mailbox to shared..." -ForegroundColor Green
                Set-Mailbox $global:disabledUserUPN -Type Shared -ErrorAction Stop
                Write-Host "Mailbox converted successfully." -ForegroundColor Green
            } catch {
                Handle-Error -ErrorMessage "Failed to convert mailbox to shared. $_"
                return
            }

            ##### Show mailbox status
            Get-Mailbox -Identity $global:disabledUserUPN | Format-List DisplayName, RecipientTypeDetails

            ##### Add mailbox access
            try {
                Write-Host "Granting full access to the shared mailbox..." -ForegroundColor Green
                $userReceivingAccess = Read-Host -Prompt "Enter the username of the user receiving access"
                Add-MailboxPermission -Identity $global:disabledUserUPN -User $userReceivingAccess -AccessRights FullAccess -InheritanceType All -Automapping $false -ErrorAction Stop
                Write-Host "Full access granted successfully to $userReceivingAccess." -ForegroundColor Green
                Write-Host "Here is the URL... https://outlook.office.com/mail/$global:disabledUserUPN"
            } catch {
                Handle-Error -ErrorMessage "Failed to grant access to $userReceivingAccess. $_"
            }
            break
        }
        '2' {
            ##### Convert mailbox to shared without granting access
            try {
                Write-Host "Converting mailbox to shared..." -ForegroundColor Green
                Set-Mailbox $global:disabledUserUPN -Type Shared -ErrorAction Stop
                Write-Host "Mailbox converted successfully." -ForegroundColor Green
            } catch {
                Handle-Error -ErrorMessage "Failed to convert mailbox to shared. $_"
                return
            }
            break
        }
        '3' {
            # Exit the function
            Write-Host "No action taken. Exiting..."
            break
        }
        default {
            Write-Host "Invalid option. Please select a valid option (1/2/3)."
            break
        }
    }
}

##### Function 5: This should remove the user from any Exchange Online email groups.
#####
function Remove-UserFromEmailGroups {

    try {
        # Connect to Exchange Online
        Connect-ExchangeOnline -UserPrincipalName $global:disabledUserUPN -ErrorAction Stop

        # Get the user's mailbox
        $mailbox = Get-EXOMailbox -Identity $global:disabledUserUPN -ErrorAction Stop

        # Get all the distribution groups the user is a member of
        $distributionGroups = Get-EXOMailbox -Identity $mailbox.Identity | Get-EXOMailboxMembership -ErrorAction Stop

        # Remove the user from each distribution group
        foreach ($group in $distributionGroups) {
            try {
                Remove-EXOMailboxMember -Identity $group.Identity -Member $mailbox.Identity -Confirm:$false -ErrorAction Stop
                Write-Host "Removed user from $($group.DisplayName)" -ForegroundColor Green
            } catch {
                Handle-Error -ErrorMessage "Failed to remove user from $($group.DisplayName). $_"
            }
        }
    } catch {
        Handle-Error -ErrorMessage "Failed to remove user from Exchange Online email distribution groups. $_"
    }
}

###### Function 6: This will restore the user from Deleted Users and then clear the immutableId. 
###### *** Only run this after you have deleted the user from AD and synced them. ***
###### 
function clearImmutableId {

    try {
        # Restore the deleted user with a random password
        $RandomPassword = -join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
        $User = Get-MgUser -Filter "UserPrincipalName eq '$global:disabledUserUPN'" -All -ErrorAction Stop
        if ($User.UserPrincipalName -and $User.DeletedDateTime) {
            $UserToRestore = Restore-MgUser -UserId $User.Id -PasswordProfile @{Password = $RandomPassword} -ErrorAction Stop
            Write-Host "User $($UserToRestore.UserPrincipalName) has been restored with a random password."
        } else {
            Write-Host "User $global:disabledUserUPN is not in the deleted users list."
        }

        # Wait for 2 seconds
        Start-Sleep -Seconds 2

        # Clear the Immutable ID
        $UserId = (Get-MgUser -Filter "UserPrincipalName eq '$global:disabledUserUPN'").Id
        $Body = @"
{
    "onPremisesImmutableId":null
}
"@
        $Uri = "https://graph.microsoft.com/v1.0/users/$UserId"
        Invoke-MgGraphRequest -Method PATCH -Uri $Uri -Body $Body -ErrorAction Stop
        Write-Host "Immutable ID cleared for $global:disabledUserUPN."
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }
}

##### Function 7: This will hide the mailbox from the GAL.
#####
function HideMailbox {
    try {
        Set-Mailbox $MailboxUPN -HiddenFromAddressListsEnabled $true -ErrorAction Stop
        Write-Host "Mailbox ($MailboxUPN) hidden from the Global Address List successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to hide the mailbox ($MailboxUPN) from the Global Address List. Error: $_" -ForegroundColor Red
    }
}

###### This is the function to handle the menu.
###### 
function Show-Menu {
    ##### Remove the comment marker if you want the menu to clear the console each time you come to the menu. 
    #Clear-Host
    Write-Host "================ $scriptTitle ================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "User being terminated: $global:MgUserDisplayName" -ForegroundColor Blue
    Write-Host "Username: $global:disabledUserUPN" -ForegroundColor Green
    Write-Host "User ID: $global:MgUserId" -ForegroundColor Green
    Write-Host ""
    Write-Host "1: Connect to Graph and Exchange Online"
    Write-Host "2: Remove account from mobile devices"
    Write-Host "3: Remove User From Groups"
    Write-Host "4: Convert Mailbox and Grant Access"
    Write-Host "5: Remove user from email groups"
    Write-Host "6: Clear Immutable Id"
    Write-Host "7: Hide mailbox from Address Book"
    Write-Host "8: Run all functions, except clearImmutableId and HideMailbox"
    Write-Host "Q: Quit"
}

###### Main loop to complete the functions based on the selection made in the menu.
######
do {
    Show-Menu
    $selection = Read-Host "Please select a task"
    switch ($selection) {
        '1' {
            Connect-MgGraphAndExchangeOnline
            Pause
        }
        '2' {
            Clear-MailboxFromMobileDevices
            Pause
        }
        '3' {
            RemoveUserFromGroups
            Pause
        }
        '4' {
            Convert-MailboxAndGrantAccess
            Pause
        }
        '5'{
            Remove-UserFromEmailGroups
            Pause
        }
        '6'{
            clearImmutableId
            Pause
        }
        '7'{
            HideMailbox
            Pause
        }
        '8'{
            Connect-MgGraphAndExchangeOnline
            Clear-MailboxFromMobileDevices
            RemoveUserFromGroups
            Convert-MailboxAndGrantAccess
            Remove-UserFromEmailGroups
            Write-Host "All functions, except clearImmutableId and HideMailbox, executed successfully."
            Pause
        }
        'q' {
            return
        }
    }
} until ($selection -eq 'q')