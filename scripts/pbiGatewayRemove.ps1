#! /opt/microsoft/powershell/7/pwsh

Param(
    # AAD Application Id to install the data gateway under: https://docs.microsoft.com/en-us/powershell/module/datagateway.profile/connect-datagatewayserviceaccount?view=datagateway-ps
    [Parameter(Mandatory = $true)][string]$AppId,

    # AAD Application secret: https://docs.microsoft.com/en-us/powershell/module/datagateway.profile/connect-datagatewayserviceaccount?view=datagateway-ps
    [Parameter(Mandatory = $true)][string]$Secret,

    # AAD Tenant Id (or name): https://docs.microsoft.com/en-us/powershell/module/datagateway.profile/connect-datagatewayserviceaccount?view=datagateway-ps
    [Parameter(Mandatory = $true)][string]$TenantId,
 
    # Documented on the Remove-DataGatewayCluster: https://docs.microsoft.com/en-us/powershell/module/datagateway/remove-datagatewaycluster?view=datagateway-ps
    [Parameter(Mandatory = $true)][string]$GatewayName,

    # Documented on the Remove-DataGatewayCluster: https://docs.microsoft.com/en-us/powershell/module/datagateway/remove-datagatewaycluster?view=datagateway-ps
    [Parameter(Mandatory = $true)][string]$Region
)

if(($PSVersionTable).PSVersion.Major -lt 7) {
    Write-Error("This script requires PowerShell v7 or above")
    exit 1
}

# DataGateway module should already been installed within the container
# ((Get-Module -ListAvailable | Where-Object {$_.Name -eq "Storage"}).Length -eq 0)
if (!(Get-InstalledModule "DataGateway")) {
    Write-Error("DataGateway PS Module is missing")
    exit 1
}

$secureClientSecret = ConvertTo-SecureString $Secret -AsPlainText

# Connect to the Data Gateway service
Write-Host("Connect to the Data Gateway Service")
$connected = (Connect-DataGatewayServiceAccount -ApplicationId $AppId -ClientSecret $secureClientSecret -Tenant $TenantId)
if ($null -eq $connected){
    Write-Error("Error connecting to Data Gateway Service")
    exit 1
}

# Check if the Data Gateway Cluster region supplied exists & get it's region key
$regionKey = (Get-DataGatewayRegion | Where-Object {$_.Region -eq $Region}).RegionKey
if ($null -eq $regionKey) {
    Write-Error("Error! Data Gateway RegionKey not found for Region '$Region'")
    exit 1    
} 

# Get Gateway ClusterId (not GatewayId)
$gatewayClusterId = (Get-DataGatewayCluster -RegionKey $regionKey | Where-Object {$_.Name -eq $GatewayName}).Id

# If there was a problem during cluster creation we won't have a ClusterId
if ($null -eq $gatewayClusterId) {
    Write-Error("Error! Data Gateway Cluster not found with Gateway Name: '$GatewayName' in RegionKey: '$regionKey'")
    exit 1
} else {
    Write-Host("Removing Data Gateway ClusterId: '$gatewayClusterId' in RegionKey: '$regionKey'")
}

Remove-DataGatewayCluster -GatewayClusterId $gatewayClusterId -RegionKey $regionKey
Write-Host("Gateway: '$GatewayName' removed")
