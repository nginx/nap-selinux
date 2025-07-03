## Troubleshooting SELinux Issues

### 1. Modify the existing rules in the selinux policy file as given below (nginx-ap-protect.te)

```shell
cd selinux_policy

sudo vim nginx-app-protect.te
```
#modify line 'allow httpd_t nap-compiler_var_t:file { create getattr setattr lock unlink open read write rename execute execute_no_trans ioctl map link };' to
```shell
allow httpd_t nap-compiler_var_t:file { create getattr setattr lock unlink open read write rename execute_no_trans ioctl map link };
```

### 2. Remove existing binary selinux policy file,and build, load the policy again

```shell
sudo make -f /usr/share/selinux/devel/Makefile clean

make -f /usr/share/selinux/devel/Makefile nginx-app-protect.pp

sudo semodule -i nginx-app-protect.pp

sudo semodule -lfull | grep nginx-app-protect
```

Above steps can also be executed by running

```shell
sudo ./reload_policy.sh
``` 

### 3. Run the test_selinux.sh script
```shell
sudo ../test_scripts/test_selinux.sh
```

### 4. Check for SELinux Denials

Any denials from above script will be displayed on the console or can check under /etc/app_protect/selinux_logs_interpreted, /etc/app_protect/selinux_logs_raw

View all SELinux denials manually with:
```shell
sudo ausearch -m AVC -ts recent 
```
```shell
sudo ausearch --success no --message AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR
```

**Denial Example for the above policy:**  

a. **Execution Denials (Two Occurrences)**

time->Mon Jun 16 14:56:59 2025
type=PROCTITLE msg=audit(1750085819.310:3295): proctitle=7368002D63002F6F70742F6170705F70726F746563742F62696E2F636F6E6669675F7365745F6170706C79202D69202F6F70742F6170705F70726F746563742F636F6E6669672F636F6E6669675F7365742E6A736F6E202D2D706F6C6963792D6D61702D6C6F636174696F6E3D2F6F70742F6170705F70726F746563742F6264
type=SYSCALL msg=audit(1750085819.310:3295): arch=c000003e syscall=59 success=no exit=-13 a0=559929d8bbe0 a1=559929d8bd60 a2=559929d89100 a3=1b6 items=0 ppid=47243 pid=47244 auid=4294967295 uid=991 gid=991 euid=991 suid=991 fsuid=991 egid=991 sgid=991 fsgid=991 tty=(none) ses=4294967295 comm="sh" exe="/usr/bin/bash" subj=system_u:system_r:httpd_t:s0 key=(null)
type=AVC msg=audit(1750085819.310:3295): avc:  denied  { execute } for  pid=47244 comm="sh" name="config_set_apply" dev="dm-1" ino=498 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:nap-compiler_var_t:s0 tclass=file permissive=0

time->Mon Jun 16 14:56:59 2025
type=PROCTITLE msg=audit(1750085819.310:3296): proctitle=7368002D63002F6F70742F6170705F70726F746563742F62696E2F636F6E6669675F7365745F6170706C79202D69202F6F70742F6170705F70726F746563742F636F6E6669672F636F6E6669675F7365742E6A736F6E202D2D706F6C6963792D6D61702D6C6F636174696F6E3D2F6F70742F6170705F70726F746563742F6264
type=SYSCALL msg=audit(1750085819.310:3296): arch=c000003e syscall=21 success=no exit=-13 a0=559929d8bbe0 a1=1 a2=7ffcea3b6520 a3=0 items=0 ppid=47243 pid=47244 auid=4294967295 uid=991 gid=991 euid=991 suid=991 fsuid=991 egid=991 sgid=991 fsgid=991 tty=(none) ses=4294967295 comm="sh" exe="/usr/bin/bash" subj=system_u:system_r:httpd_t:s0 key=(null)
type=AVC msg=audit(1750085819.310:3296): avc:  denied  { execute } for  pid=47244 comm="sh" name="config_set_apply" dev="dm-1" ino=498 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:nap-compiler_var_t:s0 tclass=file permissive=0

These logs show httpd_t (NGINX) being denied access to execute /opt/app_protect/bin/config_set_apply


### 5. Generating Policy Rules

Policy rules for the shell script will be under /etc/app_protect/selinux_missing_items_policy

Use `audit2allow` to create policy rules manually from denials:
```shell
sudo audit2allow -a  

sudo ausearch -m AVC -ts recent |  audit2allow -a 
```

**Example output for the above denials:**  
#============= httpd_t ==============

allow httpd_t nap-compiler_var_t:file execute;


### 6. Applying Fixes

1. Add the generated rules to your custom policy (/selinux_policy/nginx-app-protect.te file)
```shell
    allow httpd_t nap-compiler_var_t:file execute;
```
2. Recompile and load the updated policy by running below steps.

```shell
#Remove exisiting selinux binary file and tmp files

sudo make -f /usr/share/selinux/devel/Makefile clean
       
#Rebuild policy 

sudo make -f /usr/share/selinux/devel/Makefile nginx-app-protect.pp

#Install updated policy

sudo semodule -i nginx-app-protect.pp  

#Verify if the policy is loaded 

sudo semodule -lfull | grep nginx-app-protect
```
Above steps can also be executed by running

```shell
sudo ./reload_policy.sh
``` 
3. Run test_selinux script and check for denials
```shell
sudo ../test_scripts/test_selinux.sh
```

### 7. Verification 
Repeat steps 4 through 6, addressing each SELinux denial and re-testing until the system shows no additional policy denials or test failures. When this condition is met, you've finalized a policy that supports NGINX App Protect without restrictions.

```shell
sudo ausearch -m AVC -ts recent

sudo ausearch --success no --message AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR
```
