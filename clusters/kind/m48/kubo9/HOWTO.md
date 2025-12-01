
# kubo9 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo9 <<EOF
address=/lb.kubo9.mbp/172.18.111.0
address=/m0.kubo9.mbp/172.18.111.1 
address=/w0.kubo9.mbp/172.18.111.2 
address=/w1.kubo9.mbp/172.18.111.3 
address=/w2.kubo9.mbp/172.18.111.4 
address=/first.pool.kubo9.mbp/172.18.111.5 
address=/.ingress.kubo9.mbp/172.18.111.5
address=/ldap.kubo9.mbp/172.18.111.6
address=/minio.kubo9.mbp/172.18.111.7
address=/last.pool.kubo9.mbp/172.18.111.9 
EOF

sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo9.mbp
```


## Cluster creation

WARNING: See use local registry if applicable

```
cat >/tmp/kubo9-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo9
nodes:
  - role: control-plane
    dockerIP: m0.kubo9.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: worker
    dockerIP: w0.kubo9.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: worker
    dockerIP: w1.kubo9.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: worker
    dockerIP: w2.kubo9.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5455
EOF
```

```
kind-fip create cluster --config /tmp/kubo9-config.yaml

docker exec kubo9-control-plane bash -c "update-ca-certificates"
docker exec kubo9-worker bash -c "update-ca-certificates"
docker exec kubo9-worker2 bash -c "update-ca-certificates"
docker exec kubo9-worker3 bash -c "update-ca-certificates"

```

Check `1 added`:

```
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

Remove auto-restart

```
docker update --restart=no kubo9-control-plane
docker update --restart=no kubo9-worker
docker update --restart=no kubo9-worker2
docker update --restart=no kubo9-worker3

```

---------------------------------------------------------------------------------------------------------

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
--path=clusters/kind/m48/kubo9/flux

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

# Client deployment

```
o8
kc init https://kubeconfig.ingress.kubo9.mbp/kubeconfig
```