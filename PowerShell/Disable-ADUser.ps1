<#
	.SYNOPSIS
	1. Resets a user's password, clears the manager attribute, and hides the user in the global address list.
	2. Outputs a list of securitygroups the user currently belongs to, and adds the user to the Disabled Users security group, setting that as their primary group.
	3. Removes the user from all groups, moves them to the Disabled Users OU, and disables the account.
	
	.DESCRIPTION
	This script will automate the majority of a user account closure from the Active Directory side, and close down their account.
	
	.EXAMPLE
	.\Disable-ADUser.ps1 -DisabledUser dave.chigley
	This example will close down the user account dave.chigley in your Active Directory by following the steps in the synopsis.
	
	.PREREQUISITES
	Before running this script, you must create a security group in Active Directory with the same name you set in the $DisabledGroup parameter.
	Before running this script, you must specify the OU path for your own disabled users OU in the $TargetPath variable.
	
	.PARAMETER DisabledUser
	Stores the username of the user account to disables.
	
	.VARIABLE DisabledGroup
	Stores the name of the security group that the user will be assigned to.
	
	.VARIABLE NewPassword
	Stores the password that the user's account will be reset to.
	
	.VARIABLE ADGroup
	Used in conjunction with the $DisabledGroup parameter to assign the group as the Primary Group for the user.
	
	.VARIABLE TargetPath
	Specifies the path to the OU where the Disabled User will be moved to.
#>

# Setting parameters
	param(
		[Parameter(Mandatory=$true)][string]$DisabledUser
	)

# Declaring Variables
	$TargetPath = 'Disabled User OU path'
	$DisabledGroup = 'Disabled Users'
	
	$NewPassword = (Read-Host -Prompt 'Provide New Password' -AsSecureString)
	$ADGroup = get-adgroup $DisabledGroup -properties @('primaryGroupToken')

# Resetting password
	Set-ADAccountPassword -Identity $DisabledUser -NewPassword $NewPassword -Reset
	Write-Host "Password reset."
	
# Clearing the Manager attribute
	Set-ADUser $DisabledUser -clear manager
	Write-Host "Manager field cleared."

# Hiding the user in the Global Address List
	Set-ADUser $DisabledUser -replace @{msExchHideFromAddressLists=$true}
	Set-ADUser $DisabledUser -clear ShowinAddressBook
	Write-Host "$DisabledUser has been hidden from the global address list."

# Get list of groups the user is currently in
	Write-Host "Removing $DisabledUser from the following groups:"
	Get-ADUser $DisabledUser -Properties memberof | select -expand memberof | sort

# Adding user to $DisabledGroup and assigning this as primary group
	Add-ADGroupMember -Identity $ADGroup -Members $DisabledUser
	Get-ADUser $DisabledUser | set-aduser -replace @{primaryGroupID=$($ADGroup.primaryGroupToken)}
	Write-Host "$DisabledUser has been added to the $DisabledGroup group."

# Removing user from all other groups
	Get-ADPrincipalGroupMembership -Identity $DisabledUser | where {$_.Name -notlike $DisabledGroup} | % {Remove-ADPrincipalGroupMembership -Identity $DisabledUser -MemberOf $_ -Confirm:$false}

# Moving user to $TargetPath Outputs
	Get-ADUser $DisabledUser | Move-ADObject -TargetPath $TargetPath -Confirm:$false
	Write-Host "$DisabledUser has been moved to the Disabled Users OU."

# Ensuring removal of Domain Users group
	Remove-ADPrincipalGroupMembership -Identity $DisabledUser -MemberOf 'Domain Users' -Confirm:$false

# Disabling user account
	Disable-ADAccount -Identity $DisabledUser -Confirm:$false
