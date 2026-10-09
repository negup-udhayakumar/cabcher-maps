
# Cabcher Google Maps Setup

This script attempts to create restricted Google Maps API keys
for your Cabcher installation.

## Step 1: Run the setup command

1. Copy the command from the Cabcher installation wizard.
2. Paste it into the Google Cloud Shell terminal.
3. Press Enter and wait for the script to finish.

The script attempts to create a Google Cloud project and two keys:

- Browser key: restricted to your website's HTTP referrer.
- Server key: restricted to your server's IP address.

## Step 2: Save the generated keys

If both keys are created successfully, copy the Browser key and
Server key from the terminal into the corresponding Cabcher fields.

Keep the Project ID printed by the script.

Creating API keys does not guarantee that Maps services are ready.

## Step 3: Accept the Google Maps terms

If the terminal reports UREQ_TOS_NOT_ACCEPTED, open:

https://console.developers.google.com/terms/maps

Sign in with the same Google account and accept the terms if prompted.

## Step 4: Enable billing

Open:

https://console.cloud.google.com/billing

Link an active billing account to the exact Project ID printed by
the script. Do not create another project for billing.

## Step 5: Enable and test the APIs

After resolving any errors, enable the required Maps APIs for the
same project. The script prints a retry command that targets the
existing project.

Return to Cabcher and test:

- Map display
- Pickup and drop-off location search
- Geocoding
- Route and distance calculations
- Distance-based fare calculations

Some features may use different APIs, so verify that every required
API is enabled and that each key has the correct restrictions.

## Troubleshooting

If API key creation fails, review the error in Cloud Shell.
Google Cloud may require billing, accepted terms, or additional
permissions.

If API enablement fails, do not create a new project or regenerate
keys unnecessarily. Resolve the error and retry against the existing
Project ID.

## Security and billing

- Keep the Server key private.
- Do not expose the Server key in browser-side JavaScript.
- Restrict keys to the intended website and server IP.
- Review Google Maps Platform pricing and usage limits.
- A budget alert is not a hard spending limit.

Google Maps Platform documentation:
https://developers.google.com/maps/get-started/

Google Cloud Billing:
https://console.cloud.google.com/billing
