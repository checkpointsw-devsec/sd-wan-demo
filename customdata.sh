#!/bin/bash
ping 127.0.0.1 -c 120 > null

sic_key=${sic_key}
gateway_name=${gateway_name}
pwhash=$(/usr/bin/openssl passwd -1 ${admin_password})
time_zone=${time_zone}
admin_shell=${admin_shell}
eth0_addr='${eth0_addr}'
eth1_addr='${eth1_addr}'
token='${maas_token}'
version='${version}'

cat << EOFT >  /home/admin/ftw.txt
hostname=$gateway_name                   
ftw_sic_key=$sic_key
install_security_managment=false
install_security_gw=true
gateway_daip=false
install_ppak=true
gateway_cluster_member=false
download_info=true
upload_info=true
timezone=$time_zone
maintenance_hash='$pwhash'
admin_hash='$pwhash'
EOFT

dos2unix /home/admin/ftw.txt

config_system.orig --config-file /home/admin/ftw.txt

clish -c "set user admin shell $admin_shell" -s

# ########################################################
# create a bash script to execute on reboot 
# ########################################################
cat <<EOT > /home/admin/additional-tasks.sh
#!/bin/bash
source /opt/CPshrd-$version/tmp/.CPprofile.sh

timestamp () {
  date +"%Y-%m-%d_%H-%M-%S"
}

ping 127.0.0.1 -c 120 > null

echo \$(timestamp) ": remove crontab to avoid reboot loop" >> /home/admin/additional.log
clish -c "delete cron job additional" -s

echo \$(timestamp) ": update deploymant agent" >> /home/admin/additional.log
clish -c "installer agent update"

echo \$(timestamp) ": set maas tunnel token" >> /home/admin/additional.log
clish -c "set security-gateway cloud-mgmt-service on auth-token $token" -s

echo \$(timestamp) ": get recommended JHF" >> /home/admin/additional.log
# clish -c "lock database override"
# clish -c "installer download-and-install "

echo \$(timestamp) ": sd wan next-hop interface" >> /home/admin/additional.log
# clish -c "set interface eth0 sdwan next-hop $eth0_addr tag 'ISP1'" -s
# clish -c "set interface eth1 sdwan next-hop $eth1_addr tag 'ISP2'" -s

echo \$(timestamp) ": additional task done!" >> /home/admin/additional.log

EOT

# ########################################################
# prepare crontab  
# ########################################################
chmod 755 /home/admin/additional-tasks.sh

echo "flag file for sic" > /home/admin/sic_flag_file.log
clish -c "add cron job additional command /home/admin/additional-tasks.sh recurrence system-startup" -s

ping 127.0.0.1 -c 120 > null

reboot
