# Set  the StrongAuthenticationRequirement 

$Cred = Get-AutomationPSCredential -Name "Outlook365"
Connect-MSOLService -Credential:$Cred
#connect-azuread -Credential $cred


$sa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$sa.RelyingParty = "*"
$sa.State = "Enforced"
$sar = @($sa)

# Get all users that do not have MFA enforced
$nomfa = Get-MsolUser -All| ? {$_.StrongAuthenticationRequirements.State -ne "Enforced" -and $_.UserPrincipalName -like "*technion.ac.il"}

# Get users that should not have MFA enforced
$excludemfa= Get-MsolGroupMember -GroupObjectId (Get-MsolGroup -SearchString AAD-Security-Exclude).ObjectId | % {Get-MsolUser -UserPrincipalName $_.EmailAddress}

# Remove excluded users from the users list
$nomfausers = $nomfa |? {$_.UserPrincipalName -notin $excludemfa.UserPrincipalName} 

# Enable MFA for the needed users
$nomfausers | % {Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements $sar}
$count= $nomfausers.count
write-output "No MFA users count: $count"

foreach ($user in $nomfausers) {
    $userupn= $user.UserPrincipalName
write-output "MFA was set  for $userupn" }

