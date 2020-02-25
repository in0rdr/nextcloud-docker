# Nextcloud with Collabora Docker Test Scripts

These scripts are used to test-drive different combinations of Nextcloud, Collabora Online and richdocuments (the Collabora plugin for Nextcloud) in Docker containers.

#### Contents:
* [Requirements and Assumptions](#requirements-and-assumptions)
* [Usage](#usage)
  * [How Do I install Docker again?](#how-do-i-install-docker-again)
  * [Nextcloud OCC Script](#nextcloud-occ-script)
  * [OpenLDAP](#openldap)
* [Cleanup](#cleanup)
* [Customization](#customization)
  * [Software Versions](#software-versions)
  * [Init LDAP Test Data](#init-ldap-test-data)
* [Links](#links)

## Requirements and Assumptions
The Docker host network (`docker0`) is `172.17.0.1/16` and that the port mappings are as follows:
* `8080:80`: Apache2 with Nextcloud (http, no tls) maps to host port `8080` (inital login credentials see table below)
* `9980:9980`: Collabora Online maps to host port `9980`
* `7780:443`: phpLDAPAdmin maps to host port `7780` (login credentials see [#OpenLDAP](#OpenLDAP))

Nextcloud login credentials:
```
| Username | Password        | Type |
| -------- | --------------- | ---- |
| admin    | d3faultpass     | db   |
| frank    | d3faultpass     | db   |
| hmuster  | hmuster         | ldap |
```
The ldap user needs to be created manually, see [#Init LDAP Test Data](#Init-LDAP-Test-Data)

[Install](#how-do-i-install-docker-again) a recent version of Docker.

Install docker-compose with `pip install --user docker-compose` (or similar command).

## Usage
Change the external IP in the file `configure.sh`:
```
# change this to match a local or external ip
# on the docker host
EXT_IP=192.168.1.2
```

Prepare [Elasticsearch image](https://www.docker.elastic.co/) for [full-text search](https://github.com/nextcloud/fulltextsearch/wiki/Basic-Installation):
```
docker image pull docker.elastic.co/elasticsearch/elasticsearch:7.6.0
docker image tag docker.elastic.co/elasticsearch/elasticsearch:7.6.0 elasticsearch:latest
```

Start the containers:
```
docker-compose up
```

* Access Collabora on the Docker host: `http://$EXT_IP:9980/hosting/discovery`
* Access Nextcloud on the Docker host: `http://$EXT_IP:8080`
* Access phpLDAPAdmin on the Docker host: `https://$EXT_IP:7780` (login credentials see [section #OpenLDAP](#OpenLDAP))

### How Do I install Docker again?

If you are reading this I strongly assume you know how to install Docker. If not, refer to the [Docker docs](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-engine---community) or follow these simple steps to install on Ubuntu/Debian.

[Install using the repository](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-engine---community):
```
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce
sudo systemctl start docker
```

[Post-installation](https://docs.docker.com/install/linux/linux-postinstall/):
```
sudo usermod -aG docker $USER
newgrp docker
```

### Nextcloud OCC Script
```
# get a shell in the Docker container
docker exec -it nextcloud_base bash

# execute the script with correct permissions (as www-data)
root@fbce90ee3ab6:/var/www/html# chsh -s /bin/bash www-data
root@fbce90ee3ab6:/var/www/html# su - www-data
www-data@fbce90ee3ab6:~$ ./html/occ status
  - installed: true
  - version: 18.0.0.10
  - versionstring: 18.0.0
  - edition:
```

### OpenLDAP
```
Login DN: "cn=admin,dc=example,dc=org"
Password: "admin"
```

* https://github.com/osixia/docker-phpLDAPadmin

## Cleanup
```
# delete the containers
docker rm nextcloud_config nextcloud_base lool onlyoffice openldap phpldapadmin
# purge the nextcloud datadir volume
volumes=(ncdata oolog oodata oooffice oopsql openldapdata)
for v in "${volumes[@]}"; do docker volume rm  "$(basename `pwd` | tr '[:upper:]' '[:lower:]')_$v"; done;

# cleanup all containers and volumes
for d in $(docker ps -qa); do docker rm $d; done
docker volume prune
```

## Customization
### Software Versions
* Nextcloud and Collabora versions can be adjusted with the `image` tags in the `docker-compose.yml` file. 
* The code fetches the current version of the `richdocuments` plugin, however, earlier version can be installed (todo, add to `configure.sh`):
```
curl -L https://github.com/nextcloud/richdocuments/releases/download/v3.4.6/richdocuments.tar.gz -o richdocuments-3.4.6.tar.gz
tar -xf richdocuments-3.4.6.tar.gz
chown -R "$APACHE_USER":"$APACHE_GROUP" richdocuments
rm -rf "$WEB_ROOT/$APP_DIRNAME/richdocuments"
mv richdocuments "$WEB_ROOT/$APP_DIRNAME/"
# toggle the app, otherwise, Nextcloud thinks an update is required (which is not the case for testing)
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:disable richdocuments
sudo -u "$APACHE_USER" -g "$APACHE_GROUP" "$OCC" app:enable richdocuments
```

The `configure.sh` creates the following users:

| Username | Password |
| -------- | ---------|
| admin    | d3faultpass  |
| frank    | d3faultpass  |

It creates test folder with the name `testshare_$date`, where `$date` is the current timestamp.

`admin` is the owner of this folder and the folder is shared with `frank`.

More advanced setups/test can be implemented using the following APIs:
* https://docs.nextcloud.com/server/latest/developer_manual/client_apis/WebDAV/basic.html
* https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/ocs-share-api.html

### Init LDAP Test Data
Execute the script with the test data on the ldap container:
```
docker cp ldap-test.sh openldap:/root/
docker exec -it openldap ./root/ldap-test.sh
adding new entry "cn=nextcloud,dc=example,dc=org"
adding new entry "cn=Hans Muster,cn=nextcloud,dc=example,dc=org"
```

The nextcloud plugin `user_ldap` is configured accordingly in the script `configure.sh`.

This will create the following test user in the group `nextcloud`:
* username: `hmuster`
* password: `hmuster`

Or get a shell on the ldap Docker container:
```
docker exec -it openldap bash
# apply ldap-test.sh and/or any modifications
```

## Links
* https://hub.docker.com/_/nextcloud
* https://hub.docker.com/r/collabora/code
* https://docs.nextcloud.com/server/latest/admin_manual/configuration_user/user_auth_ldap.html