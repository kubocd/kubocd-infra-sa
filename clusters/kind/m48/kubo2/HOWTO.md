
# kubo2 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo2 <<EOF
address=/first.pool.kubo2.mbp/172.18.104.1 
address=/.ingress.kubo2.mbp/172.18.104.1 
address=/ldap.kubo2.mbp/172.18.104.2 
address=/minio1.kubo2.mbp/172.18.104.3
address=/minio2.kubo2.mbp/172.18.104.4 
address=/last.pool.kubo2.mbp/172.18.104.9 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo2.mbp
```


## Cluster creation

WARNING: See use local registry if applicable

```
cat >/tmp/kubo2-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo2
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5448
EOF
```

```
kind create cluster --config /tmp/kubo2-config.yaml

docker exec -it kubo2-control-plane bash -c "update-ca-certificates"
```


Remove auto-restart

```
docker update --restart=no kubo2-control-plane
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
--path=clusters/kind/m48/kubo2/flux

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
