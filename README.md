# Automate Entitlement Management in Azure AD Identity Governance using Microsoft Graph Powershell:-

Greetings to my fellow Technology Advocates and Specialists.

In this Session, I will demonstrate __How to create Catalog and Access Package in Entitlement Management using Microsoft Graph Powershell.__

I had the Privilege to talk on this topic in __ONE__ Azure Communities:-

I had the Privilege to talk on this topic in __TWO__ Azure Communities:-

| __NAME OF THE AZURE COMMUNITY__ | __TYPE OF SPEAKER SESSION__ |
| --------- | --------- |
| __Azure Spring Clean 2023__ | __Virtual__ |
| __Cloud Lunch and Learn__ | __Virtual__ |


| __EVENT ANNOUNCEMENTS:-__ |
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wvgh4cxe8ll54cxbwqlm.png) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/uoicxb7e4oavxemqe9fj.JPG) |
| __VIRTUAL SESSION:-__ |
| __LIVE DEMO__ was Recorded as part of my Presentation in __CLOUD LUNCH AND LEARN__ Forum/Platform |
| Duration of My Demo = __53 Mins 28 Secs__ |
| [![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/pgntkqvm0cY/0.jpg)](https://www.youtube.com/watch?v=pgntkqvm0cY) |


| __AUTOMATION OBJECTIVES:-__ |
| --------- |

| __#__ | __TOPICS__ |
| --------- | --------- |
|  1. | Create a Catalog. |
|  2. | Add an existing Azure Active Directory (AAD) Group as an Resource in the Catalog. |
|  3. | Create Azure Active Directory (AAD) Group(s). |
|  4. | Assign the Azure Active Directory (AAD) Group(s) as "Catalog Owner", "Catalog Reader", "Access Package Manager", and "Access Package Client Assignment Manager" respectively. |
|  5. | Create a Access Package. |
|  6. | Add the already added existing Azure Active Directory (AAD) Group in the Catalog to the Access Package as "Member". |
|  7. | Create Access Package Policy. |


| __INTRODUCTION:-__ |
| --------- |
| Azure Active Directory (AAD) entitlement management using Microsoft Graph PowerShell enables you to manage access to all the resources that users need, such as groups, applications, and sites. Entitlement management helps to create a package of resources that internal users can use for self-service requests. Requests that does not require approval and user access expires after 365 days.  |
| Here, in this session, resources are just member in a single group, but it could be a collection of groups, applications, or SharePoint Online sites. |

 
| __REQUIREMENTS:-__ |
| --------- |

1. Azure Tenant by type "Azure Active Directory (AAD)" with one of the Licenses in order to use "Azure AD Entitlement Management": a.) Azure AD Premium P2, OR b.) Enterprise Mobility + Security (EMS) E5 license.
2. Microsoft Graph PowerShell SDK.
3. "User Administrator", "Identity Governance Administrator" or "Global Administrator" PIM role is required to configure catalogs, access packages, or policies in entitlement management.
4. A test Azure Active Directory (AAD) Group to onboard as a Catalog Resource and Access Package Member. 


| __USE CASES:-__ |
| --------- |
| Assigning and Removing one or more users from one or more AAD Groups at the same time. |


| BELOW FOLLOWS THE CODE SNIPPET:- | 
| --------- |

```
###############
# VARIABLES:- 
###############
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

########################################################################
#3. Create AAD Groups and configure Catalog Roles and Administrator:- 
########################################################################

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
#4. Add AAD Group to the Catalog Resource:-
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
#6. Get the Origin ID of the member Resource Role:-
###################################################

$catalogresourceoriginid = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResourceRole -AccessPackageCatalogId $catalogid -Filter "originSystem eq 'AadGroup' and accessPackageResource/id eq '$catalogresourceid' and DisplayName eq 'Member'" | Select -ExpandProperty OriginId

################################
#7. Create Access Package:-
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

```

| EXPLANATION OF THE CODE SNIPPET:- | 
| --------- |

| Define Variables:- | 
| --------- |

```
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

```

| Connect to MS Graph Powershell SDK:- | 
| --------- |

```
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"
Select-MgProfile -Name "beta"
Import-Module Microsoft.Graph.DeviceManagement.Enrolment

```

| Create Catalog and get the Catalog Identifier:- | 
| --------- |

