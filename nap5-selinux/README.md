# NGINX App Protect 5 WAF with SELinux Integration
This project provides tools and documentation for integrating NGINX App Protect 5 WAF with SELinux on RHEL-based systems.

## Overview
NGINX App Protect 5 WAF (Web Application Firewall) integration with SELinux provides an additional layer of security by implementing mandatory access controls. This repository contains SELinux policies, installation scripts, and testing utilities designed for NGINX App Protect 5 deployments.

> **⚠️ Important**: This guide uses a **system that supports systemd** (such as a VM or physical server) and **cannot be run on standard Docker containers or kubernetes deployments****. The test scripts use `systemctl` commands and require full systemd service management capabilities that are not available in most containerized environments.
However, as long as NGINX is deployed on the host system, you can still test and validate SELinux policies, even if NGINX App Protect WAF components run in containers.

## Prerequisites and Dependencies

This section outlines all the requirements, prerequisites, and dependencies needed for deploying NGINX App Protect 5 WAF with SELinux integration on RHEL systems.

### 1. System Requirements
- **Operating System**: RHEL 8/9, CentOS 8/9
- **Red Hat Subscription:** Valid Red Hat Enterprise Linux subscription for package repositories and updates
- **SELinux** Must be available and enabled on the system
- **NGINX App Protect 5:** Ensure NGINX App Protect WAF is installed on your system with valid license files (nginx-repo.crt, nginx-repo.key).
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
### 5. Supported NAP5 Deployment Model
This setup supports NGINX deployment on a host (RHEL VM) with containerized NGINX App Protect WAF (NAP5) components.
* Test SELinux policy integration between host NGINX and containerized WAF.
* Validate system-level security policies with container-based functionality.

### Troubleshooting Prerequisites Issues

#### Common Prerequisite Problems

**1. SELinux Disabled or Not Available**
```bash
# Check if SELinux is installed
rpm -qa | grep selinux

# Enable SELinux if disabled
sudo setenforce 1

# Verify SELinux status
sestatus
```

**2. Missing Development Packages**
```bash
# Verify required packages are installed
rpm -qa | grep -E "(selinux-policy-devel|policycoreutils|make|gcc)"

# Install missing packages
sudo dnf install -y selinux-policy-devel make gcc
```

**3. NGINX Issues**
```bash
# Verify service status
sudo systemctl status nginx

```

**4. systemd Compatibility Issues**
```bash
# Verify systemd is running
sudo systemctl status

# Check service management capabilities
sudo systemctl --version
```

## Installation

### Step 1: Clone Repository

```bash
#command to install git if not present
sudo dnf install git -y

sudo git clone <repository-url>
```

### Step 2: Prepare Installation Files

Ensure the following files are present under /selinux_policy  directory before running the installation script:

- `nginx-app-protect.fc` (File contexts)
- `nginx-app-protect.te` (Type enforcement rules)
- `build_install_policy.sh` (Installation script)

### Step 3: Run Installation Script

Execute the installation script with root privileges:

```bash
cd nap-selinux/nap5-selinux

sudo ./selinux_policy/build_install_policy.sh
```

### Installation Process
The installation script performs the following operations:

1. **System Prerequisites Check**
   - Verifies root privileges
   - Checks SELinux status and availability

2. **SELinux State Management**
   - If disabled: Enables SELinux in permissive mode and prompts for reboot
   - If enforcing: Temporarily sets to permissive mode during installation
   - If permissive: Continues with installation

3. **Package Installation**
   - Installs required packages `selinux-policy-devel`, `make`, `gcc`

4. **Policy Module Building**
   - Compile `nginx-app-protect.pp` from source files (requires `nginx-app-protect.fc`, `nginx-app-protect.te`)

5. **Policy Installation and Verification**
   - Loads the module using `semodule`
   - Confirms the policy is active and properly installed

6. **Apply file contexts**
   - Sets proper SELinux contexts for `/opt/app_protect/` directory

7. **Configuration Testing**
   - Restarts NGINX service to verify compatibility
   - Ensures no immediate conflicts exist

8. **Enforcement Activation**
   - Sets SELinux to enforcing mode
   - Verifies the security mode change

9. **Final Status Report**
   - Displays complete system status
   - Shows SELinux mode and loaded modules

## Testing

### Automated Test Suite

Run the test suite to verify the installation:

```bash
# Execute all tests
sudo ./test_scripts/test_selinux.sh
```

### Test Components

The test suite includes the following validations:

- **Service Management Tests**
  - Start, stop, and restart operations for nginx service
  - Service status verification and dependency checks

- **HTTP Connectivity Tests**
  - Basic connectivity testing with configurable delay intervals
  - Security feature validation and response verification

