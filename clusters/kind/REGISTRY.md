

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


# Registry UI

https://github.com/Joxit/docker-registry-ui

```
docker run \
  --name registry-ui \
  -d \
  -e SINGLE_REGISTRY=true \
  -e REGISTRY_TITLE="Docker Registry UI" \
  -e DELETE_IMAGES=true \
  -e SHOW_CONTENT_DIGEST=true \
  -e NGINX_PROXY_PASS_URL="https://host.docker.internal:5001" \
  -e SHOW_CATALOG_NB_TAGS=true \
  -e CATALOG_MIN_BRANCHES=1 \
  -e CATALOG_MAX_BRANCHES=1 \
  -e TAGLIST_PAGE_SIZE=100 \
  -e REGISTRY_SECURED=false \
  -e CATALOG_ELEMENTS_LIMIT=1000 \
  -p 5003:80 \
  joxit/docker-registry-ui:main


```

http://localhost:5003/
