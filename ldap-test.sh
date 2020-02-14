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