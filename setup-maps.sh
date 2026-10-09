
#!/usr/bin/env bash
# Cabcher - Google Maps API key setup
#
# Usage:
#   ./setup-maps.sh "https://example.com/*" "203.0.113.10"
#
# Optional third argument reuses an existing project:
#   ./setup-maps.sh "https://example.com/*" "203.0.113.10" "cabcher-maps-123456"
#
# Note: Google may require billing before API key creation or API use.

set -uo pipefail

REFERRERS="${1:-}"
SERVER_IP="${2:-}"
PROJECT_ID="${3:-}"

if [[ -z "$REFERRERS" ]]; then
  read -r -p "Website referrer (example: https://example.com/*): " REFERRERS
fi

if [[ -z "$SERVER_IP" ]]; then
  read -r -p "Server public IP address: " SERVER_IP
fi

# Basic input validation
if [[ ! "$REFERRERS" =~ ^https?:// ]]; then
  echo "ERROR: Website referrer must start with http:// or https://"
  exit 1
fi

SERVER_IP="${SERVER_IP// /}"

if [[ ! "$SERVER_IP" =~ ^[0-9a-fA-F:.,/]+$ ]]; then
  echo "ERROR: Server IP address format looks invalid."
  exit 1
fi

# Create a project, or reuse the supplied project ID.
if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID="cabcher-maps-$(date +%s)-$RANDOM"

  echo ""
  echo "==> Creating Google Cloud project: $PROJECT_ID"

  if ! gcloud projects create "$PROJECT_ID" \
      --name="Cabcher Maps"; then
    echo "ERROR: Project creation failed."
    echo "Check your Google account permissions and try again."
    exit 1
  fi
else
  echo ""
  echo "==> Reusing Google Cloud project: $PROJECT_ID"

  if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
    echo "ERROR: Project $PROJECT_ID was not found or you do not have access."
    exit 1
  fi
fi

echo ""
echo "Project ID: $PROJECT_ID"

if ! gcloud config set project "$PROJECT_ID"; then
  echo "ERROR: Could not select project $PROJECT_ID."
  exit 1
fi

# Enable the API Keys API. This operation may fail if Google Cloud
# requires billing or additional permissions.
echo ""
echo "==> Enabling API Keys API"

if ! gcloud services enable apikeys.googleapis.com \
    --project="$PROJECT_ID"; then
  echo ""
  echo "ERROR: Could not enable the API Keys API."
  echo "Project ID: $PROJECT_ID"
  echo "If Google requires billing, link billing to this SAME project:"
  echo "https://console.cloud.google.com/billing"
  echo ""
  echo "After billing is enabled, retry using:"
  printf "./setup-maps.sh %q %q %q\n" \
    "$REFERRERS" "$SERVER_IP" "$PROJECT_ID"
  exit 1
fi

# Create the browser key with website referrer restrictions.
echo ""
echo "==> Creating restricted Browser key"

BROWSER_KEY="$(gcloud services api-keys create \
  --project="$PROJECT_ID" \
  --display-name="Cabcher Browser" \
  --allowed-referrers="$REFERRERS" \
  --api-target=service=maps-backend.googleapis.com \
  --api-target=service=places-backend.googleapis.com \
  --api-target=service=places.googleapis.com \
  --api-target=service=geocoding-backend.googleapis.com \
  --format='value(response.keyString)')"

if [[ -z "$BROWSER_KEY" ]]; then
  echo ""
  echo "ERROR: Browser key creation failed."
  echo "Project ID: $PROJECT_ID"
  echo "Check the error above. Billing or permissions may be required."
  echo "Do not create another project; reuse this project when retrying."
  printf "./setup-maps.sh %q %q %q\n" \
    "$REFERRERS" "$SERVER_IP" "$PROJECT_ID"
  exit 1
fi

# Create the server key with IP restrictions.
echo ""
echo "==> Creating restricted Server key"

SERVER_KEY="$(gcloud services api-keys create \
  --project="$PROJECT_ID" \
  --display-name="Cabcher Server" \
  --allowed-ips="$SERVER_IP" \
  --api-target=service=directions-backend.googleapis.com \
  --api-target=service=distance-matrix-backend.googleapis.com \
  --api-target=service=geocoding-backend.googleapis.com \
  --api-target=service=places-backend.googleapis.com \
  --api-target=service=places.googleapis.com \
  --api-target=service=routes.googleapis.com \
  --format='value(response.keyString)')"

if [[ -z "$SERVER_KEY" ]]; then
  echo ""
  echo "ERROR: Server key creation failed."
  echo "Project ID: $PROJECT_ID"
  echo "A browser key may already have been created in this project."
  echo "Check the error above before retrying to avoid duplicate keys."
  exit 1
fi

# Attempt to enable the Maps APIs after key creation.
# This may fail until billing is linked.
echo ""
echo "==> Attempting to enable Google Maps APIs"

if gcloud services enable \
  maps-backend.googleapis.com \
  places-backend.googleapis.com \
  places.googleapis.com \
  directions-backend.googleapis.com \
  distance-matrix-backend.googleapis.com \
  geocoding-backend.googleapis.com \
  routes.googleapis.com \
  --project="$PROJECT_ID"; then
  API_STATUS="Maps API enablement command succeeded."
else
  API_STATUS="Some Maps APIs could not be enabled yet. Billing or permissions may be required."
fi

echo ""
echo "=================================================="
echo " GOOGLE MAPS API KEY SETUP RESULT"
echo "=================================================="
echo "Project ID  : $PROJECT_ID"
echo "Browser key : $BROWSER_KEY"
echo "Server key  : $SERVER_KEY"
echo "=================================================="
echo "$API_STATUS"
echo ""
echo "NEXT STEPS:"
echo "1. Save both keys in Cabcher."
echo "2. Open https://console.cloud.google.com/billing"
echo "3. Link an active billing account to project:"
echo "   $PROJECT_ID"
echo "4. Confirm the required Maps APIs are enabled."
echo "5. Test maps, place search, and distance calculations."
echo ""
echo "Keys being created does NOT mean Maps services are ready."
echo "Google Maps Platform usage requires an active billing account."
echo "=================================================="
