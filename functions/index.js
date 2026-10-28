// Sends a "new sign-in" email whenever the app records a login.
// The app writes shops/{uid}/logins/{id} right after a successful sign-in.
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const nodemailer = require('nodemailer');

initializeApp();

// Set with: firebase functions:secrets:set GMAIL_USER / GMAIL_APP_PASSWORD
// (a Google account App Password, not the normal account password)
const GMAIL_USER = defineSecret('GMAIL_USER');
const GMAIL_APP_PASSWORD = defineSecret('GMAIL_APP_PASSWORD');

const METHOD_NAMES = {
  'google.com': 'Google',
  'facebook.com': 'Facebook',
  phone: 'phone number (OTP)',
};

exports.notifyLogin = onDocumentCreated(
  {
    document: 'shops/{uid}/logins/{loginId}',
    region: 'asia-south1',
    secrets: [GMAIL_USER, GMAIL_APP_PASSWORD],
  },
  async (event) => {
    const login = event.data?.data() ?? {};
    const user = await getAuth().getUser(event.params.uid);
    // Phone-only accounts have no email address to notify
    if (!user.email) return;

    const when = new Date().toLocaleString('en-GB', { timeZone: 'Asia/Kathmandu' });
    const method = METHOD_NAMES[login.method] ?? login.method ?? 'unknown';
    const device = login.platform ?? 'unknown device';

    const transport = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: GMAIL_USER.value(), pass: GMAIL_APP_PASSWORD.value() },
    });
    await transport.sendMail({
      from: `"Sajilo Khata" <${GMAIL_USER.value()}>`,
      to: user.email,
      subject: 'Sajilo Khata: new sign-in to your account',
      text:
        `Namaste ${user.displayName ?? ''},\n\n` +
        `Your Sajilo Khata account was signed in with ${method} on ${device} ` +
        `at ${when} (Nepal time).\n\n` +
        `If this was you, no action is needed. If not, sign out of the app on all ` +
        `devices and secure your Google account at https://myaccount.google.com/security.\n\n` +
        `- Sajilo Khata`,
    });
  },
);
