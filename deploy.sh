#!/usr/bin/sh

PREFIX="petclinic"
RESOURCE_GROUP="${PREFIX}-rg"
LOCATION="westeurope"

VNET_NAME="${PREFIX}-vnet"
VNET_SUBNET_NAME="${PREFIX}-subnet"
VM_SIZE="Standard_B1ms"

VM_USER="snoopdogg"
VM_PASSWORD="Snoopdogg_420"
VM_IMAGE="UbuntuLTS"

VM_FE="${PREFIX}-fe-vm"
VM_FE_PUBLIC_IP_NAME="${VM_FE}-public-ip"
VM_FE_PRIVATE_IP="10.0.1.100"

VM_BE="${PREFIX}-be-vm"
VM_BE_PRIVATE_IP="10.0.2.101"

VM_DB="${PREFIX}-db-vm"
VM_DB_PRIVATE_IP="10.0.2.100"

VM_FE_INIT_CMD_PATH="./fe-config.sh"
VM_BE_INIT_CMD_PATH="./api-config.sh"
VM_DB_INIT_CMD_PATH="./db-config.sh"

echo >&2 "<> CREATING THE $RESOURCE_GROUP RESOURCE GROUP <>"

az group create \
--location "$LOCATION" \
--resource-group "$RESOURCE_GROUP"

echo >&2 "<> CREATING THE NETWORK <>"

az network vnet create \
--resource-group "$RESOURCE_GROUP" \
--name "$VNET_NAME" \
--address-prefixes 10.0.0.0/16

az network nsg create \
--resource-group "$RESOURCE_GROUP" \
--name fe-nsg

az network nsg rule create \
--resource-group "$RESOURCE_GROUP" \
--nsg-name fe-nsg \
--name frontend \
--access allow \
--protocol Tcp \
--direction Inbound \
--destination-port-range 4200 22 \
--source-address-prefix "*" \
--source-port-range "*" \
--destination-address-prefix "*" \
--priority 200 

az network nsg create \
--resource-group "$RESOURCE_GROUP" \
--name be-nsg

az network nsg rule create \
--resource-group "$RESOURCE_GROUP" \
--nsg-name be-nsg \
--name backend \
--access allow \
--protocol Tcp \
--direction Inbound \
--destination-port-range 9966 3306 22 \
--source-address-prefix "*" \
--source-port-range "*" \
--destination-address-prefix "*" \
--priority 200 

az network vnet subnet create \
--resource-group "$RESOURCE_GROUP" \
--vnet-name "$VNET_NAME" \
--name "${VNET_SUBNET_NAME}-fe" \
--network-security-group fe-nsg \
--address-prefixes "10.0.1.0/24"

az network vnet subnet create \
--resource-group "$RESOURCE_GROUP" \
--vnet-name "$VNET_NAME" \
--name "${VNET_SUBNET_NAME}-be" \
--network-security-group be-nsg \
--address-prefixes "10.0.2.0/24"

echo >&2 "<> CREATING VIRTUAL MACHINES <>"

az vm create \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_FE" \
--size "$VM_SIZE" \
--admin-username "$VM_USER" \
--admin-password "$VM_PASSWORD" \
--image "$VM_IMAGE" \
--subnet "$VNET_SUBNET_NAME-fe" \
--private-ip-address "$VM_FE_PRIVATE_IP" \
--public-ip-sku Standard \
--public-ip-address "$VM_FE_PUBLIC_IP_NAME" \
--vnet-name "$VNET_NAME" \
--no-wait \

az vm create \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_BE" \
--size "$VM_SIZE" \
--admin-username "$VM_USER" \
--admin-password "$VM_PASSWORD" \
--image "$VM_IMAGE" \
--subnet "$VNET_SUBNET_NAME-be" \
--private-ip-address "$VM_BE_PRIVATE_IP" \
--public-ip-sku Standard \
--vnet-name "$VNET_NAME" \
--no-wait \

az vm create \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB" \
--size "$VM_SIZE" \
--admin-username "$VM_USER" \
--admin-password "$VM_PASSWORD" \
--image "$VM_IMAGE" \
--subnet "$VNET_SUBNET_NAME-be" \
--private-ip-address "$VM_DB_PRIVATE_IP" \
--public-ip-sku Standard \
--vnet-name "$VNET_NAME" \
--no-wait \

VM_IDS="$(az vm list -g "$RESOURCE_GROUP" --query "[].id" -o tsv)"

echo >&2 "<> WAITING FOR VMS... <>"

# shellcheck disable=SC2086
az vm wait --created --ids $VM_IDS

VM_FE_PUBLIC_IP=$(
	az network public-ip show \
	--resource-group "$RESOURCE_GROUP" \
	--name "$VM_FE_PUBLIC_IP_NAME" \
	--query "ipAddress" \
	--output tsv \
)

echo >&2 "<> OPENING VM PORTS <>"

az vm open-port \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_FE" \
--port 22,4200 \

az vm open-port \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_BE" \
--port 22,9966 \

az vm open-port \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB" \
--port 22,3306  \

az vm run-command invoke \
--command-id "RunShellScript" \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_FE" \
--scripts @"$VM_FE_INIT_CMD_PATH" \
--parameters $VM_BE_PRIVATE_IP $VM_FE_PUBLIC_IP \
--no-wait \

az vm run-command invoke \
--command-id "RunShellScript" \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_BE" \
--scripts @"$VM_BE_INIT_CMD_PATH" \
--parameters $VM_DB_PRIVATE_IP \
--no-wait \

az vm run-command invoke \
--command-id "RunShellScript" \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB" \
--scripts @"$VM_DB_INIT_CMD_PATH" \
--no-wait \

echo >&2 "DEPLOYMENT COMPLETE"
echo >&2 "WEBSITE URL: $VM_FE_PUBLIC_IP:4200"
echo >&2 "SSH CONNECT: \`$ ssh $VM_USER@$VM_FE_PUBLIC_IP\` WITH PASSWORD: $VM_PASSWORD"