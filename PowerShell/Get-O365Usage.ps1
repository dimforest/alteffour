<#
  .SYNOPSIS
  Retrieves usage information (storage space used) for all Exchange Online mailboxes, OneDrive, and SharePoint sites in an Office 365 tenant
	
	.DESCRIPTION
	This script will pull the data specified in the synopsis, and store it in .csv files in a specified location. This could be set to run on a schedule to pull regular data for reporting i.e. depicting this usage data in Power BI or a similar application
	
	.EXAMPLE
	.\Get-O365UsageStats.ps1 -Credential ro.rulon@alteffour.com -LogPath C:\temp\O365Usage
	This example will connect to the three admin centres using my email address (login required), and then output the results to an O365Usage folder in C:\temp
	
	.PARAMETER Credential
	Stores the email address used to connect to the various sites and pull the data
	
	.PARAMETER LogPath
	Stores the path to the folder where you want the .csv files to be stored  
#>

# Setting Parameters
	param(
		[Parameter(Mandatory=$true)][string]$Credential,
		[Parameter(Mandatory=$true)][string]$LogPath
	)

#Declaring Variables
	$AdminSiteURL="URL of your SharePoint Admin Centre"
	$UMFN = "UserMailboxes.csv"
	$SMFN = "SharedMailboxes.csv"
	$ODFN = "OneDriveUsage.csv"
	$SPFN = "SPOUsage.csv"

#Checks that the $LogPath folder exists, and creates it if not
	if (!(test-path $LogPath)){
		Write-Host "Folder $LogPath not found. Creating folder for O365 Output files..." -ForegroundColor Black -BackGroundColor White
		New-item $LogPath -ItemType directory
	}

#Connect to Exchange Online
	Write-Host "Connecting to Exchange Online..." -ForegroundColor Black -BackGroundColor White
	Connect-ExchangeOnline -UserPrincipalName $ExchangeCredentials

#Get Active User Mailbox Stats and Output to CSV
	Write-Host "Getting User Mailbox Statistics. Output will be saved in $LogPath as $UMFN" -ForegroundColor DarkGreen -BackGroundColor Yellow
	Get-Mailbox -RecipientTypeDetails UserMailbox | Get-MailboxStatistics | Sort-Object -Property TotalItemSize -Descending | Select-Object DisplayName, ItemCount, TotalItemSize | Export-CSV -Path "$LogPath\$UMFN"

#Get Shared Mailbox Stats and Output to CSV
	Write-Host "Getting Shared Mailbox Statistics. Output will be saved in $LogPath as $SMFN" -ForegroundColor DarkGreen -BackGroundColor Yellow
	Get-Mailbox -RecipientTypeDetails SharedMailbox | Get-MailboxStatistics | Sort-Object -Property TotalItemSize -Descending | Select-Object DisplayName, ItemCount, TotalItemSize | Export-CSV -Path "$LogPath\$SMFN"

#Connect to SharePoint Online Admin Site
	Write-Host "Connecting to SharePoint Online..." -ForegroundColor Black -BackGroundColor White
	Connect-SPOService -Url $AdminSiteURL

#Get OneDrive Stats and Output to CSV
	Write-Host "Getting OneDrive Statistics. Output will be saved in $LogPath as $ODFN" -ForegroundColor DarkGreen -BackGroundColor Yellow
	Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" |
	Select Owner, StorageUsageCurrent | sort storageusagecurrent | Export-CSV -Path "$LogPath\$ODFN"

#Get SharePoint Stats and Output to CSV
	Write-Host "Getting SharePoint Site Statistics. Output will be saved in $LogPath as $SPFN" -ForegroundColor DarkGreen -BackGroundColor Yellow
	Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '.sharepoint.com/sites/'" | Select Title, StorageUsageCurrent | sort StorageUsageCurrent | Export-CSV -Path "$LogPath\$SPFN"
