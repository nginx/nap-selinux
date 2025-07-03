# SELinux Integration for NGINX App Protect WAF (NAP 4 & 5)

This project provides tools, sample policies, and documentation for integrating **NGINX App Protect WAF (NAP) versions 4 and 5** with **SELinux** on RHEL-based systems.

## Overview

SELinux (Security-Enhanced Linux) provides a mandatory access control (MAC) framework for Linux systems. When deploying NGINX App Protect WAF in secure environments, customizing and enforcing SELinux policies ensures that only explicitly allowed operations are permitted, reducing the attack surface.

This repository contains:
- Custom SELinux Type Enforcement (TE) policies and supporting files(.fc) for NAP 4 and NAP 5
- Scripts for:
  - Building and loading policies
  - Extracting and interpreting SELinux denials from audit logs
  - Automating test cycles with policy generation
- Example AVC denial resolutions

##  Structure
<pre>
.
├── nap4-selinux/
│   ├── selinux_policy/
│   ├── test_scripts/
│   ├── README.md
│   └── troubleshooting.md
├── nap5-selinux/
│   ├── selinux_policy/
│   ├── test_scripts/
│   ├── README.md
│   └── troubleshooting.md
└── README.md
</pre>

## Requirements

-   RHEL 8/9 (or compatible)
-   SELinux installed and enabled
-   NGINX App Protect WAF v4 or v5
