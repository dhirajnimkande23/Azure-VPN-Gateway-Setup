 # Variables
ON_PREM_GATEWAY_IP="203.0.113.10"  # replace with real public IP
ON_PREM_ADDRESS_PREFIX="192.168.1.0/24"
LOCAL_NETWORK_GATEWAY_NAME="MyOnPremiseGateway"
CONNECTION_NAME="MyS2SConnection"
SHARED_KEY="myS2Ssharedkey"

# Create Local Network Gateway (on-prem VPN details)
az network local-gateway create \
  --resource-group $RG_NAME \
  --name $LOCAL_NETWORK_GATEWAY_NAME \
  --gateway-ip-address $ON_PREM_GATEWAY_IP \
  --local-address-prefixes $ON_PREM_ADDRESS_PREFIX

# Create Site-to-Site VPN connection
az network vpn-connection create \
  --resource-group $RG_NAME \
  --name $CONNECTION_NAME \
  --vnet-gateway1 $VPN_GATEWAY_NAME \
  --local-gateway2 $LOCAL_NETWORK_GATEWAY_NAME \
  --shared-key $SHARED_KEY \
  --enable-bgp false
