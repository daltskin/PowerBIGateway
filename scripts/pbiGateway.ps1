Param(
    # AAD Application Id to install the data gateway under: https://docs.microsoft.com/en-us/powershell/module/datagateway.profile/connect-datagatewayserviceaccount?view=datagateway-ps
    [Parameter(Mandatory = $true)]
    [string]
    $AppId,

    # AAD Application secret: https://docs.microsoft.com/en-us/powershell/module/datagateway.profile/connect-datagatewayserviceaccount?view=datagateway-ps
    [Parameter(Mandatory = $true)]
    [string]
    $Secret,

    # AAD Tenant Id (or name): https://docs.microsoft.com/en-us/powershell/module/datagateway.profile/connect-datagatewayserviceaccount?view=datagateway-ps
    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,

    # Documented on the Install-DataGateway: https://docs.microsoft.com/en-us/powershell/module/datagateway/install-datagateway?view=datagateway-ps
    [Parameter()]
    [string]
    $InstallerLocation,

    # Documented on the Add-DataGatewayCluster: https://docs.microsoft.com/en-us/powershell/module/datagateway/add-datagatewaycluster?view=datagateway-ps
    [Parameter()]
    [string]
    $Region = $null,

    # Documented on the Add-DataGatewayCluster: https://docs.microsoft.com/en-us/powershell/module/datagateway/add-datagatewaycluster?view=datagateway-ps
    [Parameter(Mandatory = $true)]
    [string]
    $RecoveryKey,

    # Documented on the Add-DataGatewayCluster: https://docs.microsoft.com/en-us/powershell/module/datagateway/add-datagatewaycluster?view=datagateway-ps
    [Parameter(Mandatory = $true)]
    [string]
    $GatewayName,

    # Documented on the Add-DataGatewayClusterUser: https://docs.microsoft.com/en-us/powershell/module/datagateway/add-datagatewayclusteruser?view=datagateway-ps
    [Parameter()]
    [string]
    $GatewayAdminUserIds = $null
)

# Import log utils
. .\logUtil.ps1

