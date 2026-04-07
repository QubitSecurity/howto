for vm in $(virsh list --all --name ); do
    info=$(echo $(virsh domblklist $vm | awk '{print $1}'))
    storage=$(echo $info | sed "s/.*--- //g" | sed "s/ sda//g" | sed "s/ sdb//g" )
#    echo "$storage"
    sodata=$(echo $(virsh domblkinfo $vm $storage )| sed "s/.*Capacity: //g" | sed "s/ Allocation.*//g")
#    echo "$vm" "$sodata"
    mod1="1073741824"
    sodata=$(expr $sodata / $mod1)

    memdata=$(echo  $(virsh dominfo $vm | grep Max))
    memdata=$(echo "$memdata" | sed "s/.*memory: //g" | sed "s/ KiB//g")
    mod2="1048576"
    memdata=$(expr $memdata / $mod2)



   echo "$vm" "$memdata" "$sodata"

done
