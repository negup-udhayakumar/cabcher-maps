
# Cabcher Google Maps Setup

This setup attempts to create Google Maps API keys for your Cabcher installation.

Google Cloud may require billing to be enabled before keys can be created or Maps APIs can be used.

## Step 1: Run the setup command

1. Open this tutorial from the Cabcher installation wizard.
2. Copy the command shown in the installer.
3. Paste it into the Google Cloud Shell terminal.
4. Press Enter and wait for the script to finish.

The script attempts to create a Google Cloud project and generate two restricted API keys:

- Browser key: restricted to your website's HTTP referrer.
- Server key: restricted to your server's IP address.

## Step 2: If both keys are created successfully

Copy the Browser key and Server key shown in the terminal.

Enter them into the matching fields in the Cabcher installation wizard.

Also keep the Project ID displayed by the script. You will need it when enabling billing.

**Important:** Creating keys does not guarantee that Google Maps features will work. Billing and API activation may still be required.

## Step 3: Enable billing for the same project

1. Open Google Cloud Billing:

   https://console.cloud.google.com/billing

2. Sign in to your Google account.
3. Create or select an active billing account.
4. Link that billing account to the exact Project ID printed by the script.

Do not create a different project for billing. The billing account must be linked to the project containing your Cabcher API keys.

## Step 4: Enable the required Google Maps APIs

After billing is linked, open the Google Cloud API Library:

https://console.cloud.google.com/apis/library

Select the project created by the script and enable the APIs required by your Cabcher installation.

The script attempts to enable the APIs automatically. If that step fails, enable them from the Google Cloud Console and review the error shown in Cloud Shell.

## Step 5: Test your installation

Return to Cabcher and test:

- Map display
- Pickup and drop-off location search
- Geocoding, if used
- Route and distance calculations
- Fare calculations based on distance

If a feature does not work, check that its API is enabled, the correct key is being used, and the key restrictions match the website or server.

## If setup fails before the keys are created

The script prints the Project ID and a retry command when possible.

If Google requires billing:

1. Enable billing for that same project.
2. Copy the retry command printed by the script.
3. Run it in the same Cloud Shell repository directory.

The retry command includes the existing Project ID so that the script does not create a different project.

If one key was created before an error occurred, check the project's API Keys page before retrying to avoid generating duplicate keys.

## Security and billing notes

- Keep the Server key private.
- Never expose the Server key in browser-side JavaScript.
- Use only the intended website referrers and server IP addresses.
- Review Google Maps Platform pricing and usage limits.
- A budget alert is not a hard spending limit.

Google Maps Platform documentation:
https://developers.google.com/maps/get-started/

Google Cloud Billing:
https://console.cloud.google.com/billing