$logger = [TraceLog]::new("$env:SystemDrive\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\", "pbiGateway.log")

if(($PSVersionTable).PSVersion.Major -lt 7) {
    $progressMsg = "This script requires PowerShell v7 or above"
    $logger.Log($progressMsg)
    Write-Error($progressMsg)
    exit 1
}

# Install the DataGateway module if not already available
# ((Get-Module -ListAvailable | Where-Object {$_.Name -eq "Storage"}).Length -eq 0)
if (!(Get-InstalledModule "DataGateway")) {
    $progressMsg = "Installing DataGateway PS Module"
    $logger.Log($progressMsg)
    Write-Host($progressMsg)
    Install-Module -Name DataGateway -Force -Scope AllUsers
}

$secureClientSecret = ConvertTo-SecureString $Secret -AsPlainText
$secureRecoveryKey = ConvertTo-SecureString $RecoveryKey -AsPlainText

# Connect to the Data Gateway service
$progressMsg = "Connect to the Data Gateway Service"
$logger.Log($progressMsg)
Write-Host($progressMsg)
$connected = (Connect-DataGatewayServiceAccount -ApplicationId $AppId -ClientSecret $secureClientSecret -Tenant $TenantId)
if ($null -eq $connected){
    $progressMsg = "Error connecting to Data Gateway Service"
    $logger.Log($progressMsg)
    Write-Error($progressMsg)
    exit 1
}

# Check if gateway already installed
if (!(IsInstalled 'GatewayComponents' $logger)) {
    # Install the gateway on machine
    $progressMsg = "Installing Data Gateway"
    $logger.Log($progressMsg)
    Write-Host($progressMsg)

    if (!(Test-Path -Path $InstallerLocation)) {
        # Download the installer
        $progressMsg = "InstallerLocation: '$InstallerLocation' not found - using default"
        $logger.Log($progressMsg)
        Write-Host($progressMsg)
        Install-DataGateway -AcceptConditions
    }else {
        # Use local installer
        $progressMsg = "InstallerLocation: '$InstallerLocation' found"
        $logger.Log($progressMsg)
        Write-Host($progressMsg)
        Install-DataGateway -AcceptConditions -InstallerLocation $InstallerLocation
    }
}

# Create the Data Gateway Cluster, returning it's Id
$gatewayClusterId = $null
$progressMsg = "Creating Data Gateway Cluster: '$GatewayName'"
$logger.Log($progressMsg)
Write-Host($progressMsg)

# Check if the Data Gateway Cluster region supplied exists
if ((Get-DataGatewayRegion | Where-Object {$_.RegionKey -eq $Region}).Length -eq 0) {
    $progressMsg = "Data Gateway Cluster region: '$RegionKey' not found using default"
    $logger.Log($progressMsg)
    Write-Host($progressMsg)
    $newGatewayCluster = (Add-DataGatewayCluster -Name $GatewayName -RecoveryKey $secureRecoveryKey -OverwriteExistingGateway) 
} else {
    $progressMsg = "Data Gateway Cluster region: '$Region'"
    $logger.Log($progressMsg)
    Write-Host($progressMsg)
    $newGatewayCluster = (Add-DataGatewayCluster -Name $GatewayName -RecoveryKey $secureRecoveryKey -RegionKey $Region -OverwriteExistingGateway) 
}

if ($null -eq $newGatewayCluster) {
    # If Gateway already exists, get the ClusterId (not GatewayId)
    $gatewayClusterId = (Get-DataGatewayCluster | Where-Object {$_.Name -eq $GatewayName}).Id
    $progressMsg = "Data Gateway Cluster name '$GatewayName' already exists: '$gatewayClusterId'"
    $logger.Log($progressMsg)
    Write-Host($progressMsg)
}else {
    # Gateway created ok, get the ClusterId
    $gatewayClusterId = $newGatewayCluster.GatewayObjectId
    $progressMsg = "Data Gateway Cluster created Id: '$gatewayClusterId'"
    $logger.Log($progressMsg)
    Write-Host($progressMsg)
}

# If problem during cluster creation or cluster missing we won't have a ClusterId
if ($null -eq $gatewayClusterId) {
    $progressMsg = "Warning! Data Gateway Cluster not found, check if Gateway Name: '$GatewayName' already exists and status of GateWay Cluster Id: '$gatewayClusterId'"
    $logger.Log($progressMsg)
    Write-Error($progressMsg)
    exit 1
}

# Optionally add additional user as an admin for this data gateway
if (!([string]::IsNullOrEmpty($GatewayAdminUserIds))) {
    $progressMsg = "Adding Data Gateway admin user(s): '$GatewayAdminUserIds'"
    $logger.Log($progressMsg)
    Write-Host($progressMsg)

    $GatewayAdminUserIdArray = $GatewayAdminUserIds -split ','
    $GatewayAdminUserIdArray.foreach{
        [GUID]$userGuid = $PSItem
        $progressMsg = "Adding Data Gateway admin user: '$userGuid'"
        $logger.Log($progressMsg)
        Write-Host($progressMsg)
        Add-DataGatewayClusterUser -GatewayClusterId $gatewayClusterId -RegionKey $Region -PrincipalObjectId $userGuid -Role Admin

        # Check the user was added ok
        if ((Get-DataGatewayCluster | Select -ExpandProperty Permissions | Where-Object {$_.Id -eq $userGuid}).Length -ne 0) {                
            $progressMsg = "Data Gateway admin user added"
            $logger.Log($progressMsg)
            Write-Host($progressMsg)
        }else {
            $progressMsg = "Warning! Data Gateway admin user not added"
            $logger.Log($progressMsg)
            Write-Warning($progressMsg)
        }
    }
}

# Retrieve the cluster status
$cs = (Get-DataGatewayClusterStatus -GatewayClusterId $gatewayClusterId).ClusterStatus
$progressMsg = "Cluster '$gatewayClusterId' status: '$cs'"
$logger.Log($progressMsg)
Write-Host($progressMsg)

$progressMsg = "Finished pbiGateway.ps1"
$logger.Log($progressMsg)
Write-Host($progressMsg)
