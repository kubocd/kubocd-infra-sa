
# kubo4 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo4 <<EOF
address=/first.pool.kubo4.mbp/172.18.106.1 
address=/.ingress.kubo4.mbp/172.18.106.1 
address=/ldap.kubo4.mbp/172.18.106.2 
address=/minio1.kubo4.mbp/172.18.106.3
address=/minio2.kubo4.mbp/172.18.106.4 
address=/last.pool.kubo4.mbp/172.18.106.9 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo4.mbp
```


## Cluster creation

WARNING: See use local registry if applicable

```
cat >/tmp/kubo4-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo4
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5450
EOF
```

```
kind create cluster --config /tmp/kubo4-config.yaml
```


Remove auto-restart

```
docker update --restart=no kubo4-control-plane
```

COMMIT LAST UPDATE ON kubocd-infra-sa

```
export GITHUB_REPO=kubocd-infra-sa
export GIT_BRANCH=main
export GITHUB_TOKEN=

flux bootstrap github \
--repository=${GITHUB_REPO} \
--branch=${GIT_BRANCH} \
--interval 15s \
--owner kubocd \
--read-write-key \
--path=clusters/kind/m48/kubo4/flux

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
