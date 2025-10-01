

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

A cluster aimed to support the demo.
- kubocd v0.2.1
- Auto bootstrap
- Only base system installed

# kubo5

Auto bootstrap cluster to test kubauth (no kit)

# kubo6

Auto bootstrap cluster to test kubauth (only kit, no kubauth-server)

# kubo7

Auto bootstrap cluster to test kubauth (kit and kubauth-server)
