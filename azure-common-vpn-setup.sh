# Variables
LOCATION="eastus"
RG_NAME="MyVPNResourceGroup"
VNET_NAME="MyVNet"
SUBNET_NAME="MySubnet"
GATEWAY_SUBNET_NAME="GatewaySubnet"
VNET_ADDRESS_PREFIX="10.0.0.0/16"
SUBNET_PREFIX="10.0.1.0/24"
GATEWAY_SUBNET_PREFIX="10.0.255.0/27"
PUBLIC_IP_NAME="MyVPNGatewayPublicIP"
VPN_GATEWAY_NAME="MyVPNGateway"
VPN_TYPE="RouteBased"
VPN_SKU="VpnGw1"

# Create Resource Group
az group create --name $RG_NAME --location $LOCATION

# Create Virtual Network
az network vnet create \
  --resource-group $RG_NAME \
  --name $VNET_NAME \
  --address-prefix $VNET_ADDRESS_PREFIX \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix $SUBNET_PREFIX

# Create Gateway Subnet
az network vnet subnet create \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name $GATEWAY_SUBNET_NAME \
  --address-prefix $GATEWAY_SUBNET_PREFIX

# Create Public IP for VPN Gateway
az network public-ip create \
  --resource-group $RG_NAME \
  --name $PUBLIC_IP_NAME \
  --sku Standard

# Create VPN Gateway
az network vnet-gateway create \
  --resource-group $RG_NAME \
  --name $VPN_GATEWAY_NAME \
  --public-ip-address $PUBLIC_IP_NAME \
  --vnet $VNET_NAME \
  --gateway-type Vpn \
  --vpn-type $VPN_TYPE \
  --sku $VPN_SKU \
  --no-wait
