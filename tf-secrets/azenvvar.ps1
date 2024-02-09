# variables
$location
$location = "CentralUS" 
$tags =   "owner=mcruz","environment=dev","project=learning"
$rgName = "rg-tf"
$kvName = "tf-kv-cruz3r"
$saName = "tfsacruz3r"
$containerName = "tfappname1"

# Login to Azure
$azlogin = az login | ConvertFrom-Json
$azlogin 

# Create A Terraform App Registration with Contributor Role to allow access to create / manage resources
$AppReg = az ad sp create-for-rbac --role="Contributor" --scopes=$("/subscriptions/" + $azlogin.id) --name="TF" | convertfrom-json
$AppReg 

# Create RG for TF
if ([System.Convert]::ToBoolean($(az group exists -n $rgName)) ){
    "Get RG"
    $rgkv = az group show -n $rgName
} else {
    "Create RG"
    $rgkv = az group create --name $rgName --location $location --tags $tags | convertfrom-json
}

# Create KeyVault for TF
#$kv = az keyvault create --name $kvName -g $rgkv.name --location $location --tags purpose=TF environment=dev | convertfrom-json
if ((az keyvault list --resource-group $rgName).length -ne 0) {
    "Create KV"
    $kv = az keyvault create --name $kvName -g $rgName --location $location --tags $tags | convertfrom-json
} else {
    # If the keyvault is already created
    "Get KV"
    $kv = az keyvault show --name $kvName | convertfrom-json
}

# Create Storage Account for TF
if ((az storage account list --resource-group $rgName).length -ne 0) {
    "Create SA"
    $sa = az storage account create --name $saName -g $rgName --location $location --tags $tags | convertfrom-json
} else {
    # If the keyvault is already created
    "Get SA"
    $sa = az storage account show --name $saName | convertfrom-json
}

$extIP = Invoke-RestMethod -uri 'https://api.ipify.org?format=json'
az storage account network-rule add -g $sa.resourceGroup -n $sa.name --ip-address $extIP.ip
az keyvault network-rule add -g $kv.resourceGroup -n $kv.name --ip-address $extIP.ip
# Manually set Enabled from selected virtual networks and IP addresses
#az storage account update -g $sa.resourceGroup -n $sa.name --default-action deny # Could not create a Container when this was set
az keyvault update -g $kv.resourceGroup -n $kv.name --default-action deny
# get storage Key
$saKey = (az storage account keys list --account-name $sa.name | convertfrom-json)[0].value

# Create New Container
az storage container create --name $containerName --account-name $sa.name --account-key $saKey

# Add Secrets to KeyVault 
$AppReg | ForEach-Object {$_ }
$AppReg.psobject.properties | ForEach-Object {if ($_.name -ne "displayName"){az keyvault secret set --vault-name $kv.name --name $("TF-" + $_.name) --value $_.value }}
# Storage Key
az keyvault secret set --vault-name $kv.name --name 'TF-storagekey' --value $saKey

# Create Env Variables
$azlogin = Connect-AzAccount 
$env:ARM_SUBSCRIPTION_ID = $azlogin.id 
$env:ARM_CLIENT_ID = (az keyvault secret show --name "TF-appid" --vault-name $kvName | ConvertFrom-Json).value
$env:ARM_CLIENT_SECRET = (az keyvault secret show --name "TF-password" --vault-name $kvName | ConvertFrom-Json).value 
$env:ARM_TENANT_ID = (az keyvault secret show --name "TF-tenant" --vault-name $kvName | ConvertFrom-Json).value 
$env:ARM_ACCESS_KEY=(az keyvault secret show --name "TF-storagekey" --vault-name $kvName | ConvertFrom-Json).value
