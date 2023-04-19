#!/bin/bash
clish -c "set user admin shell ${admin_shell}" -s
config_system -s "hostname=${gateway_name}&ftw_sic_key=${sic_key}&install_security_gw=true&gateway_daip=false&install_ppak=true&gateway_cluster_member=false&install_security_managment=false&download_info=true"
reboot
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

cat << EOFTW >  /home/admin/ftw.txt
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
admin_hash='$pwhash'
EOFTW

config_system.orig --config-file /home/admin/ftw.txt

clish -c "set user admin shell $admin_shell" -s

# ########################################################
# prepare steering file 
# ########################################################
echo { > /home/admin/sdwan_steering_params.json
echo  "sdw_nexthop_probe_enabled" : 0 >> /home/admin/sdwan_steering_params.json
echo } >> /home/admin/sdwan_steering_params.json


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

echo timestamp ": up again after ftw" > /home/admin/additional.log
echo \$(timestamp) ": override default deployment rules" >> /home/admin/additional.log
touch /opt/DDR/override_DDR

echo \$(timestamp) ": remove crontab to avoid reboot loop" >> /home/admin/additional.log
clish -c "delete cron job additional" -s

echo \$(timestamp) ": update deploymant agent" >> /home/admin/additional.log
clish -c "installer agent update"

echo \$(timestamp) ": get sd-wan package from aws" >> /home/admin/additional.log
curl_cli -k 'https://cloudguard-ipu.s3.eu-west-3.amazonaws.com/azure_blink_image_1.1_Check_Point_R81.10_T54_SecurityGateway.tgz' -o '/var/log/tmp/Check_Point_R81.10_SD-WAN_T54_SecurityGateway.tgz'
clish -c "lock database override"
clish -c "installer import local /var/log/tmp/Check_Point_R81.10_SD-WAN_T54_SecurityGateway.tgz"
clish -c "installer upgrade 1"

echo \$(timestamp) ": update certificate bundel" >> /home/admin/additional.log
curl_cli -k 'https://dl3.checkpoint.com/paid/5a/5a69c9e15e4edbea7da26ae28329f135/ca-bundle-public-cloud.crt?HashKey=1681065516_af95539c18e4269e0eff3eb143aad64c&xtn=.crt' -o '/home/admin/ca-bundle-public-cloud.crt'
cp /home/admin/ca-bundle-public-cloud.crt $CPDIR/

# echo \$(timestamp) ": install mass tunnel update" >> /home/admin/additional.log
# curl_cli -k 'https://dl3.checkpoint.com/paid/d8/d8ece265c3af152406f4f990a15e2690/Check_Point_R80_40_maas_tunnel_AutoUpdate_Bundle_T49_AutoUpdate.tar?HashKey=1681136962_ebc276d4e1b4b8398c2674bc87e39ba5&xtn=.tar' -o '/home/admin/Check_Point_R80_40_maas_tunnel_AutoUpdate_Bundle_T49_AutoUpdate.tar'
# autoupdatercli install /home/admin/Check_Point_R80_40_maas_tunnel_AutoUpdate_Bundle_T49_AutoUpdate.tar

echo \$(timestamp) ": set maas tunnel token" >> /home/admin/additional.log
clish -c "set security-gateway cloud-mgmt-service on auth-token $token" -s

echo \$(timestamp) ": sd wan next-hop interface" >> /home/admin/additional.log
clish -c "set interface eth0 sdwan next-hop $eth0_addr tag 'ISP1'" -s
clish -c "set interface eth1 sdwan next-hop $eth1_addr tag 'ISP2'" -s

echo \$(timestamp) ": copy steering json file" >> /home/admin/additional.log
mkdir -p "$FWDIR/conf/sdwan/" && cp /home/admin/sdwan_steering_params.json $FWDIR/conf/sdwan/sdwan_steering_params.json

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
