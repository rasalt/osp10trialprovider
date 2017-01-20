openstack network create nova --external --provider-network-type flat --provider-physical-network datacentre
cat ./templates/advanced-networking.yaml
openstack subnet create nova --network nova --dhcp --allocation-pool start=10.0.0.51,end=10.0.0.150 --gateway 10.0.0.1 --subnet-range 10.0.0.0/24


#Typical
neutron net-create management --router:external
neutron subnet-create management 10.0.0.0/24 --name management_subnet --enable-dhcp=False --allocation-pool start=10.0.0.50,end=10.0.0.99 --dns-nameserver 8.8.8.8
openstack network create internal
neutron subnet-create internal 192.168.0.0/24 --name internal_subnet
openstack router create internal_router
neutron router-gateway-set internal_router management
neutron router-interface-add internal_router internal_subnet


#vlan31 tenant network setup
neutron net-create --provider:physical_network tenant --provider:network_type vlan --provider:segmentation_id 31 --tenant-id 520a6b304e1c49368c33cc8a7fbf60a6 vlan31
neutron subnet-create --name vlan31_subnet --enable-dhcp=True --allocation-pool start=190.16.0.100,end=190.16.0.150 --gateway 190.16.0.1 vlan31 190.16.0.0/24

#To connect instances directly on the external network
 neutron net-create public01 --provider:network_type flat --provider:physical_network datacentre --router:external=True --shared
 neutron subnet-create --name public01_subnet --enable-dhcp --allocation-pool start=10.0.0.51,end=10.0.0.70 --gateway 10.0.0.1 public01 10.0.0.0/24 


#To add a provider vlan
neutron net-create provider-vlan31 --provider:network_type vlan --router:external true --provider:physical_network datacentre --provider:segmentation_id 31 --shared
neutron subnet-create --name subnet-provider-vlan31 provider-vlan31 190.16.0.0/24 --enable-dhcp --gateway 190.16.0.1
neutron net-list
Ping to the instance on vlan31 outside of the cloud  
