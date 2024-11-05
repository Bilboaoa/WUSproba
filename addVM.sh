resourcegroup="myResourceGroupCLI"
az group create --name $resourcegroup --location westeu

location="westus3"
vmname="myVM"
username="azureuser"
az vm create \
    --resource-group $resourcegroup \
    --name $vmname \
    --image UbuntuLTS \
    --public-ip-sku Standard \
    --admin-username $username 