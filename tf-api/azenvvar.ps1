$azlogin = az login | ConvertFrom-Json
$azlogin 

# Create A Terraform App Registration with Contributor Role to allow access to create / manage resources
$AppReg = az ad sp create-for-rbac --role="Contributor" --scopes=$("/subscriptions/" + $azlogin.id) --name="TF" | convertfrom-json
$AppReg 

# Create RG and KeyVault for Terraform
$location = "CentralUS" 
$tags = 'env=dev', 'purpose=TF', 'status=green'

$rgkv = az group create --name "rg-kv" --location $location --tags $tags | convertfrom-json
$kv = az keyvault create --name "kv-tf-cruz3r" -g $rgkv.name --location $location --tags purpose=TF environment=dev | convertfrom-json
# If the keyvault is already created
$kv = az keyvault show --name "kv-tf-cruz3r" | convertfrom-json
# Storage Key
$ACCOUNT_KEY=$(az storage account keys list --resource-group 'testpol2' --account-name 'stgcruz3rlr' --query '[0].value' -o tsv)

# Add Secrets to KeyVault 
$AppReg | ForEach-Object {$_ }
$AppReg.psobject.properties | ForEach-Object {if ($_.name -ne "displayName"){az keyvault secret set --vault-name $kv.name --name $("TF-" + $_.name) --value $_.value }}
az keyvault secret set --vault-name $kv.name --name 'tfapistate' --value $ACCOUNT_KEY

# Env Variables
$azlogin = Connect-AzAccount 
$keyvault = (az keyvault list | convertfrom-json | Where-Object name -match "kv-tf-").name 
$env:ARM_SUBSCRIPTION_ID = $azlogin.id 
$env:ARM_CLIENT_ID = (az keyvault secret show --name "TF-appid" --vault-name $KeyVault | ConvertFrom-Json).value
$env:ARM_CLIENT_SECRET = (az keyvault secret show --name "TF-password" --vault-name $KeyVault | ConvertFrom-Json).value 
$env:ARM_TENANT_ID = (az keyvault secret show --name "TF-tenant" --vault-name $KeyVault | ConvertFrom-Json).value 
$env:ARM_ACCESS_KEY=(az keyvault secret show --name "tfapistate" --vault-name $KeyVault | ConvertFrom-Json).value

# Storage Account - Not in use
$env:ARM_ACCESS_KEY = (Get-AzureKeyVaultSecret  -vaultName $KeyVault -Name "azurestateaccesskey" ).SecretValueText
# Public Key for SSH - Not in use
$env:TF_VAR_ssh_pub_key = (Get-AzureKeyVaultSecret  -vaultName $KeyVault -Name "publickey" ).SecretValueText