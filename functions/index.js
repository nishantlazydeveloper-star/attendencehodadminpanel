"use strict";

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");

initializeApp();

const auth = getAuth();
const firestore = getFirestore();
const hods = firestore.collection("hods");

function safeData(data) {
  return Object.fromEntries(
      Object.entries(data || {}).map(([key, value]) => [
        key,
        key.toLowerCase().includes("password") ? "<redacted>" : value,
      ]),
  );
}

function errorDetails(error) {
  return {
    name: error && error.name,
    code: error && error.code,
    message: error && error.message,
    stack: error && error.stack,
    details: error && error.details,
  };
}

async function requireAdmin(request, functionName) {
  const token = request.auth && request.auth.token;
  if (!token) {
    logger.error("Admin authorization failed: unauthenticated", {
      functionName,
      requestData: safeData(request.data),
    });
    throw new HttpsError("unauthenticated", "Admin sign-in is required.");
  }

  logger.info("Admin authorization started", {
    functionName,
    uid: request.auth.uid,
    tokenClaims: token,
  });
  if (token.admin === true || token.role === "admin") {
    logger.info("Admin authorized by custom claim", {
      functionName,
      uid: request.auth.uid,
    });
    return;
  }

  const adminDocumentId = request.auth.uid;
  const adminReference = firestore
      .collection("hodAdminPanel")
      .doc(adminDocumentId);
  logger.info("Firestore admin document read started", {
    functionName,
    collection: "hodAdminPanel",
    documentId: adminDocumentId,
  });
  try {
    const snapshot = await adminReference.get();
    const data = snapshot.data();
    logger.info("Firestore admin document read completed", {
      functionName,
      documentId: snapshot.id,
      exists: snapshot.exists,
      data,
    });
    if (
      snapshot.exists &&
      data &&
      data.isActive === true &&
      String(data.role || "").toLowerCase() === "admin"
    ) {
      logger.info("Admin authorized by Firestore profile", {
        functionName,
        uid: request.auth.uid,
        documentId: snapshot.id,
      });
      return;
    }
  } catch (error) {
    logger.error("Firestore admin authorization read failed", {
      functionName,
      uid: request.auth.uid,
      error: errorDetails(error),
    });
    throw new HttpsError(
        "internal",
        `Unable to verify admin profile: ${error.message || error}`,
        errorDetails(error),
    );
  }

  logger.error("Admin authorization failed: permission denied", {
    functionName,
    uid: request.auth.uid,
    tokenClaims: token,
  });
    throw new HttpsError(
        "permission-denied",
        "Active admin profile not found in hodAdminPanel.",
    );
}

function text(data, key, label, maxLength = 150) {
  const value = typeof data[key] === "string" ? data[key].trim() : "";
  if (!value) {
    throw new HttpsError("invalid-argument", `${label} is required.`);
  }
  if (value.length > maxLength) {
    throw new HttpsError(
        "invalid-argument",
        `${label} must be ${maxLength} characters or fewer.`,
    );
  }
  return value;
}

function email(data) {
  const value = text(data, "email", "Email", 254).toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value)) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  return value;
}

function uid(data) {
  return text(data, "uid", "HOD ID", 128);
}

function profile(data) {
  const name = text(data, "name", "Full name");
  return {
    name,
    fullName: name,
    nameLowercase: name.toLowerCase(),
    email: email(data),
    college: text(data, "college", "College"),
    department: text(data, "department", "Department"),
    role: "hod",
  };
}

function authError(error) {
  if (error.code === "auth/email-already-exists") {
    return new HttpsError("already-exists", "This email is already in use.");
  }
  if (error.code === "auth/user-not-found") {
    return new HttpsError("not-found", "HOD account was not found.");
  }
  if (error.code === "auth/invalid-password") {
    return new HttpsError("invalid-argument", "Password is invalid.");
  }
  return new HttpsError(
      "internal",
      error.message || "Unable to update the HOD account.",
      errorDetails(error),
  );
}

