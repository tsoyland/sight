# Sight infrastructure (Scaleway + OpenTofu)

```
GitHub Actions ──push image──> Container Registry (sight-tobba)
      │
      └─tofu apply──> Serverless Container "sight"  ──TLS + IAM key──>  Serverless SQL Database (PostgreSQL 16)
                          ▲  https://<container_hostname>  (and https://sight.tobba.no once the CNAME exists)
State: Object Storage bucket sight-tobba-tofu-state (fr-par)
```

| File | What it creates |
| --- | --- |
| `registry.tf` | Private Container Registry namespace |
| `database.tf` | Serverless SQL Database (PostgreSQL 16, scales 0–1 vCPU) + a dedicated IAM application/API key the container logs in with |
| `container.tf` | Serverless Container namespace + container (280 mVCPU / 512 MiB, `min_scale` 0 or 1, `max_scale` 1) |
| `domain.tf` | Custom domain `sight.tobba.no` with automatic TLS (only when `enable_custom_domain = true`) |

**Sized for demos at the lowest cost:** both the container and the database scale to zero when nobody is using Sight. The first visitor after a quiet period waits a few seconds while they wake up; warm up before an event to avoid that (see below).

The database is reached over TLS and requires an IAM key: the container uses its own IAM application, which can only read/write Serverless SQL Databases in this project. The connection string is passed to the container as a secret environment variable.

## One-time setup (you)

### 1. Scaleway project and IDs
1. Log in at <https://console.scaleway.com>.
2. Use the default project or create one called `sight` (top-left project switcher → **Create project**).
3. Copy the **Project ID** (Project dashboard → **Settings**) and the **Organization ID** (top-right menu → **Organization settings**).

### 2. API key for GitHub Actions
Recommended: a dedicated IAM application, so the key can't touch anything else.
1. **IAM → Applications → Create application**, name it `sight-github-actions`.
2. **IAM → Policies → Create policy**, attached to that application, with two rules:
   - Scoped to the **`sight` project**: `ContainersFullAccess`, `ContainerRegistryFullAccess`, `ServerlessSQLDatabaseFullAccess`, `ObjectStorageFullAccess`.
   - Scoped to the **organization**: `IAMManager`. This lets OpenTofu create the small IAM application the container uses to log in to the database. It is a broad permission; acceptable for a demo, but keep the GitHub secret safe.
   (If a name differs slightly in the console, pick the matching full-access set for that product.)
3. Open the application → **API keys → Generate API key**. Set **Preferred Object Storage project** to the `sight` project. Copy the **access key** and **secret key** (the secret is only shown once).

### 3. Bucket for OpenTofu state
1. **Object Storage → Create bucket**: name `sight-tobba-tofu-state`, region **Paris (fr-par)**, visibility **Private**.
2. Open the bucket → **Bucket settings → Versioning → Enable** (lets you recover an earlier state).
3. If the name is taken (names are global), choose another and change `bucket` in `infra/backend.hcl`.

### 4. GitHub secrets
In GitHub: **tsoyland/sight → Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
| --- | --- |
| `SCW_ACCESS_KEY` | access key from step 2 |
| `SCW_SECRET_KEY` | secret key from step 2 |
| `SCW_DEFAULT_PROJECT_ID` | Project ID from step 1 |
| `SCW_DEFAULT_ORGANIZATION_ID` | Organization ID from step 1 |

### 5. First deploy
Merge the PR (or **Actions → Deploy → Run workflow**). The first run takes a few minutes. The run summary shows the app URL and the **CNAME target**.

### 6. Custom domain at Domeneshop
1. Log in at <https://domene.shop> → **Domener** → `tobba.no` → **DNS-pekere** → **Legg til ny post**.
2. Host: `sight`, Type: `CNAME`, Data: the CNAME target from the deploy summary (e.g. `sightxxxx-sight.functions.fnc.fr-par.scw.cloud`), TTL: `3600`.
3. Tell Claude when it's added: a one-line PR sets `enable_custom_domain = true`, and Scaleway then issues the TLS certificate for `https://sight.tobba.no`.

## Day-to-day

**Deploys** happen on every merge to `main`: build image → push → `tofu apply` → health check.

**Warm up before an event** (no cold starts): **Actions → Deploy → Run workflow → min_scale = 1**. Afterwards run it again with `min_scale = 0`. Normal deploys keep the current setting.

**Rough monthly cost** (verify against Scaleway's price list):

| Resource | Idle | During a demo |
| --- | --- | --- |
| Serverless Container (280 mVCPU / 512 MiB, scales to zero) | €0 | a few cents per hour |
| Serverless SQL Database (scales to zero) | storage only, cents | a few cents per hour |
| Container Registry + state bucket | cents | – |
| **Total** | **≈ €1–3 / month** | |

Leaving `min_scale = 1` on around the clock would add roughly €15–20/month, so switch it back to 0 after events.

## Running OpenTofu locally

```bash
export SCW_ACCESS_KEY=... SCW_SECRET_KEY=... SCW_DEFAULT_PROJECT_ID=... SCW_DEFAULT_ORGANIZATION_ID=...
export AWS_ACCESS_KEY_ID=$SCW_ACCESS_KEY AWS_SECRET_ACCESS_KEY=$SCW_SECRET_KEY
cd infra
tofu init -backend-config=backend.hcl
tofu plan -var "image_tag=$(tofu output -raw image_tag)" -var "min_scale=$(tofu output -raw min_scale)"
```

Prefer letting GitHub Actions apply, so there's one source of truth.
