#!/usr/bin/env bash
# Cabcher - Google Maps key setup (run in Google Cloud Shell)
# Usage: ./setup-maps.sh "https://demo-taxi.com/demo-user-333/*" "203.0.113.10"
#   $1 = allowed HTTP referrer(s) for the Browser key (comma-separated, end with /*)
#   $2 = PUBLIC IP of your server for the Server key (comma-separated for several)
set -uo pipefail

REFERRERS="${1:-}"
SERVER_IP="${2:-}"

if [ -z "$REFERRERS" ]; then
  read -r -p "Website referrer (example: https://demo-taxi.com/demo-user-333/*): " REFERRERS
fi
if [ -z "$SERVER_IP" ]; then
  read -r -p "Server PUBLIC IP (example: 203.0.113.10): " SERVER_IP
fi

case "$REFERRERS" in
  http*://*) ;;
  *) echo "ERROR: referrer must start with http:// or https://"; exit 1 ;;
esac
# Remove spaces before validating the IP addresses
SERVER_IP="${SERVER_IP// /}"

# Allow IPv4, IPv6, and comma-separated IP addresses
if [[ ! "$SERVER_IP" =~ ^[0-9a-fA-F:.,/]+$ ]]; then
  echo "ERROR: server IP looks invalid"
  exit 1
fi

# Private IPs never reach Google, so warn
if [[ "$SERVER_IP" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|127\.) ]]; then
  echo "WARNING: $SERVER_IP is a private address. Google sees your PUBLIC IP."
  read -r -p "Continue anyway? (y/N): " ok
  [ "$ok" = "y" ] || exit 1
fi

PROJECT_ID="cabcher-maps-$RANDOM$RANDOM"
echo ""
echo "==> Creating project $PROJECT_ID"
gcloud projects create "$PROJECT_ID" --name="Cabcher Maps" || { echo "Project creation failed"; exit 1; }
gcloud config set project "$PROJECT_ID" >/dev/null

echo ""
echo "==> Billing (required for Maps to work)"
gcloud billing accounts list --filter="open=true" --format="table(name.basename():label=ACCOUNT_ID,displayName)"
BILLING_ID="$(gcloud billing accounts list --filter='open=true' --format='value(name.basename())' | head -n1)"
COUNT="$(gcloud billing accounts list --filter='open=true' --format='value(name)' | wc -l)"
if [ "$COUNT" -eq 0 ]; then
  echo ""
  echo "No billing account found. Create one here, then run this script again:"
  echo "  https://console.cloud.google.com/billing/create"
  exit 1
elif [ "$COUNT" -gt 1 ]; then
  read -r -p "Enter the ACCOUNT_ID to use: " BILLING_ID
fi
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ID" || {
  echo "Could not link billing. Enable it at https://console.cloud.google.com/billing and re-run."; exit 1; }

echo ""
echo "==> Enabling APIs"
gcloud services enable \
  apikeys.googleapis.com \
  maps-backend.googleapis.com \
  places-backend.googleapis.com \
  places.googleapis.com \
  directions-backend.googleapis.com \
  distance-matrix-backend.googleapis.com \
  geocoding-backend.googleapis.com \
  routes.googleapis.com || { echo "Enabling APIs failed"; exit 1; }

echo ""
echo "==> Creating Browser key (referrer restricted)"
BROWSER_KEY="$(gcloud services api-keys create \
  --display-name="Cabcher Browser" \
  --allowed-referrers="$REFERRERS" \
  --api-target=service=maps-backend.googleapis.com \
  --api-target=service=places-backend.googleapis.com \
  --api-target=service=places.googleapis.com \
  --api-target=service=geocoding-backend.googleapis.com \
  --format='value(response.keyString)' 2>/dev/null)"

echo "==> Creating Server key (IP restricted)"
SERVER_KEY="$(gcloud services api-keys create \
  --display-name="Cabcher Server" \
  --allowed-ips="$SERVER_IP" \
  --api-target=service=directions-backend.googleapis.com \
  --api-target=service=distance-matrix-backend.googleapis.com \
  --api-target=service=geocoding-backend.googleapis.com \
  --api-target=service=places-backend.googleapis.com \
  --api-target=service=places.googleapis.com \
  --api-target=service=routes.googleapis.com \
  --format='value(response.keyString)' 2>/dev/null)"

if [ -z "$BROWSER_KEY" ] || [ -z "$SERVER_KEY" ]; then
  echo "Key creation did not return a key string. List keys with:"
  echo "  gcloud services api-keys list"
  echo "  gcloud services api-keys get-key-string KEY_NAME"
  exit 1
fi

# Optional budget alert (ignored if it fails)
if [ -n "$BILLING_ID" ]; then
  gcloud services enable billingbudgets.googleapis.com >/dev/null 2>&1
  gcloud billing budgets create --billing-account="$BILLING_ID" \
    --display-name="Cabcher Maps budget" \
    --budget-amount=20USD \
    --filter-projects="projects/$PROJECT_ID" \
    --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 >/dev/null 2>&1 \
    && echo "Budget alert set at 20 USD (50% and 90%)." \
    || echo "(Budget alert skipped. You can add one in Billing > Budgets.)"
fi

echo ""
echo "=================================================="
echo " COPY THESE INTO CABCHER"
echo "=================================================="
echo " Browser key : $BROWSER_KEY"
echo " Server key  : $SERVER_KEY"
echo "=================================================="
echo "Keys can take a few minutes to become active."
