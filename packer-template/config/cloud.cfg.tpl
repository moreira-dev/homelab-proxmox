# The top level settings are used as module
# and system configuration.

# Update the contents of /etc/hosts. This will use the name you
# specified when creating the VM in proxmox
manage_etc_hosts: true

# A set of users which may be applied and/or used by various modules
# when a 'default' entry is found it will reference the 'default_user'
# from the distro configuration specified below
users:
   - default

# If this is set, 'root' will not be able to ssh in and they
# will get a message to login instead as the above $user (debian)
disable_root: true

# Change default root password from the preseed file to a random one
chpasswd:
 list: |
  root:RANDOM

# Update apt database on first boot (run 'apt-get update')
apt_update: true

# Upgrade the instance on first boot
apt_upgrade: true

# Reboot after package install/update if necessary
apt_reboot_if_required: true

# Install useful packages
packages:
 - vim

# Write out new SSH daemon configuration. Standard debian 12 configuration
# apart from forbidding root login and disabling password authentication
write_files:
 - path: /etc/ssh/sshd_config
   content: |
      PermitRootLogin no
      PubkeyAuthentication yes
      PasswordAuthentication no
      PermitEmptyPasswords no
      ChallengeResponseAuthentication no
      UsePAM yes
      X11Forwarding yes
      PrintMotd no
      AcceptEnv LANG LC_*
      Subsystem	sftp	/usr/lib/openssh/sftp-server

# The modules that run in the 'init' stage
cloud_init_modules:
 - seed_random
 - write-files
 - growpart
 - resizefs
 - disk_setup
 - mounts
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - users-groups
 - ssh



# The modules that run in the 'config' stage
cloud_config_modules:
 - set-passwords
 - apt-pipelining
 - apt-configure
 - ntp
 - timezone
 - disable-ec2-metadata

# The modules that run in the 'final' stage
cloud_final_modules:
 - package-update-upgrade-install
 - scripts-vendor
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - final-message

final_message: "The system is up, after $UPTIME seconds"

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
   # This will affect which distro class gets used
   distro: debian
   # Default user name + that default users groups (if added/used)
   default_user:
     name: debian
     lock_passwd: True
     gecos: Debian
     groups: [adm, audio, cdrom, dialout, dip, floppy, netdev, plugdev, sudo, video]
     sudo: ["ALL=(ALL) NOPASSWD:ALL"]
     shell: /bin/bash
     ssh_authorized_keys: ${jsonencode(ssh_authorized_keys)}
   paths:
      cloud_dir: /var/lib/cloud/
      templates_dir: /etc/cloud/templates/
      upstart_dir: /etc/init/
   package_mirrors:
     - arches: [default]
       failsafe:
         primary: http://deb.debian.org/debian
         security: http://security.debian.org/
   ssh_svcname: ssh
