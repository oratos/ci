# [oratos-ci](https://oratos.ci.cf-app.com/)

This repository contains the CI pipelines for the Oratos Team.

## How to target a CFCR cluster

__PRE-REQUISITE__: You need access to our vault cluster.


We have `./scripts/cfcr.sh` in order to target specific CFCR environements.

```bash
$ ./scripts/cfcr.sh
cfcr.sh: <subcommand> <environment>

Subcommands:                                                                                                                                                                                                          │368       allowedHostPaths:¬
   get-credentials         set kubernetes context                                                                                                                                                                     │369       - pathPrefix: /var/log¬
   get-credentials-tunnel  set kubernetes context, using a temporary ssh tunnel                                                                                                                                       │370         readOnly: false¬
                                                                                                                                                                                                                      │371       - pathPrefix: /var/lib/docker/containers¬
Development Subcommands:                                                                                                                                                                                              │372         readOnly: true¬
   print-env           display the bosh/credhub env vars                                                                                                                                                              │373       - pathPrefix: /var/vcap/store¬
   delete-bbl-state    delete all of the bbl state                                                                                                                                                                    │374         readOnly: true¬
   download-bbl-state  download bbl state from vault
```

For example, in order to target the acceptance cluster.

```bash
$ ./scripts/cfcr.sh get-credentials bikepark
Cluster "bikepark" set.
User "bikepark-admin" set.
Context "bikepark" modified.
Switched to context "bikepark".

$ kubectl config current-context
bikepark
```
