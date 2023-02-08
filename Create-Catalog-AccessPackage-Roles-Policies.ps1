##############
# VARIABLES:- 
##############
$CatalogName = "AM-LAB"
$CatalogDesc = "AM Lab Environment Catalog"
$AADGroupname = "AM-Lab-OpsSupport"
$AccessPackageName = "AM-Lab-Access-Pkge"
$AccessPackageDesc = "AM Lab Environment Access Package"
$scopetype = "NoSubjects"
$acceptrequests = "$true"
$accesspkgapprovalreq = "$false"
$accesspkgapprovalreqext = "$false"
$accesspkgrequestorjustify = "$false"
$AccessPackagePolicyName = "Administrator managed (365 days)"
$AccessPackagePolicyDesc = "admin managed policy"
$duration = "365"
$AADGrpCatalogowner = "AM-Lab-Catalog-Owner"
$AADGrpCatalogreader = "AM-Lab-Catalog-Reader"
$AADGrpCatalogaccesspackagemanager = "AM-Lab-Catalog-AccessPackage-Manager"
$AADGrpCatalogaccesspackageassignmentmanager = "AM-Lab-Catalog-AccessPackage-Assignment-Manager"
#############################################
# The below Role Ids are constant values:-
#############################################
$roleidCatalogowner = "ae79f266-94d4-4dab-b730-feca7e132178"
$roleidCatalogreader = "44272f93-9762-48e8-af59-1b5351b1d6b3"
$roleidAccesspackagemanager = "7f480852-ebdc-47d4-87de-0d8498384a83"
$roleidAccesspackageassignmentmanager = "e2182095-804a-4656-ae11-64734e9b7ae5"
  
#################
# CORE SCRIPT:- 
#################

#########################################
#1. Connect to MS Graph Powershell SDK:-
#########################################

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"
Select-MgProfile -Name "beta"
Import-Module Microsoft.Graph.DeviceManagement.Enrolment

####################################################
#2. Create Catalog and get the Catalog Identifier:-
####################################################

$catalogid = New-MgEntitlementManagementAccessPackageCatalog -DisplayName $CatalogName -Description $CatalogDesc | Select -ExpandProperty Id

echo "##############################################"
echo "Catalog $CatalogName created successfully."
echo "##############################################"

####################################################
#3. Create Catalog Roles and Administrator:-
####################################################

$AADGrpCatalogownerid = az ad group create --display-name $AADGrpCatalogowner --mail-nickname $AADGrpCatalogowner --query "id" -o tsv
$AADGrpCatalogreaderid = az ad group create --display-name $AADGrpCatalogreader --mail-nickname $AADGrpCatalogreader --query "id" -o tsv
$AADGrpCatalogaccesspackagemanagerid = az ad group create --display-name $AADGrpCatalogaccesspackagemanager --mail-nickname $AADGrpCatalogaccesspackagemanager --query "id" -o tsv
$AADGrpCatalogaccesspackageassignmentmanagerid = az ad group create --display-name $AADGrpCatalogaccesspackageassignmentmanager --mail-nickname $AADGrpCatalogaccesspackageassignmentmanager --query "id" -o tsv

echo "###################################################################################"
echo "Pausing the Script for 60 Secs for the newly created AAD Group to be populated."
echo "###################################################################################"
Start-Sleep 60

$catalogownerrole = @{
	PrincipalId = "$AADGrpCatalogownerid"
	RoleDefinitionId = "$roleidCatalogowner"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

$catalogreaderrole = @{
	PrincipalId = "$AADGrpCatalogreaderid"
	RoleDefinitionId = "$roleidCatalogreader"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

$catalogaccesspackagemanagerrole = @{
	PrincipalId = "$AADGrpCatalogaccesspackagemanagerid"
	RoleDefinitionId = "$roleidAccesspackagemanager"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

$catalogaccesspackageassignmentmanagerrole = @{
	PrincipalId = "$AADGrpCatalogaccesspackageassignmentmanagerid"
	RoleDefinitionId = "$roleidAccesspackageassignmentmanager"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogownerrole
echo "#######################################################################################################################"
echo "AAD Group $AADGrpCatalogowner created successfully and has been added in the Catalog $CatalogName as Catalog Owner."
echo "#######################################################################################################################"

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogreaderrole
echo "#######################################################################################################################"
echo "AAD Group $AADGrpCatalogreader created successfully and has been added in the Catalog $CatalogName as Catalog Reader."
echo "#######################################################################################################################"

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogaccesspackagemanagerrole
echo "#######################################################################################################################################################"
echo "AAD Group $AADGrpCatalogaccesspackagemanager created successfully and has been added in the Catalog $CatalogName as Catalog Access Package Manager."
echo "#######################################################################################################################################################"

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogaccesspackageassignmentmanagerrole
echo "###########################################################################################################################################################################"
echo "AAD Group $AADGrpCatalogaccesspackageassignmentmanager created successfully and has been added in the Catalog $CatalogName as Catalog Access Package Assignment Manager."
echo "###########################################################################################################################################################################"

#############################################
#4. Add AAD Group to the Catalog Resources:-
#############################################

$aadgrpid = az ad group show -g "$AADGroupname" --query "id" -o tsv

$accessPackageResource = @{
  "originSystem" = "AadGroup"
  "OriginId" = $aadgrpid
}
New-MgEntitlementManagementAccessPackageResourceRequest -CatalogId $catalogid -RequestType "AdminAdd" -AccessPackageResource $accessPackageResource | select Id, RequestState | ConvertTo-Json
echo "###################################################################################"
echo "AAD Group $AADGroupname has been added to the Catalog $CatalogName successfully."
echo "###################################################################################"

##################################################
#5. Get ID of the AAD Group as Catalog Resource:-
##################################################

$catalogresourceid = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResource -AccessPackageCatalogId $catalogid -Filter "DisplayName eq '$AADGroupname'" | Select -ExpandProperty Id

###################################################
#6. Get the OriginId of the member Resource Role:-
###################################################

$catalogresourceoriginid = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResourceRole -AccessPackageCatalogId $catalogid -Filter "originSystem eq 'AadGroup' and accessPackageResource/id eq '$catalogresourceid' and DisplayName eq 'Member'" | Select -ExpandProperty OriginId

################################
#7. Create the Access Package:-
################################

$accesspkgid = New-MgEntitlementManagementAccessPackage -CatalogId $catalogid -DisplayName $AccessPackageName -Description $AccessPackageDesc | Select -ExpandProperty Id
echo "#############################################################################################"
echo "Access Package $AccessPackageName has been added to the Catalog $CatalogName successfully."
echo "#############################################################################################"

############################################################
#8. Add Resource Role (Member Role) in the Access Package:-
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
echo "#################################################################################################################"
echo "AAD Group $AADGroupname has been added successfully to the Access Package $AccessPackageName with Member Role."
echo "#################################################################################################################"

####################################
#9. Create Access Package Policy:-
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

echo "################################################################################"
echo "Access Package Policy $AccessPackagePolicyName has been created successfully."
echo "################################################################################"