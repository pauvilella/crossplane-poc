# Configuration Package

To package the XRD, the Composition resources and the required providers
into a single OCI image, we can run:

```bash
crossplane xpkg build --ignore=kustomization.yaml
```

And to push:

```bash
echo $GITHUB_PAT | docker login ghcr.io -u pauvilella --password-stdin
crossplane xpkg push ghcr.io/pauvilella/crossplane-poc:0.0.1 --domain=https://ghcr.io
```

And to use this package, we would basically add the whole
package containing everything to our k8s cluster, with:

```yaml
---
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: pauvilella-vpc
spec:
  package: ghcr.io/pauvilella/crossplane-poc:0.0.1
```

This basically substitutes the need to adding all the xrds,
compositions and providers manually to the controlplane cluster.

By just applying this configuration that we've created,
we install everything automatically.
