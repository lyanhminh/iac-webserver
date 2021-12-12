#!/bin/bash
old_ip=$(cat old_ip.txt)
#Get new ip of instance
ip=$(aws ec2 describe-instances --filters Name=tag:Name,Values=MinhsProject1-ec2 --filters Name=instance-state-name,Values=running | jq '.Reservations[0].Instances[0].PublicIpAddress' | sed 's/\"//g')
echo "current instance ip: ${ip}"
#Update inventory file with new IP
sed -i -E "s|^(.*\..*\..*\..*) (ansible.*)|$ip \2|" inventory
sed -i -E "s|^(null) (ansible.*)|$ip \2|" inventory

#Update keychain agent by replacing the old ip
sed -i -E "s/(${old_ip:-null})/${ip}/g" ~/.ssh/config

ansible-playbook -i inventory playbook.yml

echo "${old_ip}" > old_ip.txt
