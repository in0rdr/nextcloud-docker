#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# change this to match a local or external ip
# on the docker host
EXT_IP="192.168.1.2"

WEB_ROOT=/var/www/html
APP_DIRNAME=custom_apps # or apps
OCC="$WEB_ROOT/occ"
APACHE_USER=www-data
APACHE_GROUP=root
DEFAULT_PASS=d3faultpass

# install utilities
apt-get update
apt-get install sudo quilt -y

# install nextcloud
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" maintenance:install --admin-user=admin --admin-pass="$DEFAULT_PASS"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:system:set trusted_domains 1 --value="$EXT_IP"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:system:set trusted_domains 2 --value="172.17.0.*"

# enable and configure ldap
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:enable user_ldap
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:create-empty-config
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapHost "$EXT_IP"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapPort "389"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapBase "dc=example,dc=org"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapBaseGroups "dc=example,dc=org"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapBaseUsers "dc=example,dc=org"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapAgentName "cn=admin,dc=example,dc=org"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapAgentPassword "admin"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapGroupFilter "(|(cn=nextcloud))"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapGroupFilterGroups "nextcloud"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapAttributesForGroupSearch "cn"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapAttributesForUserSearch "displayName;mail;uid"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapGroupDisplayName "cn"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapUserDisplayName "cn"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapGidNumber "gidNumber"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapUserFilter "(|(objectclass=inetOrgPerson))"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapUserFilterObjectclass "inetOrgPerson"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapLoginFilter "(&(objectclass=inetOrgPerson)(uid=%uid))"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapLoginFilterAttributes "uid"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapExpertUUIDGroupAttr "cn"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapExpertUUIDUserAttr "uid" #for windows ad, choose samaccountname
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapExpertUsernameAttr "uid" #for windows ad, choose samaccountname
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:set-config s01 ldapConfigurationActive 1
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" ldap:test-config s01

# install twofactor plugins
# use a loop, download fails sometimes
#while [ `sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:install twofactor_u2f` ]; do sleep 1; done;
#while [ `sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:install twofactor_totp` ]; do sleep 1; done;

# install richdocuments
while [ `sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:install richdocuments` ]; do sleep 1; done;
# install onlyoffice
while [ `sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:install onlyoffice` ]; do sleep 1; done;

# configure richdocuments
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set richdocuments wopi_url --value="http://$EXT_IP:9980"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set richdocuments public_wopi_url --value="http://$EXT_IP:9980"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set richdocuments disable_certificate_verification --value="yes"

# configure onlyoffice
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:system:set onlyoffice "verify_peer_off" --value=true --type=boolean
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set onlyoffice "DocumentServerUrl" --value="http://$EXT_IP:8880/"

# install full-text search plugins (core, provider and platform plugin)
# - https://decatec.de/home-server/volltextsuche-in-nextcloud-mit-ocr/
# - https://github.com/nextcloud/fulltextsearch/wiki/Basic-Installation
while [ `sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:install fulltextsearch` ]; do sleep 1; done;
while [ `sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:install files_fulltextsearch` ]; do sleep 1; done;
while [ `sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:install fulltextsearch_elasticsearch` ]; do sleep 1; done;

# configure full-text search
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set fulltextsearch search_platform --value="OCA\FullTextSearch_ElasticSearch\Platform\ElasticSearchPlatform"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set fulltextsearch_elasticsearch elastic_host --value="http://$EXT_IP:9200"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set fulltextsearch_elasticsearch elastic_index --value="nextcloud"
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" config:app:set fulltextsearch_elasticsearch analyzer_tokenizer --value="standard"

# create the full-text index
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" fulltextsearch:index

# create test user
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" OC_PASS="$DEFAULT_PASS" "$OCC" user:add frank --password-from-env

# create test share
sharedate=$(date +%s)
# https://docs.nextcloud.com/server/latest/developer_manual/client_apis/WebDAV/basic.html#creating-folders-rfc4918
curl -X MKCOL -u admin:"$DEFAULT_PASS" "http://172.17.0.1:8080/remote.php/dav/files/admin/testshare_$(date +%s)"
# https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/ocs-share-api.html#create-a-new-share
curl -H "OCS-APIRequest: true" -X POST -u admin:"$DEFAULT_PASS" "http://172.17.0.1:8080/ocs/v2.php/apps/files_sharing/api/v1/shares?permissions=15&shareType=0&path=testshare_$sharedate&shareWith=frank"

# fetch patch for "first save bug"
# todo: for patch in patches=()
#curl -L https://patch-diff.githubusercontent.com/raw/nextcloud/richdocuments/pull/805.diff -o /root/805.diff

# adapt if needed
#sed -i 's~ a/~ a/apps/richdocuments/~g' ~/805.diff
#sed -i 's~ b/~ b/apps/richdocuments/~g' ~/805.diff

# patch if needed
#cd "$WEB_ROOT/$APP_DIRNAME/richdocuments"
#quilt import "$HOME/805.diff"
#quilt push -a

# fetch patches
#quilt series
#quilt applied

# cleanup if needed
cleanup() {
	quilt pop -a
	rm -rf .pc patches/
}
