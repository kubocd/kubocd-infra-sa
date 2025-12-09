
# kubo7 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo7 <<EOF
address=/lb.kubo7.mbp/172.18.109.0
address=/m0.kubo7.mbp/172.18.109.1 
address=/s0.kubo7.mbp/172.18.109.2 
address=/w0.kubo7.mbp/172.18.109.3 
address=/w1.kubo7.mbp/172.18.109.4 
address=/w2.kubo7.mbp/172.18.109.5 
address=/first.pool.kubo7.mbp/172.18.109.6 
address=/.ingress.kubo7.mbp/172.18.109.6
address=/ldap.kubo7.mbp/172.18.109.7
address=/minio.kubo7.mbp/172.18.109.8
address=/last.pool.kubo7.mbp/172.18.109.9 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping xxxx.ingress.kubo7.mbp
```


## Cluster creation

WARNING: See use local registry if applicable

NB: 
Value before config, on m48
node.allocatable.cpu: 14
node.allocatable.memory: 24572448Ki

To have a clean memory value, for example 4Gi, set system-reserved memory to (24572448 - (4x1024*1024))Ki = 20378144Ki

```
cat >/tmp/kubo7-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo7
nodes:
  - role: control-plane
    dockerIP: m0.kubo7.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            system-reserved: "cpu=12,memory=20378144Ki"
  - role: worker
    dockerIP: s0.kubo7.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            system-reserved: "cpu=12,memory=20378144Ki"
            register-with-taints: "node-role.kubernetes.io=services:NoSchedule"     
    labels:
      node-role.kubernetes.io: services  
  - role: worker
    dockerIP: w0.kubo7.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            system-reserved: "cpu=12,memory=20378144Ki"
  - role: worker
    dockerIP: w1.kubo7.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            system-reserved: "cpu=12,memory=20378144Ki"
  - role: worker
    dockerIP: w2.kubo7.mbp
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            system-reserved: "cpu=12,memory=20378144Ki"
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5453
EOF
```


```
kind-fip create cluster --config /tmp/kubo7-config.yaml

docker exec -it kubo7-control-plane bash -c "update-ca-certificates"
docker exec kubo7-worker bash -c "update-ca-certificates"
docker exec kubo7-worker2 bash -c "update-ca-certificates"
docker exec kubo7-worker3 bash -c "update-ca-certificates"
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
docker update --restart=no kubo7-control-plane
docker update --restart=no kubo7-worker
docker update --restart=no kubo7-worker2
docker update --restart=no kubo7-worker3
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
--path=clusters/kind/m48/kubo7/flux

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
