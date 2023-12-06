#Authenticate access with user-assigned managed identity
Write-Output "Connecting to azure via  Connect-AzAccount"  
Connect-AzAccount -Identity -AccountId '63e8121f-2c23-4db6-91bb-214b76db23fc' -subscription 'CIS-Technion (EA)'
$secret = Get-AzKeyVaultSecret -VaultName 'cis-key' -Name 'iis-oauthSe'
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)  
try {  
  $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)  
} finally {  
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)  
} 


#Connect to MgGraph
$ApplicationId = "2be7d2f1-df99-48b8-b185-f00d005d241b"
$SecuredPassword = $secretValueText
$tenantID = "f1502c4c-ee2e-411c-9715-c855f6753b84"

$SecuredPasswordPassword = ConvertTo-SecureString `
-String $SecuredPassword -AsPlainText -Force

$ClientSecretCredential = New-Object `
-TypeName System.Management.Automation.PSCredential `
-ArgumentList $ApplicationId, $SecuredPasswordPassword

Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential

####

$a= Get-MgUser -Filter "assignedLicenses/`$count eq 0 and userType eq 'Member'" -ConsistencyLevel eventual -CountVariable unlicensedUserCount -All
$unlicensed = $a | ? { $_.UserPrincipalName -like '*@technion.ac.il' } 
$NonUsageLocation= Get-MgUser -Select Id,DisplayName,Mail,UserPrincipalName,UsageLocation,UserType | where { $_.UsageLocation -eq $null -and $_.UserType -eq 'Member' }
$count= $unlicensed.count
Write-Output "Unlicense count = $count"
$count2= $NonUsageLocation.count
Write-Output "NonUsageLocation count = $count2"

#$fabricFreeId= 'a403ebcc-fae0-4ca2-8c8c-7a907fd6c235'
 #$skuidA1= '78e66a63-337a-4a9a-8959-41c6654dfb56'
#$mgUser = Get-MgUser -UserId "kristina.m@technion.ac.il" -Property AssignedLicenses

foreach ($staffuser in $unlicensed) {
	#set Licenses
     # Set-MsolUser -UserPrincipalName $staffuser.UserPrincipalName -UsageLocation IL
    #Set-MgUserLicense -UserId $staffuser.UserPrincipalName -AddLicenses $mgUser.AssignedLicenses -RemoveLicenses @()
    Update-MgUser -UserId $staffuser.UserPrincipalName -UsageLocation "IL"
    Set-MgUserLicense -UserId $staffuser.UserPrincipalName -AddLicenses @{SkuId = "78e66a63-337a-4a9a-8959-41c6654dfb56"} -RemoveLicenses @() #A1
    Set-MgUserLicense -UserId $staffuser.UserPrincipalName -AddLicenses @{SkuId = "a403ebcc-fae0-4ca2-8c8c-7a907fd6c235"} -RemoveLicenses @() #fabricFreeId
     Write-Output "Add Staff Licenses to $($staffuser.UserPrincipalName)";
}

#set-MgUserLicense -UserId 'kristina.m@technion.ac.il' -AddLicenses @{SkuId = "a403ebcc-fae0-4ca2-8c8c-7a907fd6c235"} -RemoveLicenses @()


