
# kubo5 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo5 <<EOF
address=/first.pool.kubo5.mbp/172.18.107.1 
address=/.ingress.kubo5.mbp/172.18.107.1 
address=/ldap.kubo5.mbp/172.18.107.2 
address=/minio1.kubo5.mbp/172.18.107.3
address=/minio2.kubo5.mbp/172.18.107.4 
address=/last.pool.kubo5.mbp/172.18.107.9 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo5.mbp
```


## Cluster creation

WARNING: See use local registry if applicable

```
cat >/tmp/kubo5-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo5
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5451
EOF
```

```
kind create cluster --config /tmp/kubo5-config.yaml

docker exec -it kubo5-control-plane bash -c "update-ca-certificates"
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
docker update --restart=no kubo5-control-plane
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
--path=clusters/kind/m48/kubo5/flux

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
