
## Provision Concourse Cluster

Before you run this script make sure to install:

- [helm][helm]
- [kubectl][kubectl]
- [gcloud][gcloud]
- [lpass][lpass]

You will need to login to gcloud via:

```bash
gcloud auth login
```

You will need to login to lpass via:

```bash
lpass login
```

Additionally, you will need to have your secrets setup in lastpass as a note.
This note should follow the format:

```yaml
secrets:
  some-secret: value
  some-other-secret: value
```

You will need to configure the path to this note under `LASTPASS_SECRETS_PATH`
at the top of the script.

You will also need to configure the helm values, primarily `externalURL` at
the top of the script.

You will also need to enable the Kubernetes Engine API for your project.

[gcloud]: https://cloud.google.com/sdk/
[lpass]: https://github.com/lastpass/lastpass-cli
[helm]: https://github.com/kubernetes/helm/releases/latest
[kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
