
# kubo3 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo3 <<EOF
address=/first.pool.kubo3.mbp/172.18.105.1 
address=/.ingress.kubo3.mbp/172.18.105.1 
address=/ldap.kubo3.mbp/172.18.105.2 
address=/minio1.kubo3.mbp/172.18.105.3 
address=/minio2.kubo3.mbp/172.18.105.4 
address=/last.pool.kubo3.mbp/172.18.105.9
EOF



sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo3.mbp
```


## Cluster creation

See REGISTRY.md


```
cat >/tmp/kubo3-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo3
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5449
EOF
```

```
kind create cluster --config /tmp/kubo3-config.yaml
```


```
docker exec -it kubo3-control-plane bash -c "update-ca-certificates"
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
export GIT_BRANCH=v0.2.0
export GITHUB_TOKEN=

flux bootstrap github \
--owner=${GITHUB_USER} \
--repository=${GITHUB_REPO} \
--branch=${GIT_BRANCH} \
--interval 15s \
--owner kubocd \
--read-write-key \
--path=clusters/kind/m48/kubo3/flux

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

# Deployment kubocd

```
cd ..../kubocd-infra-sa/clusters/kind/m48/kubo3
kubectl create ns kubocd

helm upgrade -i -n kubocd kubocd-ctrl  ../../../../../kubocd/helm/kubocd-ctrl/ --values ./values-ctrl.yaml
```

If cert-manager is ok:

```
helm upgrade -i -n kubocd kubocd-wh  ../../../../../kubocd/helm/kubocd-wh/ --values ./values-wh.yaml
```

# Uninstall kubocd

```
kubectl get releases --all-namespaces
helm -n kubocd uninstall kubocd-wh
helm -n kubocd uninstall kubocd-ctrl
kubectl delete ns kubocd
kubectl delete crds releases.kubocd.kubotal.io contexts.kubocd.kubotal.io configs.kubocd.kubotal.io

kubectl get crds | grep kubocd

```