- **NGINX Configuration Validation**
  - Syntax checking and configuration verification

- **SELinux Audit Log Analysis**
  - Automated analysis of security violations and denials

- **Automatic Policy Generation**
  - Creates policy recommendations for missing permissions
  - Generates human-readable policy suggestions

### Generated Test Files

During testing, the following analysis files are created:

- `selinux_logs_all_contexts` - Complete SELinux event log during testing
- `selinux_logs_raw` - Raw audit entries 
- `selinux_logs_interpreted` - Human-readable audit entry interpretations
- `selinux_missing_items_policy` - Generated policy for missing permissions

### SELinux Operating Modes

- **Permissive Mode**: Logs violations without blocking operations (used during setup and testing)
- **Enforcing Mode**: Actively blocks unauthorized operations (production security mode)

## Troubleshooting

### Common Issues and Solutions

#### NGINX Fails to Start After SELinux Enforcement

**Symptoms**: Service fails to start or restart in enforcing mode

**Solution**:
```bash
# Check recent SELinux audit logs
sudo ausearch -m AVC -ts recent

# Temporarily set to permissive mode for debugging
sudo setenforce 0

# Restart service and test
sudo systemctl restart nginx

# Review and address policy violations before re-enabling enforcement
```

#### Service Management Permission Denials

**Symptoms**: `systemctl` commands fail with permission errors

**Solution**:
```bash
# Check for service control permissions
sudo ausearch -c systemctl -m AVC

# Verify service status
sudo systemctl status nginx
```

#### HTTP Request Processing Failures

**Symptoms**: Web requests are blocked or fail unexpectedly

**Solution**:
```bash
# Check for web-related SELinux denials
sudo ausearch -m AVC | grep httpd

# Enable network connectivity if needed
sudo setsebool -P httpd_can_network_connect 1
```

#### File Context and Permission Issues

**Symptoms**: Files cannot be accessed or have incorrect security contexts

**Solution**:
```bash
# Restore proper file contexts
sudo restorecon -Rv /opt/app_protect/

# Verify file security contexts
sudo ls -Z /opt/app_protect/
```

### Debug Commands

```bash
# Check comprehensive SELinux status
sudo sestatus

# View recent SELinux violations
sudo ausearch -m AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR -ts recent

# Generate policy recommendations from audit logs
sudo ausearch -m AVC -ts recent | grep -v 'nginx.pid' | grep 'httpd\|nap-' | audit2allow -R

# Validate NGINX configuration syntax
sudo nginx -t

# Check detailed service status
sudo systemctl status nginx

# Verify policy module installation
sudo semodule -l | grep nginx-app-protect

# View full module details
sudo semodule -lfull | grep nginx-app-protect
```

### Manual Policy Management

```bash
# Check current SELinux operating mode
getenforce

# Set to permissive mode (for testing)
sudo setenforce 0

# Set to enforcing mode (for production)
sudo setenforce 1

# Remove policy module (if needed)
sudo semodule -r nginx-app-protect

# Test App Protect 5 security features
curl "localhost/<script>"

# Monitor audit logs in real-time
sudo tail -f /var/log/audit/audit.log
```

### Log Locations

- **SELinux audit logs**: `/var/log/audit/audit.log`
- **NGINX error and access logs**: `/var/log/nginx/`

## Security Considerations

### Best Practices

- Always test policies in permissive mode before enabling enforcement
- Regularly review SELinux audit logs for policy violations and security events
- Keep policies updated with App Protect 5 version changes and security updates
- Monitor for new App Protect 5 features that may require additional policy permissions
- Follow the principle of least privilege when adding new permissions to policies
- Implement proper change management procedures for policy modifications

## Development

### Policy Development Workflow

1. **Initial Setup**
   - Run `build_install_policy.sh` to install the base policy module

2. **Testing**
   - Execute `test_selinux.sh` to identify policy gaps and issues.

3. **Policy Analysis and Refinement**
   - Analyze audit logs for patterns and security implications

4. **Policy Implementation**
   - Add required permissions to the policy module source files(.te file)

5. **Validation and Testing**
   - Rebuild and reinstall the updated policy module
   - Re-run tests to ensure all issues are resolved

6. **Production**
   - Deploy to production environment with enforcing mode enabled and monitor for any remaining issues.

### Adding New Permissions

1. Run tests to identify missing permissions
2. Analyze denials and generate policy suggestions
3. Add required permissions to your `.te` policy file
4. Rebuild policy: `make -f /usr/share/selinux/devel/Makefile`
5. Install updated policy: `sudo semodule -i nginx-app-protect.pp`
6. Re-run tests to confirm denials are resolved.
