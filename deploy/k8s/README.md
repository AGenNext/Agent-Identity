# Deploy Agent Identity on Kubernetes

Vendor-neutral, Kubernetes-native manifests (plain YAML + Kustomize) for the Agent Identity
control plane: **SurrealDB** (the datastore), a **schema-load Job** (loads the grounded model +
seeds), and the **API**. Works on any conformant cluster — including lightweight **k3s**.

```
                    ┌──────────────┐
   Ingress ───────▶ │ agent-identity-api │ ──▶ SurrealDB (rocksdb PVC)
                    └──────────────┘            ▲
                                                │ schema-load Job (once)
                                                │  imports surreal/schema + seeds
```

## Prerequisites

- A Kubernetes cluster + `kubectl` (v1.24+), Kustomize (built into `kubectl -k`).
- A container registry you can push to.

## 1. Build & push the API image

```bash
docker build -t <registry>/agent-identity-api:latest apps/api
docker push  <registry>/agent-identity-api:latest
```

Set that image in `deploy/k8s/kustomization.yaml` (`images:` → `newName`/`newTag`) or edit
`api.yaml`. SurrealDB uses the upstream `surrealdb/surrealdb` image (no build needed).

## 2. Create the secret

```bash
cp deploy/k8s/secret.example.yaml deploy/k8s/secret.yaml
# edit secret.yaml: set a strong SURREAL_PASS and a 32-byte JWT_SECRET (openssl rand -hex 32)
kubectl apply -f deploy/k8s/secret.yaml
```

`secret.yaml` is git-ignored — never commit real secrets. In production use a sealed-secret or
external secret store.

## 3. Load the schema into a ConfigMap

The schema-load Job imports from a ConfigMap built out of the repo's SurrealQL:

```bash
bash deploy/k8s/create-schema-configmap.sh    # run from the repo root
```

## 4. Deploy

```bash
kubectl apply -k deploy/k8s
```

This creates the namespace, SurrealDB (with a 5Gi PVC), runs the one-shot schema-load Job, and
rolls out the API (2 replicas) behind a Service + Ingress.

## 5. Verify

```bash
kubectl -n agent-identity get pods
kubectl -n agent-identity logs job/schema-load           # → "schema + seeds loaded"
kubectl -n agent-identity port-forward svc/agent-identity-api 8080:80
curl http://localhost:8080/health                        # → {"status":"ok", ...}
```

## Notes

- **Persistence:** SurrealDB uses `rocksdb:/data/agent.db` on a RWO PVC (single writer, `Recreate`
  strategy). For HA, move to a SurrealDB cluster (TiKV backend) and a StatefulSet.
- **Re-running the schema Job:** `kubectl -n agent-identity delete job schema-load && kubectl apply -k deploy/k8s`.
  Imports are idempotent for `DEFINE`; seeds use fixed record ids so they upsert.
- **Security hardening:** the API runs non-root, read-only rootfs, all caps dropped. For
  cluster-level CIS hardening on k3s, see the `k3s-harden` guidance.
- **TLS/DNS:** add `ingressClassName`, a real host, and cert-manager TLS in `ingress.yaml`.
