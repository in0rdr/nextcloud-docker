#!/usr/bin/env bash

# create test group and user
cat << EOF > group.ldif
dn: cn=nextcloud,dc=example,dc=org
cn: nextcloud
gidnumber: 500
objectclass: posixGroup
objectclass: top
EOF

cat << EOF > user.ldif
dn: cn=Hans Muster,cn=nextcloud,dc=example,dc=org
cn: Hans Muster
gidnumber: 500
givenname: Hans
homedirectory: /home/users/hmuster
loginshell: /usr/sbin/nologin
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Muster
uid: hmuster
uidnumber: 1000
userpassword: {MD5}AkY46CsWpyFCtLZTLw2WdA==
EOF

ldapadd -x -w admin -D cn=admin,dc=example,dc=org -f group.ldif
ldapadd -x -w admin -D cn=admin,dc=example,dc=org -f user.ldif


# Enable LDAP password changes per user
# https://docs.nextcloud.com/server/stable/admin_manual/configuration_user/user_auth_ldap.html#ldap-directory-settings
#
# Access control policies must be configured on the LDAP server to grant permissions for password changes.
# The User DN as configured in Server Settings needs to have write permissions in order to update the
# userPassword attribute.
cat << EOF >> /usr/share/slapd/slapd.conf

    # https://www.openldap.org/doc/admin24/access-control.html#Basic%20ACLs
    # allow users full access to their entry
    access to *
        by self write
EOF

service slapd force-reload