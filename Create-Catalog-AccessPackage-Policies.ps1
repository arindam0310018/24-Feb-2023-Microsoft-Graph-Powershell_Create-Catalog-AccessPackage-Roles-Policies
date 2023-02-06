##############
# VARIABLES:- 
##############
$CatalogName = "AM-LAB"
$CatalogDesc = "AM Lab Environment Catalog"
$AADGroupname = "AM-Lab-OpsSupport"
$AccessPackageName = "AM-Lab-Access-Pkge-001"
$AccessPackageDesc = "AM Lab Environment Access Package 001"
$scopetype = "NoSubjects"
$acceptrequests = "$true"
$accesspkgapprovalreq = "$false"
$accesspkgapprovalreqext = "$false"
$accesspkgrequestorjustify = "$false"
$AccessPackagePolicyName = "Administrator managed (365 days)"
$AccessPackagePolicyDesc = "admin managed policy"
$duration = "365"
 
#################
# CORE SCRIPT:- 
#################

#########################################
#1. Connect to MS Graph Powershell SDK:-
#########################################

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"
Select-MgProfile -Name "beta"

####################################################
#2. Create Catalog and get the Catalog Identifier:-
####################################################

$catalogid = New-MgEntitlementManagementAccessPackageCatalog -DisplayName $CatalogName -Description $CatalogDesc | Select -ExpandProperty Id

#############################################
#3. Add AAD Group to the Catalog Resources:-
#############################################

$aadgrpid = az ad group show -g "$AADGroupname" --query "id" -o tsv

$accessPackageResource = @{
  "originSystem" = "AadGroup"
  "OriginId" = $aadgrpid
}
New-MgEntitlementManagementAccessPackageResourceRequest -CatalogId $catalogid -RequestType "AdminAdd" -AccessPackageResource $accessPackageResource | select Id, RequestState | ConvertTo-Json

##################################################
#4. Get ID of the AAD Group as Catalog Resource:-
##################################################

$catalogresourceid = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResource -AccessPackageCatalogId $catalogid -Filter "DisplayName eq '$AADGroupname'" | Select -ExpandProperty Id

###################################################
#5. Get the OriginId of the member Resource Role:-
###################################################

$catalogresourceoriginid = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResourceRole -AccessPackageCatalogId $catalogid -Filter "originSystem eq 'AadGroup' and accessPackageResource/id eq '$catalogresourceid' and DisplayName eq 'Member'" | Select -ExpandProperty OriginId

################################
#6. Create the Access Package:-
################################

$accesspkgid = New-MgEntitlementManagementAccessPackage -CatalogId $catalogid -DisplayName $AccessPackageName -Description $AccessPackageDesc | Select -ExpandProperty Id

############################################################
#7. Add Resource Role (Member Role) in the Access Package:-
############################################################

$accessPackageResource = @{
  "id" = $catalogresourceid
  "resourceType" = "Security Group"
  "originId" = $aadgrpid
  "originSystem" = "AadGroup"
  }

$accessPackageResourceRole = @{
  "originId" = $catalogresourceoriginid
  "displayName" = "Member"
  "originSystem" = "AadGroup"
  "accessPackageResource" = $accessPackageResource
  }

$accessPackageResourceScope = @{
  "originId" = $aadgrpid
  "originSystem" = "AadGroup"
  }

New-MgEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $accesspkgid -AccessPackageResourceRole $accessPackageResourceRole -AccessPackageResourceScope $accessPackageResourceScope | Format-List

####################################
#8. Create Access Package Policy:-
####################################

$requestorSettings =@{
  "scopeType" = $scopetype
  "acceptRequests" = $acceptrequests
  }

$requestApprovalSettings = @{
  "isApprovalRequired" = $accesspkgapprovalreq
  "isApprovalRequiredForExtension" = $accesspkgapprovalreqext
  "isRequestorJustificationRequired" = $accesspkgrequestorjustify
  "approvalMode" = 'NoApproval'
  "approvalStages" = '[]'
  }

New-MgEntitlementManagementAccessPackageAssignmentPolicy -AccessPackageId $accesspkgid -DisplayName $AccessPackagePolicyName -Description $AccessPackagePolicyDesc -DurationInDays $duration -RequestorSettings $requestorSettings -RequestApprovalSettings $requestApprovalSettings | Format-List
