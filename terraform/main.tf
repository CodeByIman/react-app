provider "azurerm" {
  features {} 
  subscription_id = "5f3c303a-a847-45fc-9aee-f27bf8119ebb"
}

# Définition du groupe de ressources
resource "azurerm_resource_group" "devops_rg" {
  name     = "DevOpResourceGroup"
  location = "North Europe"  
}

# Création du réseau virtuel (VNet)
resource "azurerm_virtual_network" "devops_vnet" {
  name                = "DevOpsVNet"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  address_space       = ["10.0.0.0/16"]
}

# Création du sous-réseau
resource "azurerm_subnet" "devops_subnet" {
  name                 = "DevOpsSubnet"
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Création du groupe de sécurité réseau
resource "azurerm_network_security_group" "devops_nsg" {
  name                = "DevOpsNSG"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowK8sAPI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowEtcd"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowKubelet"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowNodePorts"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPHTTPS"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80-443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Association des NIC aux NSG
resource "azurerm_network_interface_security_group_association" "master_nic_nsg" {
  network_interface_id      = azurerm_network_interface.master_nic.id
  network_security_group_id = azurerm_network_security_group.devops_nsg.id
}

resource "azurerm_network_interface_security_group_association" "worker_nic_nsg" {
  network_interface_id      = azurerm_network_interface.worker_nic.id
  network_security_group_id = azurerm_network_security_group.devops_nsg.id
}

# Création des adresses IP publiques
resource "azurerm_public_ip" "master_public_ip" {
  name                = "MasterPublicIP"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "worker_public_ip" {
  name                = "WorkerPublicIP"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Création des interfaces réseau (NIC)
resource "azurerm_network_interface" "master_nic" {
  name                = "MasterNIC"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  ip_configuration {
    name                          = "MasterIPConfig"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    public_ip_address_id          = azurerm_public_ip.master_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "worker_nic" {
  name                = "WorkerNIC"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  ip_configuration {
    name                          = "WorkerIPConfig"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    public_ip_address_id          = azurerm_public_ip.worker_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Création de la machine virtuelle Master Node
resource "azurerm_linux_virtual_machine" "master" {
  name                = "resismart-master-vm"
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"

  network_interface_ids = [azurerm_network_interface.master_nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Création de la machine virtuelle Worker Node
resource "azurerm_linux_virtual_machine" "worker" {
  name                = "K8sWorker"
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"

  network_interface_ids = [azurerm_network_interface.worker_nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Affichage des adresses IP publiques
output "master_ip" {
  description = "Adresse IP publique du Master Node"
  value       = azurerm_public_ip.master_public_ip.ip_address
}

output "worker_ip" {
  description = "Adresse IP publique du Worker Node"
  value       = azurerm_public_ip.worker_public_ip.ip_address
}