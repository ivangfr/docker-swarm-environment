#!/usr/bin/env bash

MANAGER1_IP=$(docker-machine ip manager1)

ldapadd -x -D "cn=admin,dc=mycompany,dc=com" -w admin -H ldap://$MANAGER1_IP -f ldap/ldap-mycompany-com.ldif
