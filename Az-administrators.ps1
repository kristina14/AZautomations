#Authenticate access with user-assigned managed identity
Write-Output "Connecting to azure via  Connect-AzAccount"  
Connect-AzAccount -Identity -AccountId '63e8121f-2c23-4db6-91bb-214b76db23fc' -subscription 'CIS-Technion (EA)'
$secret = Get-AzKeyVaultSecret -VaultName 'cis-key' -Name 'CIS-AutomationSec'
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)  
try {  
  $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)  
} finally {  
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)  
} 


#Connect to MgGraph
$ApplicationId = "08c8a8d2-c768-4a47-b8a1-ab195cf59ab8"
$SecuredPassword = $secretValueText
$tenantID = "f1502c4c-ee2e-411c-9715-c855f6753b84"

$SecuredPasswordPassword = ConvertTo-SecureString `
-String $SecuredPassword -AsPlainText -Force

$ClientSecretCredential = New-Object `
-TypeName System.Management.Automation.PSCredential `
-ArgumentList $ApplicationId, $SecuredPasswordPassword

Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential

####

<#
#Connect to Microsoft Graph
Connect-MgGraph -Scopes RoleManagement.Read.Directory, User.Read.All, AuditLog.Read.All 
Select-MgProfile $cred
#>


$user= Get-MgUser -UserId "1a7555e5-388b-4d1c-ae96-55a55278643e"
$upn= $user.userPrincipalName
write-output "UPN is: $upn"


#Get all directory roles
$allroles = Get-MgDirectoryRole 
$allrolescount= $allroles.count
write-output "Count of allroles: $allrolescount"

#Provision in new array object
$Report = [System.Collections.Generic.List[Object]]::new()

#Start a loop to build the report
Foreach ($role in $allroles){
    $rolemembers = $null
    #Get members of each role
    $Rolemembers = Get-MgDirectoryRoleMember -DirectoryRoleId $Role.id
    #Skip role if role assignments are empty
    If ($Rolemembers -eq $null) 
        {Write-host "No users assigned to $($Role.DisplayName)"} 
         Else {
             Foreach ($Member in $rolemembers){
                #Filter out non-user assignments
                    If ($member.AdditionalProperties.'@odata.type' -notmatch "servicePrincipal") {
                        $SignInActivity = $null
                        #Get signin logs for user
                        $SignInActivity = Get-MgUser -UserId $member.id -Property signinactivity | Select-Object -ExpandProperty signinactivity
                        #Build current array object
                        $obj = [pscustomobject][ordered]@{
                            Role                     = $Role.DisplayName
                            User                     = $member.AdditionalProperties.displayName
                            Username                 = $member.AdditionalProperties.userPrincipalName
                            LastInteractiveSignIn    = $SignInActivity.LastSignInDateTime
                        }
                        #Add current array object to the report
                        $report.Add($obj)
                    }
                }
    }
}

$count= $report.count
write-output "Count of report: $count"


#Export report to csv
#$report | Export-CSV -path C:\temp\AZ-Admins.csv -NoTypeInformation -Encoding utf8 -Force
$report | Export-CSV -path AZ-Admins.csv -NoTypeInformation -Encoding utf8 -Force

#format and export
<#
$report = foreach ($key in ($RolesHash.Keys)) { $RolesHash[$key] | % { [PSCustomObject]$_ } }
$report | sort DisplayName | Export-CSV -nti -Path "$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss'))_az-admins.csv"
#>


#Export file to blob
Set-AzContext -Subscription '04294eda-21ff-4b5a-a2dd-673650a53827'
Set-AzCurrentStorageAccount -ResourceGroupName "CIS-Storage" -Name "ciscostcsv"
#Set-AzStorageBlobContent -Container "ad-admins-report" -File 'C:\temp\az-admins.csv' -Blob "az-admins.csv" -Force
Set-AzStorageBlobContent -Container "ad-admins-report" -File 'AZ-admins.csv' -Blob "az-admins.csv" -Force



#######################################
#Send email with the Attachment            
#Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Attachments 'ad-admins.csv' -Subject "AD Admins - report" -To: ms-group@technion.ac.il, igorfl@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$cred -from: "cisreports@Technion.ac.il" 

#####################################################################################################################################################


#Authenticate access with user-assigned managed identity
Write-Output "Connecting to azure via  Connect-AzAccount"  
Connect-AzAccount -Identity -AccountId '63e8121f-2c23-4db6-91bb-214b76db23fc' -subscription 'CIS-Technion (EA)'
$secret = Get-AzKeyVaultSecret -VaultName 'cis-key' -Name 'DefenderATPApp'
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)  
try {  
  $secretValueText2 = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)  
} finally {  
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)  
} 

#Connect to MgGraph
$ApplicationId2 = "40499d1b-3c87-48f9-9cb3-bf2011658f74"
$SecuredPassword = $secretValueText2
$tenantID = "f1502c4c-ee2e-411c-9715-c855f6753b84"

$SecuredPasswordPassword = ConvertTo-SecureString `
-String $SecuredPassword -AsPlainText -Force

$ClientSecretCredential = New-Object `
-TypeName System.Management.Automation.PSCredential `
-ArgumentList $ApplicationId2, $SecuredPasswordPassword

Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential




$tokenBody = @{  
    Grant_Type    = "client_credentials"  
    Scope         = "https://graph.microsoft.com/.default"  
    Client_Id     = $ApplicationId2 
    Client_Secret = $secretValueText2  
} 

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody

$headers = @{
    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-type"  = "application/json"
}


$Attachment= "AZ-admins.csv"
$FileName=(Get-Item -Path $Attachment).name
$base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment))

#Configure Mail Properties
$MailSender = "cisreports@technion.ac.il"


#Send Mail    
$URLsend = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"


$BodyJsonsend = @"
                    {
                        "message": {
                          "subject": "AZ Admins - report",
                          "body": {
                            "contentType": "HTML",
                            "content": "This Mail is sent via Microsoft <br>
                           
                            "
                          },
                          
                          "toRecipients": [
                            {
                              "emailAddress": {
                                "address": "ms-group@technion.ac.il"
                              }
                             },
                             { 
                              "emailAddress": {
                                "address": "zeev@technion.ac.il"
                              }
                            }
                          ]              
                        ,"attachments": [
                            {
                              "@odata.type": "#microsoft.graph.fileAttachment",
                              "name": "$FileName",
                              "contentType": "HTML",
                              "contentBytes": "$base64string"
                            }
                          ]
                        },
                        "saveToSentItems": "false"
                      }
"@


Invoke-RestMethod -Method POST -Uri $URLsend -Headers $headers -Body $BodyJsonsend