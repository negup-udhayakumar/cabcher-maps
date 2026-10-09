# Cabcher: Create your Google Maps keys

This takes about 3 minutes. **A billing account (card) is required** for Google Maps to work. Google gives free monthly usage, and this script also sets a budget alert.

## Step 1: Run the setup command

Paste the command shown in your Cabcher setup page, for example:

```bash
chmod +x setup-maps.sh
./setup-maps.sh "https://demo-taxi.com/demo-user-333/*" "YOUR_SERVER_PUBLIC_IP"
```

If you have no command, just run `./setup-maps.sh` and answer the questions.

## Step 2: Choose billing

When asked, pick your billing account. If none exists, create one at
https://console.cloud.google.com/billing/create and run the script again.

## Step 3: Copy your keys

At the end the terminal prints:

- **Browser key**
- **Server key**

Copy each one into the matching field in Cabcher, then click **Test keys**.

## Troubleshooting

- *Map shows a watermark or dark map*: billing is not enabled on the project.
- *REQUEST_DENIED on the server key*: the server IP in the key does not match your server's public IP.
- Keys can take up to 5 minutes to start working.
