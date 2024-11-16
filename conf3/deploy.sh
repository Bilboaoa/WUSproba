#!/usr/bin/sh

PREFIX="petclinic"
RESOURCE_GROUP="${PREFIX}-rg"
LOCATION="westeurope"

VNET_NAME="${PREFIX}-vnet"
VNET_SUBNET_NAME="${PREFIX}-subnet"
VM_SIZE="Standard_B1ms"

VM_USER="azuser"
VM_PASSWORD="Pet12345678!"
VM_IMAGE="Ubuntu2204"

VM_FE="${PREFIX}-fe-vm"
VM_FE_PUBLIC_IP_NAME="${VM_FE}-public-ip"
VM_FE_PRIVATE_IP="10.0.1.100"

VM_BE="${PREFIX}-be-vm"
VM_BE_PRIVATE_IP="10.0.2.100"

VM_DB="${PREFIX}-db-vm"
VM_DB_PRIVATE_IP="10.0.3.100"

VM_DB_SLAVE="${PREFIX}-db-slave-vm"
VM_DB_SLAVE_PRIVATE_ID="10.0.3.101"

NGINX_PRIVATE_IP=$VM_SLAVE_PRIVATE_ID

VM_FE_INIT_CMD_PATH="./fe-config.sh"
VM_BE_INIT_CMD_PATH="./api-config.sh"
VM_DB_INIT_CMD_PATH="./db-config.sh"
VM_DB_SLAVE_INIT_PATH="./db-slave.sh"
VM_NG_INIT_CMD_PATH="./nginx.sh"

echo >&2 "<<<<<<<<<<<< CREATING THE $RESOURCE_GROUP RESOURCE GROUP >>>>>>>>>>>>>"

az group create \
--location "$LOCATION" \
--resource-group "$RESOURCE_GROUP"

echo >&2 "<<<<<<<<<<<< CREATING THE NETWORK >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

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
--destination-port-range 8080 22 \
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
--destination-port-range 8081 9966 3306 22 \
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

az network vnet subnet create \
--resource-group "$RESOURCE_GROUP" \
--vnet-name "$VNET_NAME" \
--name "${VNET_SUBNET_NAME}-db" \
--network-security-group be-nsg \
--address-prefixes "10.0.3.0/24"

echo >&2 "<<<<<<<<<<<<<<<<< CREATING VIRTUAL MACHINES >>>>>>>>>>>>>>>"

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
--subnet "${VNET_SUBNET_NAME}-db" \
--private-ip-address "$VM_DB_PRIVATE_IP" \
--public-ip-sku Standard \
--vnet-name "$VNET_NAME" \
--no-wait \

az vm create \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB_SLAVE" \
--size "$VM_SIZE" \
--admin-username "$VM_USER" \
--admin-password "$VM_PASSWORD" \
--image "$VM_IMAGE" \
--subnet "${VNET_SUBNET_NAME}-db" \
--private-ip-address "$VM_DB_SLAVE_PRIVATE_ID" \
--public-ip-address "" \
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

echo >&2 "<<<<<<<<<<<<<<<<< OPENING VM PORTS >>>>>>>>>>>>>>>>>>>>>"

az vm open-port \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_FE" \
--port 22,8080 \

az vm open-port \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_BE" \
--port 22,9966 \

az vm open-port \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB" \
--port 22,3306,9966  \

az vm open-port \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB_SLAVE" \
--port 22,3306,8081  \

echo >&2 "<<<<<<<<<<<<<<<<< INVOKING COMMANDS >>>>>>>>>>>>>>>>>>>>>"

az vm run-command invoke \
--command-id "RunShellScript" \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_FE" \
--scripts @"$VM_FE_INIT_CMD_PATH" \
--parameters $NGINX_PRIVATE_IP $VM_FE_PUBLIC_IP 8081 \
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

az vm run-command invoke \
--command-id "RunShellScript" \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB_SLAVE" \
--scripts @"$VM_DB_SLAVE_INIT_PATH" \
--parameters $VM_DB_PRIVATE_IP 3306
--no-wait \

az vm run-command invoke \
--command-id "RunShellScript" \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB" \
--scripts @"$VM_BE_INIT_CMD_PATH" \
--parameters $VM_DB_PRIVATE_IP \
--no-wait \

az vm run-command invoke \
--command-id "RunShellScript" \
--resource-group "$RESOURCE_GROUP" \
--name "$VM_DB_SLAVE" \
--scripts @"$VM_NG_INIT_CMD_PATH" \
--parameters 8081 $VM_BE_PRIVATE_IP 9966 $VM_DB_PRIVATE_IP 9966 \
--no-wait \

echo >&2 "DEPLOYMENT COMPLETE"
echo >&2 "WEBSITE URL: $VM_FE_PUBLIC_IP:8080"
echo >&2 "SSH CONNECT: \`$ ssh $VM_USER@$VM_FE_PUBLIC_IP\` WITH PASSWORD: $VM_PASSWORD"
