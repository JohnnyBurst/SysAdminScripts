# Hyper-V setup Nat Network


# Criando o VSwitch nat
New-VMSwitch -SwitchName "SW-NAT" -SwitchType Internal

# Obtendo o ID da interface criada automaticamente e conectada no vswitch nat.
$ifindex = (Get-NetAdapter -Name "vEthernet (SW-NAT)").IfIndex

# Configurando um IP estático nesta interface do switch.
New-NetIPAddress -IPAddress 172.16.50.1 -PrefixLength 24 -InterfaceIndex $ifindex

# Definindo a interface com NAT
New-NetNat -Name NatNetwork -InternalIPInterfaceAddressPrefix 172.16.50.0/24