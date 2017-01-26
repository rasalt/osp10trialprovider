#/bin/bash
# Assumptions
# Nodes are labelled as control and compute respectively in the node name
# There are no storage nodes
# ntp server is ntp.pool.org
# basic deploy
# TODO:
#    Step 5: Add info about root disks: Not required in my deployment yet as its VM based

source ~/stackrc
error=0

#Step1: Check state 

for i in $(openstack baremetal node list | grep -v "Provisioning State" | awk ' { print $11 } '); do
    if [ "$i" != "available" ]; then
      error=$((error+1))
    fi
done

if [ $error -ne "0" ]; then
    echo "Error: power or provision state incorrect"
    exit 2
fi

#Step2: Check the number of computes 
# There should be atleast 1 compute and 1 or 3 controllers
 
#Compute flavors 

anycompute=$(openstack baremetal node list | grep "compute" | grep -v "UUID" | awk ' { print $2} ')
anycompute=${#anycompute[@]}
echo $anycompute

if [ $anycompute -eq "0" ]; then
    echo "Error: There should be atleast 1 compute node"
    exit 2
fi

for i in $(openstack baremetal node list | grep "compute" | grep -v "UUID" | awk ' { print $2} '); do
    openstack baremetal node set --property capabilities='profile:compute,boot_option:local' $i 
done

#Controller flavors

anycontrol=$(openstack baremetal node list | grep "controller" | grep -v "UUID" | awk ' { print $2} ')
anycontrol=${#anycontrol[@]}
echo $anycontrol

if [ $anycontrol -ne "1" ] && [ $anycontrol -ne "3" ]; then
    echo "Error: There should be 1 or 3 controller nodes"
    exit 3
fi

for i in $(openstack baremetal node list | grep "control" | grep -v "UUID" | awk ' { print $2} '); do
    openstack baremetal node set --property capabilities='profile:control,boot_option:local' $i
done

#Step3: 
openstack overcloud profiles list

#Step4: default deploy

#1 . Delete an overcloudrc if it exists
if [ -f "overcloudrc" ]; then
    echo "Deleting overcloudrc file"
    rm overcloudrc
fi

#openstack overcloud deploy --templates \
#    --ntp-server ntp.pool.org --control-scale $anycontrol --compute-scale $anycompute \
#    --neutron-tunnel-types vxlan --neutron-network-type vxlan

openstack overcloud deploy --templates  -e /home/stack/templates/advanced-networking.yaml   --compute-flavor compute --control-flavor control --compute-scale 1 --control-scale 1 --ceph-storage-scale 0 --neutron-network-type vxlan --neutron-tunnel-types vxlan --ntp-server pool.ntp.org --neutron-bridge-mappings datacentre:br-ex,provider:br-provider


#Step5: check for successful deployment
# 1. Ensure overcloudrc is created

if [ ! -f "overcloudrc" ]; then
    echo "Error: overcloud deployment failed"
    exit 2
fi
# 2. Ensure nova list has a non None instance id

 
#Step6: Check Provision state for the 
error=0
for i in $(openstack baremetal node list | grep -v "Provisioning State" | awk ' { print $11 } '); do
    if [ "$i" != "active" ]; then
      error=$((error+1))
    fi
done
for i in $(openstack baremetal node list | grep -v "Provisioning State" | awk ' { print $9 } '); do  
    if [ "$i" != "on" ]; then    
       error=$((error+1))
    fi
done
for i in $(openstack baremetal node list | grep -v "Provisioning State" | awk ' { print $6 } '); do  
    if [ "$i" == "None" ]; then    
       echo "Node UUID is $i"
       error=$((error+1))
    fi
done
if [ $error -ne "0" ]; then
    echo "Error: provisioning/Power state or UUID incorrect"
    openstack baremetal node list
    exit 1
fi

echo "Deployment successful"
exit 0

# After deployment 
#[stack@manager ironic_scripts]$ openstack baremetal node list
#+--------------------------------------+--------------------------+--------------------------------------+-------------+--------------------+-------------+
#| UUID                                 | Name                     | Instance UUID                        | Power State | Provisioning State | Maintenance |
#+--------------------------------------+--------------------------+--------------------------------------+-------------+--------------------+-------------+
#| 36f7927b-1ad6-4de0-8070-60fef11f84d8 | overcloud-controller-nw1 | 71461e90-01fe-48af-bb3a-095a3837525d | power on    | active             | False       |
#| 25da5892-b4ca-4d58-a72a-df8aafdfe0a2 | overcloud-compute-nw1    | 9c30ed5a-47fd-411a-8075-402a250128f1 | power on    | active             | False       |
#+--------------------------------------+--------------------------+--------------------------------------+-------------+--------------------+-------------+

