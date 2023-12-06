

$htmldownload = @"

<html> 

<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;"><img src="https://gustavo.webgr.technion.ac.il/wp-content/uploads/sites/59/2020/05/logo1.png" alt="" width="625" height="130" />&nbsp;</p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;"><strong>You have a report Alerts/Incidents for the last Week</strong></p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;"><a href="https://technionmail.sharepoint.com/sites/portalsecurity/Lists/FileList/Attachments/[id]/[filename]">Download</a></p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;">For more information</p>
<p style="text-align: center;"><a href="https://securitycenter.windows.com/">securitycenter.windows.com</a></p>
<p>&nbsp;</p>
<p style="text-align: center;">&nbsp;&nbsp;&nbsp;&nbsp; <img src="https://gustavo.webgr.technion.ac.il/wp-content/uploads/sites/59/2020/05/logo2.png" alt="" width="624" height="67" /></p>

</html>
"@ 

$htmlnoalerts = @"

<html> 

<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;"><img src="https://gustavo.webgr.technion.ac.il/wp-content/uploads/sites/59/2020/05/logo1.png" alt="" width="625" height="130" />&nbsp;</p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;"><strong>There are no any Alerts/Incidents for the last Week</strong></p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;">&nbsp;</p>
<p style="text-align: center;">For more information</p>
<p style="text-align: center;"><a href="https://securitycenter.windows.com/">securitycenter.windows.com</a></p>
<p>&nbsp;</p>
<p style="text-align: center;">&nbsp;&nbsp;&nbsp;&nbsp; <img src="https://gustavo.webgr.technion.ac.il/wp-content/uploads/sites/59/2020/05/logo2.png" alt="" width="624" height="67" /></p>

</html>
"@ 






function body ($id,$filename) {

     $html = $htmldownload.Replace("[id]",$id).Replace("[filename]",$filename)
     return $html
}



##HTML for Report

$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
<title>
 
</title>
"@
$pre = @"

<div style='margin:  0px auto; BACKGROUND-COLOR:grey;Color:White;font-weight:bold;FONT-SIZE:  24pt;TEXT-ALIGN: center;'>

  ATP Week Report for $group

</div>    

"@ 
$Post =  @"

<div style='margin:  0px auto; BACKGROUND-COLOR:grey;Color:black;font-weight:bold;FONT-SIZE:  20pt;TEXT-ALIGN: left;'>

  <br>CIS Technion</br>  
  <br>For More Information go to <a href="https://securitycenter.windows.com/">securitycenter.windows.com</a></br>


</div>    

"@ 


$StorageAccountName = "atpstoragereports"
$ResourceGroupName = "CIS-Storage"
$container = "reportsforfaculty"

$userCredentials = Get-AutomationPSCredential -Name "Outlook365"
connect-azaccount -credential $userCredentials

Select-AzSubscription -Subscription "04294eda-21ff-4b5a-a2dd-673650a53827"

Set-AzStorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName

$date= (get-date).ToString("dd-MM-yyyy")


function write-sharepointlist ($owner,$file,$title) {
######ADD item to list

$newlist = Add-PnPListItem -List "FileList" -Values @{"Owner"="$owner";"Title"="$title"}


##Attach Report

$item = Get-PnPListItem -List FileList -Id $newlist.id

$ctx = Get-PnPContext

$fileStream = New-Object IO.FileStream("$file",[System.IO.FileMode]::Open)

$attachInfo = New-Object -TypeName Microsoft.SharePoint.Client.AttachmentCreationInformation
$attachInfo.FileName = "$file"
$attachInfo.ContentStream = $fileStream

$attFile = $item.attachmentFiles.add($attachInfo)
$ctx.load($attFile)
$ctx.ExecuteQuery()
return $item
}


###Connect to Sharepoint list

#connect to the list

$url = "https://technionmail.sharepoint.com/sites/portalsecurity"

Connect-PnPOnline -Url "$url" -Credential ($userCredentials)






$tenantId = 'f1502c4c-ee2e-411c-9715-c855f6753b84' ### Paste your own tenant ID here
$appId = '40499d1b-3c87-48f9-9cb3-bf2011658f74' ### Paste your own app ID here
$appSecret = '9pE7Q~PaoUS9-STOoaBpmzKasE6WxPEG18Yxe' ### Paste your own app keys here

$resourceAppIdUri = 'https://api.securitycenter.windows.com'
$oAuthUri = "https://login.windows.net/$TenantId/oauth2/token"

$authBody = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}

$authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
$token = $authResponse.access_token
Out-File -FilePath "./Latest-token.txt" -InputObject $token


$dateTime = (Get-Date).ToUniversalTime().AddHours(-168).ToString("o")

$url = "https://api.securitycenter.windows.com/api/alerts?`$filter=alertCreationTime ge $dateTime"


$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $token" 
}

$response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers -ErrorAction Stop

#foreach alert, get the machineId and alertId and isloate machine while writing the alert ID in the isolation comments. 
$obj = $null

