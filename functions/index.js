"use strict";

const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

initializeApp();

const PAIRING_CODE_PATTERN = /^[A-Z]{5}$/;

exports.pairWithCode = onCall(async (request) => {
  const callerUid = request.auth && request.auth.uid;
  if (!callerUid) {
    throw new HttpsError(
      "unauthenticated",
      "Sign in before connecting a partner.",
    );
  }

  const rawCode = request.data && request.data.code;
  if (typeof rawCode !== "string") {
    throw new HttpsError("invalid-argument", "Enter a valid partner code.");
  }

  const code = rawCode.trim().toUpperCase();
  if (!PAIRING_CODE_PATTERN.test(code)) {
    throw new HttpsError(
      "invalid-argument",
      "Partner codes must be 5 letters.",
    );
  }

  const db = getFirestore();
  const users = db.collection("users");
  const callerRef = users.doc(callerUid);

  return db.runTransaction(async (transaction) => {
    const callerSnapshot = await transaction.get(callerRef);
    if (!callerSnapshot.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Your profile could not be found.",
      );
    }

    const callerData = callerSnapshot.data() || {};
    if (hasPartner(callerData)) {
      throw new HttpsError(
        "failed-precondition",
        "You are already connected to a partner.",
      );
    }

    const matchQuery = users.where("pairingCode", "==", code).limit(2);
    const matchSnapshot = await transaction.get(matchQuery);

    if (matchSnapshot.empty) {
      throw new HttpsError("not-found", "Partner code not found.");
    }
    if (matchSnapshot.size > 1) {
      throw new HttpsError(
        "failed-precondition",
        "That partner code is not unique. Ask your partner to refresh their code.",
      );
    }

    const partnerSnapshot = matchSnapshot.docs[0];
    const partnerUid = partnerSnapshot.id;
    if (partnerUid === callerUid) {
      throw new HttpsError(
        "failed-precondition",
        "You cannot connect to your own code.",
      );
    }

    const partnerData = partnerSnapshot.data() || {};
    if (hasPartner(partnerData)) {
      throw new HttpsError(
        "failed-precondition",
        "That partner code is already connected.",
      );
    }

    const now = FieldValue.serverTimestamp();
    transaction.update(callerRef, {
      partnerId: partnerUid,
      updatedAt: now,
    });
    transaction.update(partnerSnapshot.ref, {
      partnerId: callerUid,
      updatedAt: now,
    });

    return {
      success: true,
      partnerId: partnerUid,
    };
  });
});

function hasPartner(userData) {
  return typeof userData.partnerId === "string" && userData.partnerId.length > 0;
}
