document.addEventListener("DOMContentLoaded", function() {
  var form = document.querySelector('.webauthn_key_authentication');

  form.addEventListener('submit', function(event) {
    event.preventDefault();
    webauthnAuthentcationCeremony();
  });
})

var authenticationOptionsPath = "/account/mfa/webauthn/options";
var authenticationCallbackPath = "/account/mfa/webauthn/callback"
var accountRootPath = "/"

// Full authentication ceremony
// 1. Request the authentication options from the server
// 2. Encode the challenge and user data as an ArrayBuffer
// 3. Send it to the browser API
// 4. Decode the ArrayBuffers returned from the Browser API
// 5. Send it back to the server
function webauthnAuthentcationCeremony() {
  requestAuthenticationFromServer()
    .then((response) => response.json())
    .then((getOptions) => encodeGetOptions(getOptions))
    .then((encodedCreationOptions)  => get(encodedCreationOptions))
    .then((publicKeyCredential) => decodePublicKeyCredentials(publicKeyCredential))
    .then((decodedPublicKeyCredential) => sendResponseToServer(decodedPublicKeyCredential))
    .then((authenticationAttemptResponse) => handleAuthenticationAttemptResponse(authenticationAttemptResponse))
    .catch((err) => handleErrors(err))
}

// Error handling
function handleErrors(err) {
  console.log(err)
}

// Javascript to talk to the browser API
// =====================================
function get(encodedGetOptions) {
  return navigator.credentials.get({"publicKey": encodedGetOptions});
}

// To and from the server
function requestAuthenticationFromServer() {
  return fetch(authenticationOptionsPath);
}

function sendResponseToServer(decodedPublicKeyCredential) {
  return fetch(authenticationCallbackPath, {
    "method": "POST",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": getCSRFToken()
    },
    "credentials": "same-origin",
    "body": JSON.stringify({ "publicKeyCredential": decodedPublicKeyCredential })
  });
}

function handleAuthenticationAttemptResponse(response) {
  if (response.ok) {
    window.location.replace(accountRootPath)
  } else if (response.status < 500) {
    console.log(response.text)
  } else {
    console.log("Sorry something went wrong")
  }
}

// Encode and decode ArrayBuffers
// ==============================
function decodePublicKeyCredentials(publicKeyCredential) {
  return Object.assign({
    "id": publicKeyCredential.id,
    "rawId": bufferToBase64url(publicKeyCredential.rawId),
    "response": {
      "authenticatorData": bufferToBase64url(publicKeyCredential.response.authenticatorData),
      "clientDataJSON": bufferToBase64url(publicKeyCredential.response.clientDataJSON),
      "signature": bufferToBase64url(publicKeyCredential.response.signature),
      "userHandle": publicKeyCredential.response.userHandle
    },
    "type": publicKeyCredential.type
  })
}

function encodeGetOptions(getOptions) {
  getOptions.challenge = base64urlToBuffer(getOptions.challenge)
  getOptions.allowCredentials = getOptions.allowCredentials.map((c) => base64ArrayToArrayBuffer(c))
  return getOptions;
}

function authenticatorAttachmentToUndefined(getOptions) {
  return (getOptions.authenticatorSelection && getOptions.authenticatorSelection.authenticatorAttachment === null)
}
