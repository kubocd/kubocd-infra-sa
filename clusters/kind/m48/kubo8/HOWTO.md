
# kubo8 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo8 <<EOF
address=/lb.kubo8.mbp/172.18.110.0
address=/m0.kubo8.mbp/172.18.110.1 
address=/m1.kubo8.mbp/172.18.110.2 
address=/m2.kubo8.mbp/172.18.110.3 
address=/w0.kubo8.mbp/172.18.110.4 
address=/w1.kubo8.mbp/172.18.110.5 
address=/w2.kubo8.mbp/172.18.110.6 
address=/first.pool.kubo8.mbp/172.18.110.7 
address=/.ingress.kubo8.mbp/172.18.110.7
address=/ldap.kubo8.mbp/172.18.110.8
address=/minio1.kubo8.mbp/172.18.110.9
address=/last.pool.kubo8.mbp/172.18.110.9 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo8.mbp
```


## Cluster creation

WARNING: See use local registry if applicable

```
cat >/tmp/kubo8-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo8
loadBalancer:
  dockerIP: lb.kubo8.mbp
nodes:
  - role: control-plane
    dockerIP: m0.kubo8.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: control-plane
    dockerIP: m1.kubo8.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: control-plane
    dockerIP: m2.kubo8.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: worker
    dockerIP: w0.kubo8.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: worker
    dockerIP: w1.kubo8.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
  - role: worker
    dockerIP: w2.kubo8.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5454
EOF
```

```
kind-fip create cluster --config /tmp/kubo8-config.yaml

docker exec -it kubo8-control-plane bash -c "update-ca-certificates"
docker exec -it kubo8-control-plane2 bash -c "update-ca-certificates"
docker exec -it kubo8-control-plane3 bash -c "update-ca-certificates"
docker exec -it kubo8-worker bash -c "update-ca-certificates"
docker exec -it kubo8-worker2 bash -c "update-ca-certificates"
docker exec -it kubo8-worker3 bash -c "update-ca-certificates"

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
docker update --restart=no kubo8-control-plane
docker update --restart=no kubo8-control-plane2
docker update --restart=no kubo8-control-plane3
docker update --restart=no kubo8-worker
docker update --restart=no kubo8-worker2
docker update --restart=no kubo8-worker3
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
--path=clusters/kind/m48/kubo8/flux

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