function exactHttpsError(stage, error) {
  if (error instanceof HttpsError) {
    return error;
  }

  const code = String(error && error.code || "");
  const message = error && error.message ?
    String(error.message) :
    String(error || "Unknown error");
  const details = {
    stage,
    originalCode: code || null,
    originalMessage: message,
    ...errorDetails(error),
  };

  const knownErrors = {
    "auth/email-already-exists": [
      "already-exists",
      `Firebase Auth createUser failed: ${message}`,
    ],
    "auth/invalid-email": [
      "invalid-argument",
      `Firebase Auth rejected the email: ${message}`,
    ],
    "auth/invalid-password": [
      "invalid-argument",
      `Firebase Auth rejected the password: ${message}`,
    ],
    "auth/uid-already-exists": [
      "already-exists",
      `Firebase Auth UID already exists: ${message}`,
    ],
    "auth/insufficient-permission": [
      "permission-denied",
      `Firebase Admin SDK lacks permission during ${stage}: ${message}`,
    ],
    "auth/project-not-found": [
      "failed-precondition",
      `Firebase Auth project configuration is invalid: ${message}`,
    ],
  };

  if (knownErrors[code]) {
    return new HttpsError(
        knownErrors[code][0],
        knownErrors[code][1],
        details,
    );
  }

  if (code === "6" || code === "already-exists") {
    return new HttpsError(
        "already-exists",
        `Firestore document already exists during ${stage}: ${message}`,
        details,
    );
  }
  if (code === "7" || code === "permission-denied") {
    return new HttpsError(
        "permission-denied",
        `Permission denied during ${stage}: ${message}`,
        details,
    );
  }
  if (code === "5" || code === "not-found") {
    return new HttpsError(
        "not-found",
        `Resource not found during ${stage}: ${message}`,
        details,
    );
  }
  if (code === "3" || code === "invalid-argument") {
    return new HttpsError(
        "invalid-argument",
        `Invalid data during ${stage}: ${message}`,
        details,
    );
  }
  if (code === "14" || code === "unavailable") {
    return new HttpsError(
        "unavailable",
        `Firebase service unavailable during ${stage}: ${message}`,
        details,
    );
  }

  return new HttpsError(
      "internal",
      `${stage} failed: ${message}${code ? ` [${code}]` : ""}`,
      details,
  );
}

