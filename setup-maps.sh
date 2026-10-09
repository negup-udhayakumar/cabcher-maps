
#!/usr/bin/env bash
# Cabcher - Google Maps API Setup
#
# Usage:
#   ./setup-maps.sh "https://example.com/*" "203.0.113.10"
#
# Reuse an existing project:
#   ./setup-maps.sh "https://example.com/*" "203.0.113.10" "YOUR_PROJECT_ID"

set -uo pipefail

REFERRERS="${1:-}"
SERVER_IP="${2:-}"
PROJECT_ID="${3:-}"

# Google Maps APIs to enable
MAPS_APIS=(
    maps-backend.googleapis.com
    places-backend.googleapis.com
    places.googleapis.com
    directions-backend.googleapis.com
    distance-matrix-backend.googleapis.com
    geocoding-backend.googleapis.com
    routes.googleapis.com
)

# Save the keys in the user's private Cloud Shell home directory.
KEY_FILE="$HOME/cabcher-maps-keys.txt"

save_keys() {
    local temp_file
    temp_file="$(mktemp "$HOME/.cabcher-maps-keys.XXXXXX")" || return 1

    if ! (
        umask 077
        printf 'PROJECT_ID=%s\nBROWSER_KEY=%s\nSERVER_KEY=%s\n' \
            "$PROJECT_ID" "$BROWSER_KEY" "$SERVER_KEY" > "$temp_file"
    ); then
        rm -f "$temp_file"
        return 1
    fi

    chmod 600 "$temp_file" || {
        rm -f "$temp_file"
        return 1
    }

    if ! mv -f "$temp_file" "$KEY_FILE"; then
        rm -f "$temp_file"
        return 1
    fi

    chmod 600 "$KEY_FILE"
}

# Extract keyString from gcloud output without printing the key.
extract_key() {
    python3 -c '
import re
import sys

output = sys.stdin.read()
match = re.search(r"""["\x27]keyString["\x27]\s*:\s*["\x27]([^"\x27]+)["\x27]""", output)
if match:
    print(match.group(1))
'
}

# 1. Get and validate inputs
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

# 2. Create a new project or reuse an existing one
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
    echo "==> Reusing existing project: $PROJECT_ID"

    if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
        echo "ERROR: Project not found or access denied: $PROJECT_ID"
        exit 1
    fi
fi

if ! gcloud config set project "$PROJECT_ID"; then
    echo "ERROR: Could not select the project."
    exit 1
fi

echo ""
echo "Project ID: $PROJECT_ID"

# 3. Enable the API Keys API
echo ""
echo "==> Enabling API Keys API"

if ! gcloud services enable apikeys.googleapis.com \
    --project="$PROJECT_ID"; then

    echo ""
    echo "ERROR: Could not enable the API Keys API."
    echo "Check project permissions and billing requirements."
    exit 1
fi

# 4. Create the Browser API key
echo ""
echo "==> Creating restricted Browser API key"

BROWSER_OUTPUT="$(gcloud services api-keys create \
    --project="$PROJECT_ID" \
    --display-name="Cabcher Browser" \
    --allowed-referrers="$REFERRERS" \
    --api-target=service=maps-backend.googleapis.com \
    --api-target=service=places-backend.googleapis.com \
    --api-target=service=places.googleapis.com \
    --api-target=service=geocoding-backend.googleapis.com \
    --format=json 2>&1)"
BROWSER_EXIT=$?

BROWSER_KEY="$(printf '%s' "$BROWSER_OUTPUT" | extract_key)"

if [[ "$BROWSER_EXIT" -ne 0 || -z "$BROWSER_KEY" ]]; then
    echo "ERROR: Browser API key creation failed."
    echo "$BROWSER_OUTPUT"
    exit 1
fi

echo "Browser API key created."

# 5. Create the Server API key
echo ""
echo "==> Creating restricted Server API key"

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
    --format=json 2>&1)"
SERVER_EXIT=$?

SERVER_KEY="$(printf '%s' "$SERVER_OUTPUT" | extract_key)"

if [[ "$SERVER_EXIT" -ne 0 || -z "$SERVER_KEY" ]]; then
    echo "ERROR: Server API key creation failed."
    echo "$SERVER_OUTPUT"
    echo ""
    echo "The Browser key was created, but the Server key was not."
    echo "Check API Keys in Google Cloud Console before retrying."
    echo "Do not rerun blindly, because that may create duplicate keys."
    exit 1
fi

echo "Server API key created."

# 6. Save both keys BEFORE enabling Maps APIs.
# This means the keys remain available if Maps API activation fails.
echo ""
echo "==> Saving keys to a private file"

if ! save_keys; then
    echo "ERROR: Could not save the keys securely."
    echo "Please resolve the file permission or disk issue."
    exit 1
fi

echo "Keys saved to: $KEY_FILE"
echo "File permissions restricted to the Cloud Shell user."

# 7. Attempt to enable Google Maps APIs
echo ""
echo "==> Attempting to enable Google Maps APIs"

API_OUTPUT="$(gcloud services enable "${MAPS_APIS[@]}" \
    --project="$PROJECT_ID" 2>&1)"
API_EXIT=$?

if [[ "$API_EXIT" -eq 0 ]]; then
    echo "$API_OUTPUT"
    API_STATUS="Google Maps APIs enabled successfully."
else
    echo "$API_OUTPUT"

    if [[ "$API_OUTPUT" == *"UREQ_TOS_NOT_ACCEPTED"* ]]; then
        API_STATUS="Google Maps Terms of Service must be accepted."
    else
        API_STATUS="Maps API activation failed. Review the error above."
    fi
fi

# 8. Show the result without printing the actual keys
echo ""
echo "=================================================="
echo " CABCHER GOOGLE MAPS SETUP RESULT"
echo "=================================================="
echo "Project ID: $PROJECT_ID"
echo ""
echo "Browser key and Server key are saved privately."
echo "File: $KEY_FILE"
echo ""
echo "STATUS:"
echo "$API_STATUS"
echo ""
echo "HOW TO GET YOUR KEYS:"
echo "Run this command in Cloud Shell:"
echo "cat ~/cabcher-maps-keys.txt"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Copy the Browser key and Server key into Cabcher."
echo ""
echo "2. If the error says UREQ_TOS_NOT_ACCEPTED, open:"
echo "   https://console.developers.google.com/terms/maps"
echo ""
echo "3. Accept the Google Maps terms for this project if prompted."
echo ""
echo "4. Enable billing for this SAME project:"
echo "   https://console.cloud.google.com/billing"
echo ""
echo "5. After resolving the issue, retry API activation with:"
printf 'gcloud services enable'
printf ' %s' "${MAPS_APIS[@]}"
printf ' --project=%q\n' "$PROJECT_ID"
echo ""
echo "Do not rerun the setup script just to accept terms."
echo "The retry command above reuses this project and its existing keys."
echo ""
echo "Keep the Server key private and do not commit the key file."
echo "=================================================="
