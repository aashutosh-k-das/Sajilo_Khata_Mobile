// Google and Facebook sign-in for the web prototype.
//
// With the VITE_FIREBASE_* values set (see .env.example) this uses real
// Firebase Authentication popups. Without them the app runs in demo mode and
// app.js shows a pretend account picker instead.

const config = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

export const firebaseReady = Boolean(config.apiKey && config.authDomain && config.projectId);

// Firebase is loaded only when configured, so demo mode stays lightweight
let services = null;
async function load() {
  if (!services) {
    const [{ initializeApp }, authMod, fsMod] = await Promise.all([
      import('firebase/app'),
      import('firebase/auth'),
      import('firebase/firestore'),
    ]);
    const app = initializeApp(config);
    const auth = authMod.getAuth(app);
    auth.useDeviceLanguage();
    services = { authMod, fsMod, auth, db: fsMod.getFirestore(app) };
  }
  return services;
}

export class AuthError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

// Plain-language messages for the errors people actually hit
const ERROR_MESSAGES = {
  'auth/popup-closed-by-user': { ne: 'लगइन रद्द गरियो', en: 'Login cancelled' },
  'auth/cancelled-popup-request': { ne: 'लगइन रद्द गरियो', en: 'Login cancelled' },
  'auth/popup-blocked': {
    ne: 'ब्राउजरले पपअप रोक्यो। पपअप अनुमति दिएर फेरि प्रयास गर्नुहोस्',
    en: 'The browser blocked the popup. Allow popups and try again',
  },
  'auth/account-exists-with-different-credential': {
    ne: 'यो इमेल अर्को तरिकाले दर्ता छ। पहिले प्रयोग गरेको तरिकाले लगइन गर्नुहोस्',
    en: 'This email is already registered with another login method. Use that one instead',
  },
  'auth/network-request-failed': { ne: 'इन्टरनेट जडान छैन', en: 'No internet connection' },
  'auth/operation-not-allowed': {
    ne: 'यो लगइन तरिका Firebase मा सक्रिय छैन',
    en: 'This login method is not enabled in Firebase',
  },
  'auth/unauthorized-domain': {
    ne: 'यो वेबसाइट Firebase मा अनुमति प्राप्त छैन',
    en: 'This website is not an authorised domain in Firebase',
  },
};

export function authErrorMessage(err, lang) {
  const known = ERROR_MESSAGES[err?.code];
  if (known) return known[lang] ?? known.en;
  return lang === 'ne' ? 'लगइन असफल भयो' : 'Login failed';
}

/**
 * Opens the provider's sign-in popup.
 * @param {'google' | 'facebook'} providerName
 * @returns {Promise<{ id: string, name: string, email: string | null, method: string }>}
 */
export async function signInWith(providerName) {
  if (!firebaseReady) throw new AuthError('demo-mode', 'Firebase is not configured');
  const { authMod, auth } = await load();

  const provider = providerName === 'facebook'
    ? new authMod.FacebookAuthProvider()
    : new authMod.GoogleAuthProvider();
  provider.addScope('email');
  if (providerName === 'google') provider.setCustomParameters({ prompt: 'select_account' });

  const { user } = await authMod.signInWithPopup(auth, provider);
  const method = providerName === 'facebook' ? 'facebook.com' : 'google.com';
  await recordLogin(user.uid, method);

  return {
    id: user.email || user.phoneNumber || user.uid,
    name: user.displayName || '',
    email: user.email,
    method,
  };
}

// Writes shops/{uid}/logins/{id}; the notifyLogin Cloud Function emails the
// account owner about the new sign-in. Never blocks login if it fails.
async function recordLogin(uid, method) {
  try {
    const { fsMod, db } = await load();
    await fsMod.addDoc(fsMod.collection(db, 'shops', uid, 'logins'), {
      method,
      platform: 'web browser',
      at: fsMod.serverTimestamp(),
    });
  } catch (e) {
    console.warn('Could not record login:', e);
  }
}

export async function signOut() {
  if (!firebaseReady) return;
  // Firebase keeps the user signed in across reloads, so load it even if
  // this page view never opened a popup
  const { authMod, auth } = await load();
  await authMod.signOut(auth);
}