foreach ($alert in $response.value)
{ 
    Start-Sleep -s 2
	$alertId = $alert.id
	$machineId = $alert.machineId
	
	$url = "https://api.securitycenter.windows.com/api/machines/$machineId" 
	
	$body = @{}

	$headers = @{		
		Authorization = "Bearer $token" 
	} 
	
	$machineInfoResponse = Invoke-WebRequest -Method Get -Uri $url -Body $body -Headers $headers -ErrorAction Stop -UseBasicParsing
	
	#check the isolatino request code and write to log file. 
	if($machineInfoResponse.StatusCode -eq 200) { 
        $machineInfo =  $machineInfoResponse | select -Expand Content | ConvertFrom-Json
        $machineName = $machineInfo.computerDnsName

		# replace the next line with your code to take the alerts data and enrich it with machine info.
	    #$csv = $machineInfo | select @{name="IP";e={$_."lastExternalIpAddress"}},@{name="ComputerNAme";e={$_."computerDnsName"}},@{name="OS";e={$_."osPlatform"}},@{name="Tag";e={$_."rbacgroupname"}}
	   $obj = New-Object -TypeName PSObject
		 $obj | Add-Member -MemberType NoteProperty -Name "IP" -Value $machineInfo.lastExternalIpAddress
		 $obj | Add-Member -MemberType NoteProperty -Name "ComputerNAme" -Value $machineInfo.computerDnsName
		 $obj | Add-Member -MemberType NoteProperty -Name "OS" -Value $machineInfo.osPlatform
		 $obj | Add-Member -MemberType NoteProperty -Name "Tag" -Value $machineInfo.rbacGroupName
		 $obj | Add-Member -MemberType NoteProperty -Name "Alert Title" -Value $alert.title
         $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $alert.description
		 $obj | Add-Member -MemberType NoteProperty -Name "Severity" -Value $alert.severity
		 $obj | Add-Member -MemberType NoteProperty -Name "Incident ID" -Value $alert.incidentId
		 $obj | Add-Member -MemberType NoteProperty -Name "Alert Creation" -Value $alert.alertCreationTime

		
		 $obj | export-csv -Path:"c:\atpreports\atp-$date.csv"  -NoTypeInformation -Append -Force
	 
	} 
	else { 
		[System.Windows.MessageBox]::Show("Failed to get machine info for machien id - $machineId")
	} 
}


#Set-AZStorageBlobContent -Container $container -File atp.csv -blob "ATP-$date.csv" 

#Filter CSV for Faculty

#$blob =  Get-AzStorageBlobContent -Blob:"ATP-$date.csv" -Container:$container -Destination:"C:\Temp\" -Force 

$csv = import-csv -Path "c:\atpreports\ATP-$date.csv"
$Groupname = $csv | select Tag |sort Tag -Unique

## Email for non info for this week
#if ($Groupname -like "*AR Computers*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:ar-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*Pa Computers*") {} else{Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:pa-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*CV Computers*"){} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:cv-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*EE Computers*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:ee-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*MT Computers*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:MT-Admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "TR*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:TRDF-Admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "BFE*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:BFE-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "BM*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:bm-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "AG*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:ag-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "GIS*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:gis-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "BI*") {} else{Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:Bi-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*AE Computers*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:Ae-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*CH Computers*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:Ch-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*CE Computers*"){} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:Ce-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*PHY Computers*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:phy-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*ME Computers*") {} else {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:me-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 
#if ($Groupname -like "*SI Computers*"){} else  {Send-MailMessage -Bodyashtml -Encoding ([System.Text.Encoding]::UTF8) -Body $htmlnoalerts -Subject "ATP Report Weekly" -To:si-admins@technion.ac.il -SmtpServer:"smtp.office365.com" -UseSsl -Port 587 -Credential:$userCredentials -from: "cisreports@Technion.ac.il"} 




###########################################
#Connect To App
# The resource URI
$resource = "https://graph.microsoft.com"
$clientid = "40499d1b-3c87-48f9-9cb3-bf2011658f74" #Application (client) ID from Azure App registration Page
$clientSecret = "9pE7Q~PaoUS9-STOoaBpmzKasE6WxPEG18Yxe" #Client Secret from "Certificate $ secrets"
# $redirectUri = "http://localhost" # Redirect URL, which was used at App Registration Process
$Tenantid = "f1502c4c-ee2e-411c-9715-c855f6753b84" # Directory (tenant) ID also from Azure App registration Page


# No interaction, Application Permission
$tokenBody = @{  
    Grant_Type    = "client_credentials"  
    Scope         = "https://graph.microsoft.com/.default"  
    Client_Id     = $clientId  
    Client_Secret = $clientSecret  
}   

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$Tenantid/oauth2/v2.0/token" -Method POST -Body $tokenBody  


$headers = @{
        "Authorization" = "Bearer $($tokenResponse.access_token)"
        "Content-type"  = "application/json"
    }



#Configure Mail Properties
$MailSender = "cisreports@technion.ac.il"


