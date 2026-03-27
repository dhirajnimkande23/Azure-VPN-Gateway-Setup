# Azure-VPN-Gateway-Setup

## 📦 Project: **Azure VPN Gateway Setup**

---

## 🔷 Prerequisites

✅ Azure Resource Group
✅ Azure Virtual Network
✅ Azure Gateway Subnet
✅ Azure Public IP
✅ Azure VPN Gateway

---



---

## 🔵 Azure **Site-to-Site VPN (S2S VPN)** vs **Point-to-Site VPN (P2S VPN)**

| Feature                    | **Site-to-Site VPN**                                                          | **Point-to-Site VPN**                                                          |
| :------------------------- | :---------------------------------------------------------------------------- | :----------------------------------------------------------------------------- |
| **Purpose**                | Connects an entire on-premises network (office, datacenter) to an Azure VNet. | Connects individual client devices (like laptops) to an Azure VNet.            |
| **Type of Connection**     | **Network-to-Network**                                                        | **Client-to-Network**                                                          |
| **Typical Use Cases**      | Hybrid cloud, branch office connectivity                                      | Remote developer/admin access, ad-hoc secure access                            |
| **VPN Device Requirement** | Requires a compatible on-prem VPN device (firewall/router)                    | No VPN device needed — uses native VPN clients (Windows, macOS, Linux)         |
| **Connection Initiation**  | Always-on or demand-based from the network gateway                            | User-initiated from the client device                                          |
| **Protocols Supported**    | IKEv2, IPsec                                                                  | OpenVPN, IKEv2, SSTP                                                           |
| **Authentication**         | Typically pre-shared keys (PSK) or certificates                               | Azure AD, Certificates, or RADIUS                                              |
| **Scalability**            | Connects entire networks, scalable for branch offices                         | Meant for a few clients or small teams                                         |
| **Pricing**                | Based on gateway SKU and data transfer                                        | Per connection and data transfer (minimal for light use)                       |
| **Example Scenario**       | Company HQ connects its LAN to Azure VNet over VPN Gateway                    | Developer works remotely on a client machine connecting securely to Azure VNet |

---

## 📊 Visual Example

**Site-to-Site VPN:**

```
[ On-Prem Network ] <--IPSec Tunnel--> [ Azure VPN Gateway ] --> [ Azure VNet ]
```

**Point-to-Site VPN:**

```
[ Laptop/Desktop ] <--VPN Client Connection--> [ Azure VPN Gateway ] --> [ Azure VNet ]
```

---

## 📌 Quick Azure Resource Summary:

* **Both require a VPN Gateway in Azure**
* **Site-to-Site** requires a public-facing IP on the on-prem VPN device
* **Point-to-Site** only needs client software and proper certificates or authentication setup

---

## 🔍 When to use what:

| Scenario                                       | Recommended VPN Type           |
| :--------------------------------------------- | :----------------------------- |
| Permanent connectivity between office & Azure  | **Site-to-Site VPN**           |
| Developers connecting from home/laptop         | **Point-to-Site VPN**          |
| Multiple offices connected to Azure            | **Multiple Site-to-Site VPNs** |
| Ad-hoc troubleshooting or test access to Azure | **Point-to-Site VPN**          |


## 📌 Create Common Resources (for both S2S and P2S)

### 📜 `azure-common-vpn-setup.sh`

```bash
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
```

---

## 🔷 📡 Site-to-Site VPN Setup (connect on-prem VPN device to Azure)

**You’ll need your on-prem VPN public IP and IP address space**

### 📜 `azure-s2s-connection.sh`

```bash
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
```

---

## 🔷 💻 Point-to-Site VPN Setup (client devices connect securely)

### 📜 `azure-p2s-config.sh`

```bash
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
```

👉 For client certificates:
You’ll need to generate a **self-signed root cert** and client cert (on Windows/macOS/Linux) — can help you with those commands too if you’d like.

---

## 📦 📌 How to Run:

```bash
bash azure-common-vpn-setup.sh
bash azure-s2s-connection.sh   # for Site-to-Site
bash azure-p2s-config.sh       # for Point-to-Site
```

---

## ✅ Summary:

