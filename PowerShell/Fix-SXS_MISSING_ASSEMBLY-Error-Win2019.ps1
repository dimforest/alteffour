<#
.SYNOPSIS
  
  This script will fix the SXS assmbly missing issue while installing feature
.DESCRIPTION
  
  The script mark the resolved packages absent which are missing manifest.
.PARAMETER 
    Provide CBS file path
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in current working directory  "AssemblyMissingScript-" + [datetime]::Now.ToString("yyyyMMdd-HHmm-ss") + ".log")>
.NOTES
  Version:        1.0
  Author:         Abhinav Joshi
  Creation Date:  14/11/2020
  Purpose/Change: Initial script development
  
.EXAMPLE
  
  Run the script ERROR_SXS_ASSEMBLY_MISSING.ps1
  Please enter CBS file path (Default Path: c:\windows\logs\cbs\cbs.log): C:\windows\Logs\cbs\cbs2.log
#>
function enable-privilege {
    param(
        ## The privilege to adjust. This set is taken from
        ## http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
        [ValidateSet(
            "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
            "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
            "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
            "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
            "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
            "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
            "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
            "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
            "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
            "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
            "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
        $Privilege,
        ## The process on which to adjust the privilege. Defaults to the current process.
        $ProcessId = $pid,
        ## Switch to disable the privilege, rather than enable it.
        [Switch] $Disable
    )
    ## Taken from P/Invoke.NET with minor adjustments.
    $definition = @'
 using System;
 using System.Runtime.InteropServices;
  
 public class AdjPriv
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
   ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
  {
   bool retVal;
   TokPriv1Luid tp;
   IntPtr hproc = new IntPtr(processHandle);
   IntPtr htok = IntPtr.Zero;
   retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
   tp.Count = 1;
   tp.Luid = 0;
   if(disable)
   {
    tp.Attr = SE_PRIVILEGE_DISABLED;
   }
   else
   {
    tp.Attr = SE_PRIVILEGE_ENABLED;
   }
   retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
   retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
   return retVal;
  }
 }
'@
    $processHandle = (Get-Process -id $ProcessId).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
}
$logfile = [System.IO.Path]::Combine($rootDir, "AssemblyMissingScript-" + [datetime]::Now.ToString("yyyyMMdd-HHmm-ss") + ".log")
if (-not (Test-Path "$PWD\logs")) {
    New-Item -Path "$PWD\logs" -ItemType Directory -Verbose
}
Start-Transcript -Path "$PWD\logs\$logfile"
$cbspathTEMP = Read-Host -Prompt "Please enter CBS file path (Default Path: c:\windows\logs\cbs\cbs.log)"
$cbspath = $cbspathTEMP.Replace('"','')
write-host  ""
write-host -ForegroundColor Yellow $cbspath
if ($cbspath -eq $null -or $cbspath.Length -eq "0"){
    
    Write-Host -ForegroundColor Yellow "No path was entered"
        
    Write-Host "Setting up default CBS path"
    $cbspath = "c:\Windows\Logs\CBS\CBS.log"
    Write-Host -ForegroundColor Cyan $cbspath
}
$CheckingpackagesResolving = "Resolving Package:"
$checkingFailure = Get-Content $CBSpath | Select-String "ERROR_SXS_ASSEMBLY_MISSING"
    if ($checkingFailure -ne $null -and $CheckWhichFeature -ne 0) {
            Write-Host "Checking resolving packages"
            $CBSlines = Get-Content $CBSpath | Select-String $CheckingpackagesResolving
            $Result = @()
            if ($CBSlines) {
                foreach ($CBSline in $CBSlines) {
                    $packageLine = $CBSline | Out-String
                    $package = $packageLine.Split(":").Trim().Split(',').Trim() | Select-String "Package_"
                    $Result += $package
                }
                Write-host "Found following resolving packages"
                $Results = $Result | Select-Object -Unique
                foreach ($regpackage in $Results) {
                    $bb = "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$regpackage"
                    $uname = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                    enable-privilege SeTakeOwnershipPrivilege 
                    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($bb, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::takeownership)
                    # You must get a blank acl for the key b/c you do not currently have access
                    $acl = $key.GetAccessControl([System.Security.AccessControl.AccessControlSections]::None)
                    $me = [System.Security.Principal.NTAccount]$uname
                    $acl.SetOwner($me)
                    $key.SetAccessControl($acl)
                    # After you have set owner you need to get the acl with the perms so you can modify it.
                    $acl = $key.GetAccessControl()
                    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ($uname, "FullControl", "Allow")
                    $acl.SetAccessRule($rule)
                    $key.SetAccessControl($acl)
                    $key.Close()  
                    Write-Host "Mark this package absent $regpackage"
                    Set-ItemProperty -Path "HKLM:\$bb" -Name Currentstate -Value 0 -Type DWord -Force
                }
                Write-host "Verifying package state"
                $Verifcationcheckvalue = "1"
                foreach ($Regpackagecheck in $Results) {
                
                    $CurrentstateOfpackage = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Regpackagecheck").CurrentState
    
                    if ($CurrentstateOfpackage -eq "0") {
                    
                        Write-host -ForegroundColor Green  $CurrentstateOfpackage of $Regpackagecheck
                        $Verifcationcheckvalue += "1"
        
                    }
                    else {
                        Write-host -ForegroundColor red  $CurrentstateOfpackage of $Regpackagecheck
                        $Verifcationcheckvalue += "0"
                    }
                }    
                if ($Verifcationcheckvalue -notmatch "0") {
                    
                    write-host "========================================================================="
                    write-host ""
                    Write-host -f white -BackgroundColor green "Verification passed, Retry Enabled"
                    write-host ""
                    write-host "========================================================================="
                    $Global:try = $true
                }
                else {
                    write-host "========================================================================="
                    write-host ""
                    write-host -f white -BackgroundColor Red "Verification Failed, Can't contiune. Collect $logfile and CBS.log"
                    write-host ""
                    write-host "========================================================================="
                    $Global:try = $false
                }
            }
            else {
                Write-Error "Error while finding resolving packages"
            }
        }
    else {
            Write-Host "Looks like $CBSpath is not right CBS File, check manually. "
        }
stop-Transcript
pause