#Connect to GRAPH API
$tokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $clientId
    Client_Secret = $clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody
$headers = @{
    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-type"  = "application/json"
}

$URLsend = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"



########
foreach ($Group in $Groupname) {

$group = $Group.tag

  $csvtemp = $csv | ? {$_.tag -eq "$group"} | ConvertTo-Html -Head $Header -PreContent $pre -PostContent $Post | foreach {
  $PSItem -replace "<td>Medium</td>", "<td style='background-color:#FCFF33'>Medium</td>" -replace "<td>Low</td>", "<td style='background-color:#6BFF33'>Low</td>" -replace "<td>High</td>", "<td style='background-color:#FF3333'>High</td>"
  } | out-file "c:\atpreports\ATP-$group-$date.html"
  #Set-AzStorageBlobContent -Container $container -File "ATP-$group.html" -blob "$Group-$date.html"
  #$blob2 = Get-AzStorageBlobContent -Blob:"$Group-$date.html" -Container:$container -Destination:"C:\Temp\" -Force



$fileforsharepoint = "ATP-$group-$date.html"

$filetosend = "c:\atpreports\ATP-$Group-$date.html"	 
$FileName=(Get-Item -Path $filetosend).name
$base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($filetosend))




###################

<#
if ($group -like "EE*") {  $emailto =  "ee-admins@technion.ac.il"
                                                   } 

if ($group -like "AR*") {  $emailto =  "ar-admins@technion.ac.il"
                        } 
if ($group -like "MT*") {  $emailto =  "mt-admins@technion.ac.il"
                        } 
if ($group -like "CV*") {  $emailto =  "cv-admins@technion.ac.il"
                        } 
if ($group -like "PA*") {  $emailto =  "pa-admins@technion.ac.il"
                        } 
if ($group -like "BI*") {  $emailto =  "bi-admins@technion.ac.il"
                        } 
                       
if ($group -like "TR*") {  $emailto =  "trdf-admins@technion.ac.il"
                        } 
if ($group -like "CS*") {  $emailto =  "cs-admins@technion.ac.il"
                        } 

if ($group -like "ME*") {  $emailto =  "me-admins@technion.ac.il"                  
                        } 

if ($group -like "ED*") {  $emailto =  "ed-admins@technion.ac.il"
                
                        } 
if ($group -like "BM*") {  $emailto =  "BM-admins@technion.ac.il"
                                                   } 
if ($group -like "Med*") { $emailto =  "med-admins@technion.ac.il"
                          
                                                  } 
if ($group -like "AE*") {  $emailto =  "ae-admins@technion.ac.il"                         
                        } 
if ($group -like "UG*") {  $emailto =  "under-admins@technion.ac.il"
                        } 
if ($group -like "PHY*") { $emailto =  "phy-admins@technion.ac.il"
                                                   } 

if ($group -like "CH*") {  $emailto =  "ch-admins@technion.ac.il"
                          
                                                  } 
if ($group -like "BFE*") { $emailto =  "bfe-admins@technion.ac.il"
                          }
if ($group -like "IEM*") { $emailto =  "ie-admins@technion.ac.il"
                           
                        } 
if ($group -like "AG*") {  $emailto =  "ag-admins@technion.ac.il"
            
                        } 
if ($group -like "CE*") {  $emailto =  "ce-admins@technion.ac.il"                   
                        } 
if ($group -like "Rechesh*") {  $emailto =  "pur-admins@technion.ac.il"
                        } 
if ($group -like "GIS*") { $emailto =  "gis-admins@technion.ac.il"
                        
                        } 
if ($group -like "SI*") {  $emailto =  "si-admins@technion.ac.il"
                           }
if ($group -like "HU*") {  $emailto =  "hum-admins@technion.ac.il"
                           }
if ($group -like "CL*") {  $emailto =  "cl-admins@technion.ac.il"                        
                        } 

             else {$owner = $null}
     
#>
 $emailto =  "kristina.mus@technion.ac.il" 

 
if($owner -ne $null ) {
    $itemid = write-sharepointlist -owner $emailto -file $filetosend -title $group 
                           $html = body -Id ($itemid.id) -filename $fileforsharepoint                
                          
                                       $BodyJsonsend = @"
                    {
                        "message": {
                          "subject": "ATP Report Weekly - $group",
                          "body": {
                            "contentType": "HTML",
                            "content": "This Mail is sent via Microsoft <br>
                            "
                          },
                          
                          "toRecipients": [
                            {
                              "emailAddress": {
                                "address": "$emailto"
                              }
                            }
                          ]              
                        ,"attachments": [
                            {
                              "@odata.type": "#microsoft.graph.fileAttachment",
                              "name": "$FileName",
                              "contentType": "text/plain",
                              "contentBytes": "$base64string"
                            }
                          ]
                        },
                        "saveToSentItems": "false"
                      }
"@








                        Invoke-RestMethod -Method POST -Uri $URLsend -Headers $headers -Body $BodyJsonsend

            }
    }

Remove-Item c:\atpreports\* -Recurse -Force



