## Provision Concourse
Before you run this script make sure to install:

- [git][git]
- [vault][vault]
- [bbl][bbl]
- [gcloud][gcloud]
- [bosh][bosh]

You will need to login to gcloud via:

```bash
gcloud auth login
```

You will need to login to vault via:

```bash
vault login -method=userpass username=<user>
```

### Updating the concourse deployment variables
The concourse deployment is driven by variables that are stored in vault. 
In order to modify those variables, following these steps:

```bash
vault read -field=concourse_vars.yml secret/envs/bosh-concourse-vars > /tmp/concourse_vars.yml
vim /tmp/concourse_vars.yml  #make your desired edits
vault write secret/envs/bosh-concourse-vars concourse_vars.yml=@/tmp/concourse_vars.yml
```

### To create a bosh environment and deploy concourse on it use the command below:
```bash
./deploy.sh
```

Currently, there are a couple of manual steps that must be performed after the
concourse deployment is created. These are ...
1. You must update the bbl created loadbalancer to route to the web instances
   of your concourse deployment.
1. You must update the DNS configuration of oratos.ci.cf-app.com to point to 
   the bbl created loadbalancer.

### If all you want is to redeploy concourse, use the command below:
```bash
./deploy_concourse.sh
```

### To delete the concourse deployment and bosh environment run this command: 
```bash
./destroy.sh
````

[gcloud]: https://cloud.google.com/sdk/
[vault]: https://www.vaultproject.io
[bbl]: https://github.com/cloudfoundry/bosh-bootloader
[bosh]: https://bosh.io
[git]: https://git-scm.com
