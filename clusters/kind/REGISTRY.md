

# Using local registry

Manage to have:

```
$ tree /Users/sa/dev/certs/
/Users/sa/dev/certs/
|-- ca-odp.crt
|-- host.docker.internal.crt
|-- host.docker.internal.key
|-- localhost.crt
`-- localhost.key
```

And create folder `/Users/sa/dev/registry`


Create registry in docker:

```
docker run -d -p 5001:5000 --restart=always --name registry \
    -v /Users/sa/dev/registry:/var/lib/registry \
    -v /Users/sa/dev/certs:/certs \
     -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/host.docker.internal.crt \
     -e REGISTRY_HTTP_TLS_KEY=/certs/host.docker.internal.key \
     -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    registry:2
```


And create the cluster the following way:

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
