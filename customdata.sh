#!/bin/bash
clish -c "set user admin shell ${admin_shell}" -s
config_system -s "hostname=${gateway_name}&ftw_sic_key=${sic_key}&install_security_gw=true&gateway_daip=false&install_ppak=true&gateway_cluster_member=false&install_security_managment=false&download_info=true"
reboot
