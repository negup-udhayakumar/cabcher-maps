# Cabcher: Create your Google Maps keys

This takes about 3 minutes. A Google Cloud billing account is required for Google Maps to work. Google may offer free monthly usage, depending on the applicable pricing and eligibility.

## Step 1: Run the setup command

Return to your Cabcher installation page and copy the command from the **Guided Setup** section.

Paste the copied command into the Cloud Shell terminal and press Enter.

The command contains your installation's website URL and server IP address. You do not need to enter the demo URL or IP manually.

If you do not have a command available, run:

```bash
./setup-maps.sh
```

Then follow the prompts.

## Step 2: Choose billing

Select an available billing account when prompted.

If you do not have one, create it at:

https://console.cloud.google.com/billing/create

Then run the setup script again.

## Step 3: Copy your keys

At the end, the terminal displays:

* **Browser key**
* **Server key**

Copy each key into its matching field in Cabcher, then click **Test keys**.

## Troubleshooting

* **Map shows a watermark or dark map:** Check billing, API enablement, and key restrictions.
* **REQUEST_DENIED on the server key:** Verify the server key's IP restrictions and enabled APIs.
* **Keys are not working immediately:** Wait a few minutes and test again.
