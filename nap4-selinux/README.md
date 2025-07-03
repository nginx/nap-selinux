# NGINX App Protect WAF with SELinux Integration

This project provides tools and documentation for integrating NGINX App Protect WAF with SELinux on RHEL-based systems.

## Overview

NGINX App Protect WAF (Web Application Firewall) integration with SELinux provides an additional layer of security by implementing mandatory access controls. This repository contains SELinux policies, installation scripts, and testing utilities designed for NGINX App Protect deployments.

> **⚠️ Important**: This guide uses a **system that supports systemd** (such as a VM or physical server) and **cannot be run on standard Docker containers or kubernetes deployments**. The test scripts use `systemctl` commands and require full systemd service management capabilities that are not available in most containerized environments.

## Prerequisites

### 1. System Requirements

- **Operating System**: RHEL 8/9, CentOS 8/9
- **Red Hat Subscription:** Valid Red Hat Enterprise Linux subscription for package repositories and updates
- **SELinux** Must be available and enabled on the system
- **NGINX**: NGINX with App Protect WAF(NAP4) installed and running
- **nginx.conf:** Make sure there is valid nginx.conf file under /etc/nginx/nginx.conf
- **Root/sudo access:** Required for installation and configuration

### 2. Package Installation and Updates
* All necessary packages for SELinux policy development, runtime libraries, and system integration are installed automatically as part of the setup process.
* **The setup process installs the following packages:**
* **Core SELinux Policy Development:**
   * `selinux-policy-devel` - SELinux policy development headers and build system for creating custom policies.
   * `policycoreutils` - Core SELinux policy management utilities including semanage, setsebool, and restorecon.
   * `policycoreutils-devel` - Development files and headers for SELinux policy utilities.
   * `policycoreutils-python-utils` - Python-based SELinux management tools like semanage and audit2allow.
* **SELinux Runtime Libraries:**
   * `libselinux` - Core SELinux runtime library for application integration.
   * `libselinux-utils` - Command-line utilities for SELinux context management and queries.
   * `python3-libselinux` - Python 3 bindings for SELinux library functions and context operations.
   * `python3-policycoreutils` - Python 3 modules for SELinux policy management and analysis.
* **Build and Development Tools:**
   * `make` - Build automation tool required for compiling SELinux policy modules.
   * `m4` - Macro processor used by SELinux policy build system for template expansion.
   * `gcc` - GNU Compiler Collection needed for building SELinux policy components.
* **System Monitoring and Integration:**
   * `audit` - Linux audit framework for monitoring and logging SELinux denials and security events.
   * `curl` - Command-line tool for downloading policy templates and remote resources.
   * `systemd` - System service manager integration for SELinux-aware service management.
   * `vim` - Text editor with SELinux syntax highlighting support for policy development.
* If your application requires additional SELinux packages beyond these core dependencies, add them to your installation scripts based on your specific security policy requirements.


### 3. Certificate and License Management
* If your application uses SSL/TLS or license files, ensure the necessary directories exist and files are copied to the correct locations.
* Validate certificates and keys as required.
* Adjust file locations and permissions based on your application's needs.

### 4. SELinux Enforcement Checks
* Check whether SELinux is enabled and in enforcing or permissive mode.
* Ensure necessary SELinux policy packages and development tools are installed for custom policy development.

```bash
# Check SELinux status
sestatus

# Verify SELinux is enabled and enforcing/permissive
getenforce

# Check audit daemon status
sudo systemctl status auditd

# Command to check the loaded SELinux module
semodule -l

# Check if key SELinux tools are installed
rpm -q policycoreutils selinux-policy selinux-policy-devel

# Check if development tools are installed
rpm -q gcc make libselinux libselinux-utils policycoreutils-python-utils
```

### 5. Repository and Subscription Management
* Ensure your system can access the required repositories for package management.
* For Red Hat systems, update client certificates or subscriptions to authenticate with Red Hat Update Infrastructure if needed.
* For other distributions, ensure repository configuration matches your organizational standards.

## Installation

### 1. Clone Repository

```bash
#command to install git if not present
sudo dnf install git -y

git clone <repository-url>
```
### Step 2: Prepare Installation Files

Ensure the following files are present under /selinux_policy  directory before running the installation script:
- `nginx-app-protect.fc` (File contexts)
- `nginx-app-protect.te` (Type enforcement rules)
- `build_install_policy.sh` (Installation script)

### Step 3: Run Installation Script

Execute the installation script with root privileges:

```bash
sudo cd nap-selinux/nap4-selinux

sudo ./selinux_policy/build_install_policy.sh
```

**The installation script will:**

* **Check system prerequisites**: Verify root privileges and SELinux status
* **Handle SELinux state**:
   * If disabled: Enable SELinux in permissive mode and prompt for reboot
   * If enforcing: Temporarily set to permissive mode
   * If permissive: Continue with installation
