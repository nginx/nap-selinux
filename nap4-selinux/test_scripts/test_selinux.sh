#!/bin/sh

set -ex

# check required tools
ausearch -v
audit2allow --version

policy_file="selinux_missing_items_policy"
logs_file="selinux_logs"
apcompile_comm='/opt/app_protect/bin/apcompile'
apreload_comm='/opt/app_protect/bin/apreload'
gen_sec_defaults="sudo APP_PROTECT_GENERATE_SECURITY_DEFAULTS=1"

# Get the start test time
start_time=$(date +%H:%M)


# Trap on exit (success or failure)
trap '{
  echo "Collecting SELinux audit logs..."
  ausearch --message AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR --start "${start_time}" --interpret >"${logs_file}_all_contexts" || echo "Nothing new in audit log"
  ausearch --success no --message AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR --start "${start_time}" --raw  >"${logs_file}_raw" || { echo "Nothing new in audit log related to app-protect" && exit 0; }
  ausearch --input "${logs_file}_raw" --interpret >"${logs_file}_interpreted"
  ausearch --input "${logs_file}_raw" | audit2allow -a >"${policy_file}"

  echo "Found new SELinux issues! Policy written to: ${policy_file}"
  set +x
  echo ""
  echo "======== Generated Policy ========"
  cat "${policy_file}"
  echo ""
  echo "======== Interpreted AVC Logs ========"
  cat "${logs_file}_interpreted"
  echo ""
}' EXIT

# Change dir to one with 'nginx' as the owner
cd /etc/app_protect

# Cleaning exisiting logs
echo "Cleaning up old files..."
sudo find . -name "${policy_file}*" -delete 2>/dev/null || true
sudo find . -name "${logs_file}*" -delete 2>/dev/null || true


# Test nginx configuration
echo "Testing NGINX configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "NGINX configuration test failed! Exiting."
    exit 1
fi
echo "NGINX configuration test passed."

test_apreload() {
    /bin/su -s /bin/sh -c "$apreload_comm $@" nginx
}
test_apcompile() {
    $gen_sec_defaults /bin/su -s /bin/sh -c "$apcompile_comm $@" nginx
}


# systemctl
systemctl stop nginx
systemctl start nginx
systemctl restart nginx
systemctl status --no-pager nginx
systemctl stop nginx-app-protect
systemctl start nginx-app-protect
systemctl restart nginx-app-protect
systemctl status --no-pager nginx-app-protect

# curl
curl localhost
sleep 5
curl localhost
curl "localhost/<script>"

# apreload test:
test_apreload
test_apreload '-t'
test_apreload '-apply'
test_apreload '-wait-for-enforcer=true'
test_apreload '-wait-for-enforcer=false'
test_apreload '-i /opt/app_protect/config/config_set.json'
test_apreload '-policy-map-location /opt/app_protect/bd_config/policy_path.map'

# apcompile test:
test_apcompile '-g /opt/app_protect/global.json -p /opt/app_protect/policy.json -o /opt/app_protect/policy_bundle'
test_apcompile '--bundle /opt/app_protect/policy_bundle --dump'
test_apcompile '-l /etc/app_protect/conf/log_default.json -o /opt/app_protect/logbundle --dump'
test_apcompile '--init'
test_apcompile '-p /opt/app_protect/policy.json -o /opt/app_protect/policy_bundle --dump'
test_apcompile '-p /opt/app_protect/grpc_policy.json -o /opt/app_protect/policy_bundle --dump'

# get-signatures test
/opt/app_protect/bin/get-signatures -o /opt/app_protect/sigs.json

# apdiag test (may be ingonerd in cases of problems)
/opt/app_protect/bin/apdiag -f /opt/app_protect/apdiag.tgz

# convert-policy test
/opt/app_protect/bin/convert-policy -i /opt/app_protect/policy.json -f='xml' -o /opt/app_protect/xml_policy.xml
