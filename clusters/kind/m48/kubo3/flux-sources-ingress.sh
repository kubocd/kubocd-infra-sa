
# For access to source from external (use --sourceControllerOverride flux-sources.ingress.kubo4.mbp)

export MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${MYDIR}/.kubeconfig

kubectl apply -f - <<EOF
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: flux-sources
    namespace: flux-system
  spec:
    ingressClassName: nginx
    rules:
    - host: flux-sources.ingress.kubo3.mbp
      http:
        paths:
        - backend:
            service:
              name: source-controller
              port:
                number: 80
          path: /
          pathType: Prefix
EOF

kubectl apply -f - <<EOF
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: allow-fetching
    namespace: flux-system
  spec:
    ingress:
      - from:
          - namespaceSelector: {}
        ports:
          - port: 9090
            protocol: TCP
    podSelector: {}
    policyTypes:
      - Ingress
EOF