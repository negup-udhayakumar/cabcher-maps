
#!/usr/bin/env bash
# Cabcher - Google Maps API Key Setup
#
# Usage:
#   ./setup-maps.sh "https://example.com/*" "203.0.113.10"
#
# Optional third argument: reuse an existing project.
#   ./setup-maps.sh "https://example.com/*" "203.0.113.10" "cabcher-maps-123456"
#
# Note:
# Key creation may work without billing, but Maps APIs require
# the required terms, billing, permissions, and API configuration.

set -uo pipefail

REFERRERS="${1:-}"
SERVER_IP="${2:-}"
PROJECT_ID="${3:-}"

# --------------------------------------------------
# 1. Collect and validate inputs
# --------------------------------------------------

if [[ -z "$REFERRERS" ]]; then
    read -r -p "Website referrer (example: https://example.com/*): " REFERRERS
fi

if [[ -z "$SERVER_IP" ]]; then
    read -r -p "Server public IP address: " SERVER_IP
fi

if [[ ! "$REFERRERS" =~ ^https?:// ]]; then
    echo "ERROR: Referrer must start with http:// or https://"
    exit 1
fi

SERVER_IP="${SERVER_IP// /}"

if [[ ! "$SERVER_IP" =~ ^[0-9a-fA-F:.,/]+$ ]]; then
    echo "ERROR: Server IP address format looks invalid."
    exit 1
fi

# --------------------------------------------------
# 2. Create or reuse the Google Cloud project
# --------------------------------------------------

if [[ -z "$PROJECT_ID" ]]; then
    PROJECT_ID="cabcher-maps-$(date +%s)-$RANDOM"

    echo ""
    echo "==> Creating Google Cloud project: $PROJECT_ID"

    if ! gcloud projects create "$PROJECT_ID" \
        --name="Cabcher Maps"; then
        echo "ERROR: Project creation failed."
        exit 1
    fi
else
    echo ""
    echo "==> Reusing project: $PROJECT_ID"

    if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
        echo "ERROR: Project not found or access denied: $PROJECT_ID"
        exit 1
    fi
fi

echo ""
echo "Project ID: $PROJECT_ID"

if ! gcloud config set project "$PROJECT_ID"; then
    echo "ERROR: Could not select project."
    exit 1
fi

# --------------------------------------------------
# 3. Enable the API Keys API
# --------------------------------------------------

echo ""
echo "==> Enabling API Keys API"

if ! gcloud services enable apikeys.googleapis.com \
    --project="$PROJECT_ID"; then
    echo ""
    echo "ERROR: Could not enable the API Keys API."
    echo "Project: $PROJECT_ID"
    echo "Billing: https://console.cloud.google.com/billing"
    echo ""
    echo "Resolve the error, then retry with the same project:"
    printf './setup-maps.sh %q %q %q\n' \
        "$REFERRERS" "$SERVER_IP" "$PROJECT_ID"
    exit 1
fi

# --------------------------------------------------
# 4. Create the Browser API key
# --------------------------------------------------

BROWSER_KEY=""

echo ""
echo "==> Creating restricted Browser key"

BROWSER_OUTPUT="$(gcloud services api-keys create \
    --project="$PROJECT_ID" \
    --display-name="Cabcher Browser" \
    --allowed-referrers="$REFERRERS" \
    --api-target=service=maps-backend.googleapis.com \
    --api-target=service=places-backend.googleapis.com \
    --api-target=service=places.googleapis.com \
    --api-target=service=geocoding-backend.googleapis.com \
    --format='value(response.keyString)' 2>&1)"
BROWSER_EXIT=$?

if [[ "$BROWSER_EXIT" -eq 0 ]]; then
    BROWSER_KEY="$(printf '%s\n' "$BROWSER_OUTPUT" | tail -n 1)"
fi

if [[ -z "$BROWSER_KEY" ]]; then
    echo "$BROWSER_OUTPUT"
    echo ""
    echo "ERROR: Browser key creation failed."
    echo "Project: $PROJECT_ID"
    printf './setup-maps.sh %q %q %q\n' \
        "$REFERRERS" "$SERVER_IP" "$PROJECT_ID"
    exit 1
fi

echo "Browser key created successfully."

# --------------------------------------------------
# 5. Create the Server API key
# --------------------------------------------------

SERVER_KEY=""

echo ""
echo "==> Creating restricted Server key"

SERVER_OUTPUT="$(gcloud services api-keys create \
    --project="$PROJECT_ID" \
    --display-name="Cabcher Server" \
    --allowed-ips="$SERVER_IP" \
    --api-target=service=directions-backend.googleapis.com \
    --api-target=service=distance-matrix-backend.googleapis.com \
    --api-target=service=geocoding-backend.googleapis.com \
    --api-target=service=places-backend.googleapis.com \
    --api-target=service=places.googleapis.com \
    --api-target=service=routes.googleapis.com \
    --format='value(response.keyString)' 2>&1)"
SERVER_EXIT=$?

if [[ "$SERVER_EXIT" -eq 0 ]]; then
    SERVER_KEY="$(printf '%s\n' "$SERVER_OUTPUT" | tail -n 1)"
fi

if [[ -z "$SERVER_KEY" ]]; then
    echo "$SERVER_OUTPUT"
    echo ""
    echo "ERROR: Server key creation failed."
    echo "Project: $PROJECT_ID"
    echo "The Browser key may already exist. Check API Keys in Cloud Console."
    echo "Do not rerun blindly, or duplicate keys may be created."
    exit 1
fi

echo "Server key created successfully."

# --------------------------------------------------
# 6. Attempt to enable Google Maps APIs
# --------------------------------------------------

echo ""
echo "==> Attempting to enable Google Maps APIs"

API_OUTPUT="$(gcloud services enable \
    maps-backend.googleapis.com \
    places-backend.googleapis.com \
    places.googleapis.com \
    directions-backend.googleapis.com \
    distance-matrix-backend.googleapis.com \
    geocoding-backend.googleapis.com \
    routes.googleapis.com \
    --project="$PROJECT_ID" 2>&1)"
API_EXIT=$?

API_STATUS=""

if [[ "$API_EXIT" -eq 0 ]]; then
    echo "$API_OUTPUT"
    API_STATUS="Google Maps APIs enabled successfully."
else
    echo "$API_OUTPUT"

    if [[ "$API_OUTPUT" == *"UREQ_TOS_NOT_ACCEPTED"* ]]; then
        API_STATUS="Google Maps Terms of Service must be accepted."
    else
        API_STATUS="Some Maps APIs could not be enabled. Review the error above."
    fi
fi

# --------------------------------------------------
# 7. Display keys and next steps
# --------------------------------------------------

echo ""
echo "=================================================="
echo " CABCHER GOOGLE MAPS SETUP RESULT"
echo "=================================================="
echo "Project ID:"
echo "$PROJECT_ID"
echo ""
echo "Browser API key:"
echo "$BROWSER_KEY"
echo ""
echo "Server API key:"
echo "$SERVER_KEY"
echo "=================================================="
echo ""
echo "STATUS:"
echo "$API_STATUS"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Save both keys in the Cabcher installer."
echo ""
echo "2. If Terms of Service were not accepted, open:"
echo "   https://console.developers.google.com/terms/maps"
echo ""
echo "3. Enable billing for this SAME project:"
echo "   https://console.cloud.google.com/billing"
echo ""
echo "4. Confirm the required Maps APIs are enabled."
echo ""
echo "5. Test map display, place search, and distance calculations."
echo ""
echo "If API enablement failed, retry after resolving the error:"
printf 'gcloud services enable maps-backend.googleapis.com places-backend.googleapis.com places.googleapis.com directions-backend.googleapis.com distance-matrix-backend.googleapis.com geocoding-backend.googleapis.com routes.googleapis.com --project=%q\n' \
    "$PROJECT_ID"
echo ""
echo "Keys being created does not guarantee Maps services will work."
echo "Billing, accepted terms, API activation, and valid restrictions may be required."
echo "=================================================="
