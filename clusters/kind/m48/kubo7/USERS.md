# USERS

-----------------------------------------
## alice (LDAP)

groups:
- staff (LDAP)
- managers (LDAP)

claims:
- office: 312R (local)

roles:
- kubauth-ucrd-admin (group: managers)

-----------------------------------------
## bob (LDAP)

groups:
- staff (LDAP)

-----------------------------------------
## fred (LDAP)

groups:
- staff (LDAP)
- managers (LDAP)

roles:
- kubauth-ucrd-admin (group: managers)

-----------------------------------------
## admin (Local)

groups:
- cluster-admins
- data-ops

claims:
-  policy: consoleAdmin (group: data-ops)

clusterRoles:
- cluster-admin (group: cluster-admins)


-----------------------------------------
## jim (local)

-----------------------------------------
## john (local)

groups: 
- kubauth-admins

roles:
- kubauth-ucrd-admin (group: kubauth-admins)

claims:
- office: 208G (local)