* **azure-common-vpn-setup.sh** → creates RG, VNet, GatewaySubnet, Public IP, VPN Gateway
* **azure-s2s-connection.sh** → defines local network gateway (on-prem) and S2S connection
* **azure-p2s-config.sh** → configures VPN Gateway for P2S connections with address pool and cert

Excellent — let’s do both cleanly ✅
I'll package this as:

* 📦 **Terraform module** — production-ready, modular and parameterized
* 📦 **Bicep template** — clean declarative ARM infrastructure-as-code

---

## 📦 Terraform Module — Azure VPN Setup

📁 **Repo Structure**

```
azure-vpn-hybrid-terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── providers.tf
```

---

### 📜 `providers.tf`

```hcl
provider "azurerm" {
  features {}
}
```

---

### 📜 `variables.tf`

```hcl
variable "location" { default = "eastus" }
variable "resource_group_name" { default = "MyVPNResourceGroup" }
variable "vnet_name" { default = "MyVNet" }
variable "vnet_address_space" { default = ["10.0.0.0/16"] }
variable "subnet_prefix" { default = "10.0.1.0/24" }
variable "gateway_subnet_prefix" { default = "10.0.255.0/27" }
variable "public_ip_name" { default = "MyVPNGatewayPublicIP" }
variable "vpn_gateway_name" { default = "MyVPNGateway" }
variable "vpn_sku" { default = "VpnGw1" }
variable "vpn_type" { default = "RouteBased" }
variable "s2s_shared_key" { default = "myS2Ssharedkey" }
variable "onprem_gateway_ip" { default = "203.0.113.10" }
variable "onprem_address_prefix" { default = ["192.168.1.0/24"] }
```

---

### 📜 `main.tf`

```hcl
resource "azurerm_resource_group" "vpn_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "MySubnet"
  resource_group_name  = azurerm_resource_group.vpn_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vpn_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

resource "azurerm_public_ip" "vpn_gateway_pip" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = var.vpn_gateway_name
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  type                = "Vpn"
  vpn_type            = var.vpn_type
  active_active       = false
  enable_bgp          = false
  sku                 = var.vpn_sku

  ip_configuration {
    name                          = "vpngwconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }
}

resource "azurerm_local_network_gateway" "onprem" {
  name                = "MyOnPremiseGateway"
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  gateway_address     = var.onprem_gateway_ip
  address_space       = var.onprem_address_prefix
}

resource "azurerm_virtual_network_gateway_connection" "s2s_connection" {
  name                            = "MyS2SConnection"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.vpn_rg.name
  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id        = azurerm_local_network_gateway.onprem.id
  shared_key                      = var.s2s_shared_key
}
```

---

### 📜 `outputs.tf`

```hcl
output "vpn_gateway_public_ip" {
  value = azurerm_public_ip.vpn_gateway_pip.ip_address
}
```

---

## 📌 To Deploy:

```bash
terraform init
terraform apply -auto-approve
```

---

## 📦 Azure Bicep Template

📁 **azure-vpn.bicep**

```bicep
param location string = 'eastus'
param resourceGroupName string = 'MyVPNResourceGroup'
param vnetName string = 'MyVNet'
param vnetAddressSpace string = '10.0.0.0/16'
param subnetPrefix string = '10.0.1.0/24'
param gatewaySubnetPrefix string = '10.0.255.0/27'
param publicIpName string = 'MyVPNGatewayPublicIP'
param vpnGatewayName string = 'MyVPNGateway'
param vpnType string = 'RouteBased'
param vpnSku string = 'VpnGw1'

resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: [vnetAddressSpace] }
    subnets: [
      { name: 'MySubnet' properties: { addressPrefix: subnetPrefix } }
      { name: 'GatewaySubnet' properties: { addressPrefix: gatewaySubnetPrefix } }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-03-01' = {
  name: publicIpName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource vpngw 'Microsoft.Network/virtualNetworkGateways@2024-03-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: vpnType
    sku: { name: vpnSku }
    ipConfigurations: [
      {
        name: 'vpngwconfig'
        properties: {
          publicIPAddress: { id: pip.id }
          subnet: { id: vnet.properties.subnets[1].id }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

output vpnGatewayIp string = pip.properties.ipAddress
```

---

## 📌 To Deploy:

```bash
az deployment group create --resource-group MyVPNResourceGroup --template-file azure-vpn.bicep
```