* **Install required development packages**: Installs selinux, development tools and system monitoring packages.
* **Build the SELinux policy module**: Compile `nginx-app-protect.pp` from source files (requires `nginx-app-protect.fc`, `nginx-app-protect.te`)
* **Install and verify the policy**: Load the module using `semodule` and confirm it's active
* **Test the configuration**: Restart NGINX service to verify compatibility
* **Enable enforcement**: Set SELinux to enforcing mode and verify the change
* **Provide final status**: Display complete system status including SELinux mode and loaded modules

#### SELinux Modes

- **Permissive Mode**: Logs violations without blocking (used during setup)
- **Enforcing Mode**: Actively blocks unauthorized operations (production mode)

#### Manual Policy Management

```bash
# Check current SELinux mode
getenforce

# Set to permissive mode
sudo setenforce 0

# Set to enforcing mode
sudo setenforce 1

# View installed modules
sudo semodule -l | grep nginx
sudo semodule -lfull | grep nginx-app-protect

# Remove policy module
sudo semodule -r nginx
```

### 3. Run Test Suite

Run the test suite to verify the installation:

```bash
#  Execute all tests
sudo ./test_scripts/test_selinux.sh
```
#### Automated Testing

The test suite includes:

- Service start/stop/restart tests for nginx and nginx-app-protect
- HTTP connectivity tests including security testing
- App Protect functionality tests:
  - `apreload` operations with various parameters
  - `apcompile` policy compilation and bundling
  - `get-signatures` signature updates
  - `apdiag` diagnostic collection
  - `convert-policy` policy format conversion
- SELinux audit log analysis
- Automatic policy generation for missing permissions

#### Manual Testing

```bash
# Test basic NGINX functionality
curl localhost

# Test App Protect security features
curl "localhost/<script>"

# Check SELinux denials
sudo ausearch -m AVC -ts recent

# Monitor audit logs
sudo tail -f /var/log/audit/audit.log
```
#### Generated Test Files

During testing, the following analysis files are created:

- `selinux_logs_all_contexts` - Complete SELinux event log during testing
- `selinux_logs_raw` - Raw audit entries 
- `selinux_logs_interpreted` - Human-readable audit entry interpretations
- `selinux_missing_items_policy` - Generated policy for missing permissions

## Troubleshooting

### Common Issues

#### 1. NGINX Fails to Start After SELinux Enforcement

**Solution**: Check SELinux audit logs and add missing permissions:

```bash
sudo ausearch -m AVC -ts recent
sudo setenforce 0
sudo systemctl restart nginx
```

#### 2. App Protect Binary Execution Denials

**Solution**: Check for missing execute permissions:

```bash
sudo ausearch -c apcompile -m AVC
sudo ausearch -c apreload -m AVC
```

#### 3. Runtime File Access Denials

**Solution**: Verify App Protect runtime paths have proper NAP contexts:

```bash
sudo ls -Z /opt/app_protect/
sudo ausearch -m AVC | grep nap-compiler_var_t
```

### Debug Commands

```bash
# Check SELinux status
sudo sestatus

# View recent SELinux denials
sudo ausearch -m AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR -ts recent

# Generate policy from audit logs
sudo ausearch -m AVC -ts recent | audit2allow -R

# Test NGINX configuration
sudo nginx -t

# Check service status
sudo systemctl status nginx
```
### Log Locations

- **SELinux audit logs**: `/var/log/audit/audit.log`
- **NGINX logs**: `/var/log/nginx/`
- **App Protect logs**: `/var/log/app_protect/`

## Security Considerations

- Always test policies in permissive mode before enforcing
- Regularly review SELinux audit logs for policy violations
- Keep policies updated with App Protect version changes
- Monitor for new App Protect features that may require policy updates
- Follow the principle of least privilege when adding permissions
- The policy uses custom NAP types (`nap-compiler_var_t`, `nap-engine_t`) for enhanced isolation

## Development

### Policy Development Workflow

1. **Initial Setup**: Run `build_install_policy.sh` to install custom policy
2. **Testing**: Execute `test_selinux.sh` to identify policy gaps and issues
3. **Policy Refinement**: Analyze audit logs for patterns and security implications
4. **Implementation**: Add missing permissions to the policy module source files(.te file)
5. **Validation**: Rebuild and reinstall the updated policy module. Re-run tests to ensure all issues are resolved
6. **Production**: Deploy to production environment with enforcing mode enabled and monitor for any remaining issues

### Adding New Permissions

1. Run tests to identify missing permissions
2. Analyze denials and generate policy suggestions
3. Add required permissions to your `.te` policy file
4. Rebuild policy: `make -f /usr/share/selinux/devel/Makefile`
5. Install updated policy: `sudo semodule -i nginx-app-protect.pp`
6. Re-run tests to confirm denials are resolved.
