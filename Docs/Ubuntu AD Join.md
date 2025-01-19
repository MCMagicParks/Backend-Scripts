# How to Join an Ubuntu Server to Active Directory (AD)

**Note:** Ensure the hostname of the server is set before continuing.

## Steps

### 1. Install Prerequisites
```bash
sudo apt install sssd-ad sssd-tools realmd adcli
```

### 2. Verify the Domain is Discoverable via DNS
Run the following command:
```bash
sudo realm -v discover ad.enchantedexperiences.net
```
The output should resemble:
```yaml
 * Resolving: _ldap._tcp.ad.enchantedexperiences.net
 * Performing LDAP DSE lookup on: 192.168.10.10
 * Successfully discovered: ad.enchantedexperiences.net
ad.enchantedexperiences.net
  type: kerberos
  realm-name: AD.ENCHANTEDEXPERIENCES.NET
  domain-name: ad.enchantedexperiences.net
  configured: kerberos-member
  server-software: active-directory
  client-software: sssd
  required-package: sssd-tools
  required-package: sssd
  required-package: libnss-sss
  required-package: libpam-sss
  required-package: adcli
  required-package: samba-common-bin
  login-formats: %U@ad.enchantedexperiences.net
  login-policy: allow-realm-logins
```

### 3. Join the domain
```bash
sudo realm join -v -U tchumbley ad.enchantedexperiences.net
```
Replace `tchumbley` with your domain username.

### 4. Enable Automatic Home Directory Creation
Run:
```bash
sudo pam-auth-update --enable mkhomedir
```
### 5. Install Kerberos Tickets
Run:
```bash
sudo apt install krb5-user
```
### 6. Add `secLinuxAdmins` group to `root`
Edit the sudoers file:
```bash
sudo visudo
```
Add the following lines:
```bash
# Add ENCHANTED\secLinuxAdmins group to root
%secLinuxAdmins@AD.ENCHANTEDEXPERIENCES.NET ALL=(ALL:ALL) ALL
```
### 7. Reboot and Test Login
```bash
sudo reboot
```
Test login with your domain credentials.

### 8. Finalize in Active Directory
Move the new computer object in AD to the appropriate Organizational Unit (OU).