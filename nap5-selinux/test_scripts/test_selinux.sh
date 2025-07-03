#!/bin/sh

set -ex

# check required tools
ausearch -v
audit2allow --version

policy_file="selinux_missing_items_policy"
logs_file="selinux_logs"

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

# systemctl
systemctl stop nginx
systemctl start nginx
systemctl restart nginx
systemctl status --no-pager nginx

# curl
curl localhost
sleep 5
curl localhost
curl "localhost/<script>"
