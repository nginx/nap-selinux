## Troubleshooting SELinux Issues

### 1. Modify the existing rules in the selinux policy file as given below (nginx-ap-protect.te)

```shell
cd selinux_policy

sudo vim nginx-app-protect.te
```

#modify line 'allow httpd_t httpd_sys_rw_content_t:file { create read write open unlink getattr setattr rename};' to
```shell
allow httpd_t httpd_sys_rw_content_t:file { create read open unlink getattr setattr rename};
```
### 2. Remove existing binary selinux policy file,and build, load the policy again

```shell
sudo make -f /usr/share/selinux/devel/Makefile clean

sudo make -f /usr/share/selinux/devel/Makefile nginx-app-protect.pp

sudo semodule -i nginx-app-protect.pp

sudo semodule -lfull | grep nginx-app-protect
```

Above steps can also be executed by running

```shell
sudo ./reload_policy.sh
``` 

### 3. Run test_selinux script

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

**Denial Examples for the above policy:**  

a. **VERSION file denial:**  

	time->Fri Jun 27 09:06:46 2025
	type=PROCTITLE msg=audit(1751015206.470:24069): proctitle=6370002F6F70742F6170705F70726F746563742F56455253494F4E002F6F70742F6170705F70726F746563742F636F6E6669672F
	type=SYSCALL msg=audit(1751015206.470:24069): arch=c000003e syscall=257 success=no exit=-13 a0=ffffff9c a1=562ad646ee70 a2=201 a3=0 items=0 ppid=56265 pid=56266 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="cp" exe="/usr/bin/cp" subj=system_u:system_r:httpd_t:s0 key=(null)
	type=AVC msg=audit(1751015206.470:24069): avc:  denied  { write } for  pid=56266 comm="cp" name="VERSION" dev="dm-4" ino=1051352 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:httpd_sys_rw_content_t:s0 tclass=file permissive=0
	

b. **RELEASE file denial:**

	time->Fri Jun 27 09:06:46 2025
	type=PROCTITLE msg=audit(1751015206.473:24070): proctitle=6370002F6F70742F6170705F70726F746563742F52454C45415345002F6F70742F6170705F70726F746563742F636F6E6669672F
	type=SYSCALL msg=audit(1751015206.473:24070): arch=c000003e syscall=257 success=no exit=-13 a0=ffffff9c a1=55f155745e70 a2=201 a3=0 items=0 ppid=56267 pid=56268 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="cp" exe="/usr/bin/cp" subj=system_u:system_r:httpd_t:s0 key=(null)
	type=AVC msg=audit(1751015206.473:24070): avc:  denied  { write } for  pid=56268 comm="cp" name="RELEASE" dev="dm-4" ino=1051354 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:httpd_sys_rw_content_t:s0 tclass=file permissive=0


c. **temp_config_set.json denial:**
    
    time->Fri Jun 27 09:06:46 2025
	type=PROCTITLE msg=audit(1751015206.473:24071): proctitle=2F7573722F7362696E2F6E67696E78002D63002F6574632F6E67696E782F6E67696E782E636F6E66
	type=SYSCALL msg=audit(1751015206.473:24071): arch=c000003e syscall=257 success=no exit=-13 a0=ffffff9c a1=7ffa186e8e78 a2=241 a3=1b6 items=0 ppid=1 pid=56263 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
	type=AVC msg=audit(1751015206.473:24071): avc:  denied  { write } for  pid=56263 comm="nginx" path="/opt/app_protect/config/temp_config_set.json" dev="dm-4" ino=1051366 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:httpd_sys_rw_content_t:s0 tclass=file permissive=0


These logs show httpd_t being denied access to:

1. /opt/app_protect/VERSION (Version denial) - NGINX (under httpd_t) tried to write to the file /opt/app_protect/VERSION.

2. opt/app_protect/RELEASE (Release denial) - NGINX (under httpd_t) attempting to update or copy over RELEASE file was blocked.

3. /opt/app_protect/config/temp_config_set.json (temp_config_set.json denial) - The main nginx process(under httpd_t) tried to write a temporary JSON file into the /opt/app_protect/config/ directory.

### 5. Generating Policy Rules

Policy rules for the shell script will be under /etc/app_protect/selinux_missing_items_policy

Use `audit2allow` to create policy rules manually from denials:
```shell
sudo audit2allow -a  

sudo ausearch -m AVC -ts recent |  audit2allow -a 
```

**Example output for the above denials:**  
#============= httpd_t ==============

#!!!! This avc can be allowed using the boolean 'httpd_builtin_scripting'

allow httpd_t httpd_sys_rw_content_t:file write;

### 6. Applying Fixes

1. Add the generated rules to your custom policy (/selinux_policy/nginx-app-protect.te file)
```shell
    allow httpd_t httpd_sys_rw_content_t:file write;
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
