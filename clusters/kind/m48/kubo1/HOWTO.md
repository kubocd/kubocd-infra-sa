
# kubo1 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo1 <<EOF
address=/first.pool.kubo1.mbp/172.18.103.1 
address=/.ingress.kubo1.mbp/172.18.103.1 
address=/ldap.kubo1.mbp/172.18.103.2 
address=/minio1.kubo1.mbp/172.18.103.3 
address=/minio2.kubo1.mbp/172.18.103.4 
address=/last.pool.kubo1.mbp/172.18.103.9 
EOF



sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo1.mbp
ping minio2.kubo1.mbp
```


## Cluster creation

See REGISTRY.md


```
cat >/tmp/kubo1-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo1
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5447
EOF
```

```
kind create cluster --config /tmp/kubo1-config.yaml
```


```
docker exec -it kubo1-control-plane bash -c "update-ca-certificates"
```

Check `1 added`:

```
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

```
export GITHUB_USER=SergeAlexandre
export GITHUB_REPO=kubocd-infra-sa
export GIT_BRANCH=v0.1.2
export GITHUB_TOKEN=

flux bootstrap github \
--owner=${GITHUB_USER} \
--repository=${GITHUB_REPO} \
--branch=${GIT_BRANCH} \
--interval 15s \
--owner kubocd \
--read-write-key \
--path=clusters/kind/m48/kubo1/flux

```

And git pull on kad-infra-sa to update our local copy

# Decrease reaction time on dependencies

In flux-system/kustomization, add patches:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --requeue-dependency=5s
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
```
