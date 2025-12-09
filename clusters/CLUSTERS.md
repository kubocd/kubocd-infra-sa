

# kubo1:

The cluster to work on kubocd:
- NO kubocd installed
- FluxCD installed
- Installed as helm releases:
  - Cert-manager
  - Ingress
  - metallb

# kubo2:

A cluster with system auto bootstrap to support kubauth in dev mode (Running on host)

# kubo3:

To have a SKAS reference deployment
Auto bootstrap with base system

# kubo4

A cluster aimed to support the kubocd demo.
- kubocd v0.2.1
- Auto bootstrap
- Only base system installed

# kubo5

Auto bootstrap cluster to work on kubauth

# kubo6

Auto bootstrap cluster to be used for kubauth-doc

# kubo7

Multi nodes (1 + 1 + 3) cluster for pod placement test

# kubo8 

Multi node (3 + 3) cluster. Work on kubauth

# kubo9

Multi worker nodes cluster (1 + 3). Work on scheduling