```
$catalogid = New-MgEntitlementManagementAccessPackageCatalog -DisplayName $CatalogName -Description $CatalogDesc | Select -ExpandProperty Id

echo "##############################################"
echo "Catalog $CatalogName created successfully."
echo "##############################################"

```

| Create AAD Groups and configure Catalog Roles and Administrator:- | 
| --------- |
| __Note:-__ |
| The script is paused for 60 secs in order for the newly created AAD Groups to be populated. Later, these AAD Groups were used to assign Catalog Roles and Administrators. |

```
AADGrpCatalogownerid = az ad group create --display-name $AADGrpCatalogowner --mail-nickname $AADGrpCatalogowner --query "id" -o tsv
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

```

| Add AAD Group to the Catalog Resource:- | 
| --------- |

```
$aadgrpid = az ad group show -g "$AADGroupname" --query "id" -o tsv

$accessPackageResource = @{
  "originSystem" = "AadGroup"
  "OriginId" = $aadgrpid
}
New-MgEntitlementManagementAccessPackageResourceRequest -CatalogId $catalogid -RequestType "AdminAdd" -AccessPackageResource $accessPackageResource | select Id, RequestState | ConvertTo-Json
echo "###################################################################################"
echo "AAD Group $AADGroupname has been added to the Catalog $CatalogName successfully."
echo "###################################################################################"

```

| Get ID of the AAD Group as Catalog Resource:- | 
| --------- |

```
$catalogresourceid = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResource -AccessPackageCatalogId $catalogid -Filter "DisplayName eq '$AADGroupname'" | Select -ExpandProperty Id

```

| Get the Origin ID of the member Resource Role:- |
| --------- |

```
$catalogresourceoriginid = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResourceRole -AccessPackageCatalogId $catalogid -Filter "originSystem eq 'AadGroup' and accessPackageResource/id eq '$catalogresourceid' and DisplayName eq 'Member'" | Select -ExpandProperty OriginId

```

| Create Access Package:- |
| --------- |

```
$accesspkgid = New-MgEntitlementManagementAccessPackage -CatalogId $catalogid -DisplayName $AccessPackageName -Description $AccessPackageDesc | Select -ExpandProperty Id
echo "#############################################################################################"
echo "Access Package $AccessPackageName has been added to the Catalog $CatalogName successfully."
echo "#############################################################################################"

```

| Add Resource Role (Member Role) in the Access Package:- |
| --------- |

```
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

```

| Create Access Package Policy:- |
| --------- |

```
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

```

__NOW ITS TIME TO TEST:-__

| __TEST CASES:-__ | 
| --------- |
| 1. Connect to MS Graph Powershell SDK:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/sm26lofcf2zgbdlw43ug.jpg) |
| 2. Script executed successfully:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/lpd7lge5uut5gay70v74.jpg) |
| 3. Validate creation of Catalog:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/mjjp92gx40f6oiyowco1.jpg) |
| 4. Validate adding existing AAD group to Catalog resource:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8tkaf9ppwvjekfloqr9e.jpg) |
| 5. Validate creation of AAD groups:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/xhnugw9ray5nxcpn7i6e.jpg) |
| 6. Validate Catalog Roles and Administrator:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8a6aklxzvatczxqqj8r5.jpg) |
| 7. Validate creation of Access Package:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/211y566ul0qeoazwidix.jpg) |
| 8. Validate existing AAD group under Catalog Resource as Member of Access Package:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/upp8pf3mu1zn29ivuhz3.jpg) |
| 9. Validate creation of Access Package Policies:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/w78xsghb1uvnyw7av45q.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/i58hz1u5xjf36uwz3ar3.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/bcwikg1t0d2kz0vptnes.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cz2puukdxjhqxrmy8rah.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jyl5lwvbk5y493rsygs5.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/6tbky6jr13j60jzniv4r.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/1m3kicbn8tode2tkofk0.jpg) |
| 10. Validate Assignment of a test user to the AAD Group using Access Package:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/mqa16rx7c28p4rtinbag.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/0982mbgcncvf0jby7jaz.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cr2kx6rcowct04thhdwc.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8zzs18duxuglvyisguws.jpg) |


__Hope You Enjoyed the Session!!!__

__Stay Safe | Keep Learning | Spread Knowledge__
