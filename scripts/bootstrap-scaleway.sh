#!/usr/bin/env bash
# One-time Scaleway + GitHub setup for Sight. Run it on your own machine:
#
#   scw init          # log in to Scaleway once (opens a prompt for your own API key)
#   gh auth login     # log in to GitHub once
#   ./scripts/bootstrap-scaleway.sh
#
# What it does (safe to re-run; existing resources are reused):
#   1. Finds or creates the Scaleway project "sight".
#   2. Finds or creates the IAM application "sight-github-actions" and its policy
#      (project: Containers, Container Registry, Serverless SQL, Object Storage; organization: IAMManager).
#   3. Creates the OpenTofu state bucket (fr-par, private, versioned) if it doesn't exist.
#   4. Generates a new API key for the application and stores the four values as GitHub
#      Actions secrets on the repo. The secret key is never printed.
set -euo pipefail

REPO="${REPO:-tsoyland/sight}"
PROJECT_NAME="${PROJECT_NAME:-sight}"
APP_NAME="${APP_NAME:-sight-github-actions}"
POLICY_NAME="${POLICY_NAME:-sight-github-actions}"
BUCKET="${BUCKET:-sight-tobba-tofu-state}"   # must match infra/backend.hcl
REGION="fr-par"
PROJECT_PERMISSIONS=(ContainersFullAccess ContainerRegistryFullAccess ServerlessSQLDatabaseFullAccess ObjectStorageFullAccess)
ORG_PERMISSIONS=(IAMManager)

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mError: %s\033[0m\n' "$*" >&2; exit 1; }

for tool in scw gh jq; do
  command -v "$tool" >/dev/null || die "'$tool' is not installed. scw: https://github.com/scaleway/scaleway-cli  gh: https://cli.github.com  jq: https://jqlang.org"
done
scw info >/dev/null 2>&1 || die "scw is not configured. Run 'scw init' first."
gh auth status >/dev/null 2>&1 || die "gh is not logged in. Run 'gh auth login' first."

ORG_ID="$(scw config get default-organization-id)"
[ -n "$ORG_ID" ] || die "No default organization in scw config. Run 'scw init'."
say "Organization: $ORG_ID"

# 1. Project
say "Project '$PROJECT_NAME'"
PROJECT_ID="$(scw account project list name="$PROJECT_NAME" -o json | jq -r --arg n "$PROJECT_NAME" 'map(select(.name == $n)) | .[0].id // empty')"
if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID="$(scw account project create name="$PROJECT_NAME" description="Sight audience insights app" -o json | jq -r .id)"
  echo "Created project $PROJECT_ID"
else
  echo "Using existing project $PROJECT_ID"
fi

# 2. IAM application + policy
say "IAM application '$APP_NAME'"
APP_ID="$(scw iam application list name="$APP_NAME" -o json | jq -r --arg n "$APP_NAME" 'map(select(.name == $n)) | .[0].id // empty')"
if [ -z "$APP_ID" ]; then
  APP_ID="$(scw iam application create name="$APP_NAME" description="Deploys Sight from GitHub Actions" -o json | jq -r .id)"
  echo "Created application $APP_ID"
else
  echo "Using existing application $APP_ID"
fi

say "IAM policy '$POLICY_NAME'"
POLICY_ID="$(scw iam policy list application-ids.0="$APP_ID" -o json | jq -r --arg n "$POLICY_NAME" 'map(select(.name == $n)) | .[0].id // empty')"
if [ -z "$POLICY_ID" ]; then
  args=(name="$POLICY_NAME" description="Sight deploy: project resources + IAM for the database login" application-id="$APP_ID"
        rules.0.project-ids.0="$PROJECT_ID" rules.1.organization-id="$ORG_ID")
  for i in "${!PROJECT_PERMISSIONS[@]}"; do args+=("rules.0.permission-set-names.$i=${PROJECT_PERMISSIONS[$i]}"); done
  for i in "${!ORG_PERMISSIONS[@]}"; do args+=("rules.1.permission-set-names.$i=${ORG_PERMISSIONS[$i]}"); done
  POLICY_ID="$(scw iam policy create "${args[@]}" -o json | jq -r .id)"
  echo "Created policy $POLICY_ID"
else
  echo "Policy already exists ($POLICY_ID); leaving its rules unchanged"
fi

# 3. State bucket (created with your own credentials, in the sight project)
say "State bucket '$BUCKET' ($REGION)"
if scw object bucket get "$BUCKET" region="$REGION" project-id="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Bucket exists; making sure versioning is on"
  scw object bucket update "$BUCKET" enable-versioning=true region="$REGION" project-id="$PROJECT_ID" >/dev/null
else
  scw object bucket create "$BUCKET" enable-versioning=true acl=private region="$REGION" project-id="$PROJECT_ID" >/dev/null \
    || die "Could not create bucket '$BUCKET' (names are global; it may be taken). Re-run with BUCKET=<other-name> and update infra/backend.hcl."
  echo "Created bucket"
fi

# 4. API key -> GitHub secrets
say "API key for '$APP_NAME' -> GitHub secrets on $REPO"
KEY_JSON="$(scw iam api-key create application-id="$APP_ID" default-project-id="$PROJECT_ID" description="GitHub Actions for $REPO ($(date -u +%Y-%m-%d))" -o json)"
ACCESS_KEY="$(jq -r .access_key <<<"$KEY_JSON")"
SECRET_KEY="$(jq -r .secret_key <<<"$KEY_JSON")"
unset KEY_JSON
[ -n "$ACCESS_KEY" ] && [ -n "$SECRET_KEY" ] && [ "$SECRET_KEY" != "null" ] || die "API key creation returned no secret key."

gh secret set SCW_ACCESS_KEY              --repo "$REPO" --body "$ACCESS_KEY"
gh secret set SCW_SECRET_KEY              --repo "$REPO" --body "$SECRET_KEY"
gh secret set SCW_DEFAULT_PROJECT_ID      --repo "$REPO" --body "$PROJECT_ID"
gh secret set SCW_DEFAULT_ORGANIZATION_ID --repo "$REPO" --body "$ORG_ID"
unset SECRET_KEY

say "Done"
cat <<SUMMARY
Project:      $PROJECT_ID ($PROJECT_NAME)
Application:  $APP_ID ($APP_NAME)
API key:      $ACCESS_KEY (secret stored only in GitHub)
State bucket: $BUCKET ($REGION, versioned)
GitHub:       SCW_ACCESS_KEY, SCW_SECRET_KEY, SCW_DEFAULT_PROJECT_ID, SCW_DEFAULT_ORGANIZATION_ID set on $REPO

Older API keys of '$APP_NAME' (from earlier runs) can be deleted in the console: IAM > Applications > $APP_NAME > API keys.
Next: tell Claude the secrets are in; it will re-run the PR's plan and then deploy.
SUMMARY
