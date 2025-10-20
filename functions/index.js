// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// helper: fetch tokens from collection name if field exists
async function _collectTokensFromCollection(colName) {
  const tokens = [];
  try {
    const snap = await admin.firestore().collection(colName).get();
    snap.forEach(doc => {
      const data = doc.data();
      // tries common field names: fcmToken, token
      const t = data?.fcmToken || data?.token || data?.deviceToken;
      if (t && typeof t === "string") tokens.push({ token: t, docId: doc.id, col: colName });
    });
  } catch (err) {
    console.warn(Could not read collection ${colName}:, err);
  }
  return tokens;
}

// remove bad token from Firestore doc
async function _removeTokenField(docRef, fieldName = "fcmToken") {
  try {
    await docRef.update({ [fieldName]: admin.firestore.FieldValue.delete() });
  } catch (err) {
    console.warn(Could not remove token field from ${docRef.path}:, err);
  }
}

exports.notifyNGOsOnNewDonation = functions.firestore
  .document("donations/{donationId}")
  .onCreate(async (snapshot, context) => {
    const donation = snapshot.data() || {};
    const restaurantName = donation.restaurantName || donation.restaurantId || "A restaurant";
    const title = "New Food Donation";
    const body = ${restaurantName} posted ${donation.title || "a donation"}${donation.quantity ? " • " + donation.quantity : ""};

    // Collect tokens from both common collection names (safe fallback)
    const tokensFromNgos = await _collectTokensFromCollection("ngos");
    const tokensFromNgo = await _collectTokensFromCollection("ngo");

    // merge and deduplicate tokens (by token string)
    const combined = [...tokensFromNgos, ...tokensFromNgo];
    const uniqueMap = new Map();
    combined.forEach(t => {
      if (t?.token) uniqueMap.set(t.token, t); // keep last metadata
    });
    const uniqueTokensMeta = Array.from(uniqueMap.values());
    const tokens = uniqueTokensMeta.map(t => t.token);

    if (!tokens.length) {
      console.log("No NGO tokens found. Exiting.");
      return null;
    }

    // Create notification payload (you can add data payload as needed)
    const messagePayload = {
      notification: {
        title,
        body
      },
      android: {
        priority: "high",
      },
      apns: {
        headers: {
          "apns-priority": "10"
        }
      },
      data: {
        donationId: snapshot.id,
        // you can add more keys like restaurantId, etc.
      }
    };

    // Firebase Admin supports sending to up to 500 tokens via sendMulticast
    const BATCH_SIZE = 500;
    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batchTokensMeta = uniqueTokensMeta.slice(i, i + BATCH_SIZE);
      const batchTokens = batchTokensMeta.map(t => t.token);

      try {
        const response = await admin.messaging().sendMulticast({
          tokens: batchTokens,
          ...messagePayload
        });

        console.log(Batch ${i / BATCH_SIZE} sent. Success: ${response.successCount}, Failure: ${response.failureCount});

        // Handle errors: remove invalid tokens
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const err = resp.error;
            const problematic = batchTokensMeta[idx]; // {token, docId, col}
            console.warn(Token failed: ${problematic?.token} error:, err && err.code ? err.code : err);

            // common error codes: 'messaging/registration-token-not-registered', 'messaging/invalid-registration-token'
            if (err && (err.code === 'messaging/registration-token-not-registered' || err.code === 'messaging/invalid-registration-token')) {
              const col = problematic?.col;
              const docId = problematic?.docId;
              if (col && docId) {
                const docRef = admin.firestore().collection(col).doc(docId);
                _removeTokenField(docRef, 'fcmToken').catch(e => console.warn('Remove token error', e));
              }
            }
          }
        });

      } catch (err) {
        console.error("Error sending multicast:", err);
      }
    }

    return null;
  });