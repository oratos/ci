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

### Creating a sink-resources-release final release
1. Run the `cut-final-release` job in CI.
1. Update the new draft release in
   [sink-resources-release](https://github.com/pivotal-cf/sink-resources-release/releases)
1. Use instructions from
   [pks-releng-toolbox](https://github.com/pivotal-cf/pks-releng-toolbox/blob/master/CONTRIBUTING.md)
   to prepare a pull request to [PKS](https://github.com/pivotal-cf/p-pks-integrations)

### Creating a new testing cluster:
1. Create a `bbl` env in GCP in `bbl-state` directory.
1. `git init` in `bbl-state`
1. Clean `bbl-state` with `git clean -ffdX` to remove Terraform binaries.
1. Tar the directory: `tar czf bbl-state.tgz bbl-state/`
1. Base64 encode the tarball: `cat bbl-state.tgz | base64 > bbl-state.tgz.enc`
1. Write that to a new vault var: `vault write secret/envs/<new cluster>-bbl-state tarball=@bbl-state.tgz.enc`
1. Copy GCP creds from oratos-ci-testing-cfcr cluster: `vault read --field=vars.yml secret/envs/oratos-ci-testing-cfcr-gcp-vars > vars.yml`
1. Update vars for the new CFCR cluster in `vars.yml`.
    1. worker and master service can be the same
    1. service accounts need GCP permissions [as described in the
       documentation](https://docs.pivotal.io/tkgi/1-8/gcp-service-accounts.html).
1. Write vars file to a new vault key: `vault write secret/envs/<new cluster>-gcp-vars vars.yml=@vars.yml`
1. In pipeline:
    1. Set `cfcr-bbl-state` key and `cfcr-gcp-vars` key in pipeline.
    1. Update value of `ENV_DNS_NAME` in `configure-dev-dns-zone` job.
1. Create a VPN firewall on the network created by CFCR deploy allowing all IPs to send traffic to all cluster nodes
    (by label) on ports 8443 and 443
    1. label: `bosh-oratos-ci-testing-cfcr-worker`
    1. label: `bosh-oratos-ci-testing-cfcr-master`

### Dealing with vault:
You may have to restart a vault pod at some point. Here's how:
1. Log in to gcloud via cf-pks-observability1 team
2. Run `gcloud container clusters list`. You should see an "oratos-vault" cluster.
3. Run `gcloud container clusters get-credentials oratos-vault` (with zone if you don't have a default)
4. `kubectl get pods -n oratos-vault` to find the dead pod(s)
5. `kubectl delete pod -n oratos-vault -l app=vault` to delete the dead pod(s)
6. For each new pod that comes up, unseal using port forwarding:
    - `kubectl port-forward <new pod name> 8200 -n oratos-vault`
    - In another terminal tab, run `echo $VAULT_ADDR` to see the vault url.
    - Change this env var to the local port specified in the last command and pass it into the following vault command:
      `VAULT_ADDR=http://localhost:8200 vault operator unseal`
    - Enter the "unseal key" found in Vault. (Folder "Shared-CF-Oratos", Name "Vault Key")
7. Your new pod should be up!
