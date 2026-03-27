# Variables
P2S_ADDRESS_POOL="172.16.0.0/24"
CERT_NAME="P2SRootCert"
CERT_PUBLIC_KEY="rootcert.pem"  # must be pre-generated Base64-encoded cert

# Update VPN Gateway config for P2S
az network vnet-gateway update \
  --resource-group $RG_NAME \
  --name $VPN_GATEWAY_NAME \
  --set vpnClientConfiguration.vpnClientAddressPool.addressPrefixes=$P2S_ADDRESS_POOL

# Upload root certificate for client authentication
az network vnet-gateway root-cert create \
  --resource-group $RG_NAME \
  --gateway-name $VPN_GATEWAY_NAME \
  --name $CERT_NAME \
  --public-cert-data "$(cat $CERT_PUBLIC_KEY)"
