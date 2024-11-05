resourcegroup="myResourceGroupCLI"
az group create --name $resourcegroup --location westeurope

location="westus3"
vmname="myVM"
username="azureuser"
az vm create \
    --resource-group $resourcegroup \
    --name $vmname \
    --image Ubuntu2204 \
    --public-ip-sku Standard \
    --admin-username $username \
    --generate-ssh-keys