exports.createHod = onCall(async (request) => {
  const functionName = "createHod";
  logger.info("Cloud Function request received", {
    functionName,
    callerUid: request.auth && request.auth.uid,
    requestData: safeData(request.data),
  });
  await requireAdmin(request, functionName);
  const data = request.data || {};
  const values = profile(data);
  const password = text(data, "password", "Password", 128);
  if (password.length < 8) {
    throw new HttpsError(
        "invalid-argument",
        "Password must be at least 8 characters.",
    );
  }

  let user;
  let stage = "request validation";
  try {
    stage = "Firebase Auth createUser";
    logger.info("Firebase Auth createUser started", {
      functionName,
      callerUid: request.auth.uid,
      requestData: {...values, password: "<redacted>"},
    });
    user = await auth.createUser({
      email: values.email,
      password,
      displayName: values.name,
      disabled: false,
    });
    logger.info("Firebase Auth createUser succeeded", {
      functionName,
      uid: user.uid,
      email: user.email,
    });

    stage = "Firebase Auth setCustomUserClaims";
    logger.info("Firebase Auth setCustomUserClaims started", {
      functionName,
      uid: user.uid,
      claims: {role: "hod"},
    });
    await auth.setCustomUserClaims(user.uid, {role: "hod"});
    logger.info("Firebase Auth setCustomUserClaims succeeded", {
      functionName,
      uid: user.uid,
    });

    stage = "Firestore hods document create";
    const documentId = user.uid;
    const hodReference = hods.doc(documentId);
    const hodData = {
      ...values,
      uid: user.uid,
      isActive: true,
      status: "Active",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: request.auth.uid,
    };
    logger.info("Firestore HOD document create started", {
      functionName,
      collection: "hods",
      documentId,
      data: {
        ...values,
        uid: user.uid,
        isActive: true,
        status: "Active",
        createdBy: request.auth.uid,
        createdAt: "<serverTimestamp>",
        updatedAt: "<serverTimestamp>",
      },
    });
    await hodReference.create(hodData);
    logger.info("Firestore HOD document create succeeded", {
      functionName,
      collection: "hods",
      documentId,
    });

    const response = {uid: user.uid, documentId};
    logger.info("Cloud Function request succeeded", {
      functionName,
      response,
    });
    return response;
  } catch (error) {
    logger.error("Create HOD operation failed", {
      functionName,
      stage,
      callerUid: request.auth && request.auth.uid,
      createdUid: user && user.uid,
      requestData: safeData(data),
      error: errorDetails(error),
    });

    let rollbackError;
    if (user) {
      logger.warn("Rollback Firebase Auth deleteUser started", {
        functionName,
        uid: user.uid,
      });
      await auth.deleteUser(user.uid).then(() => {
        logger.warn("Rollback Firebase Auth deleteUser succeeded", {
          functionName,
          uid: user.uid,
        });
      }).catch((errorDuringRollback) => {
        rollbackError = errorDuringRollback;
        logger.error("Rollback Firebase Auth deleteUser failed", {
          functionName,
          uid: user.uid,
          error: errorDetails(errorDuringRollback),
        });
      });
    }

    const callableError = exactHttpsError(stage, error);
    if (rollbackError) {
      throw new HttpsError(
          "internal",
          `${callableError.message} Auth rollback also failed: ` +
            `${rollbackError.message || rollbackError}`,
          {
            operationError: callableError.details,
            rollbackError: errorDetails(rollbackError),
            uid: user && user.uid,
          },
      );
    }
    logger.error("Create HOD returning callable error", {
      functionName,
      stage,
      code: callableError.code,
      message: callableError.message,
      details: callableError.details,
    });
    throw callableError;
  }
});

exports.updateHod = onCall(async (request) => {
  await requireAdmin(request, "updateHod");
  const data = request.data || {};
  const id = uid(data);
  const values = profile(data);
  const reference = hods.doc(id);
  const existing = await reference.get();
  if (!existing.exists) {
    throw new HttpsError("not-found", "HOD profile was not found.");
  }

  try {
    await auth.updateUser(id, {
      email: values.email,
      displayName: values.name,
    });
    await reference.update({
      ...values,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth.uid,
    });
    return {uid: id};
  } catch (error) {
    throw authError(error);
  }
});

exports.setHodActive = onCall(async (request) => {
  await requireAdmin(request, "setHodActive");
  const data = request.data || {};
  const id = uid(data);
  if (typeof data.isActive !== "boolean") {
    throw new HttpsError("invalid-argument", "Active status is required.");
  }
  const reference = hods.doc(id);
  if (!(await reference.get()).exists) {
    throw new HttpsError("not-found", "HOD profile was not found.");
  }

  try {
    await auth.updateUser(id, {disabled: !data.isActive});
    await reference.update({
      isActive: data.isActive,
      status: data.isActive ? "Active" : "Inactive",
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth.uid,
    });
    return {uid: id};
  } catch (error) {
    throw authError(error);
  }
});

exports.deleteHod = onCall(async (request) => {
  await requireAdmin(request, "deleteHod");
  const id = uid(request.data || {});
  const reference = hods.doc(id);
  const snapshot = await reference.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "HOD profile was not found.");
  }

  try {
    await auth.deleteUser(id);
    await reference.delete();
    return {uid: id};
  } catch (error) {
    throw authError(error);
  }
});
