var form = document.querySelector('.webauthn_key_registration')

if (form) {
  form.addEventListener('submit', function(event) {
    event.preventDefault();
    webauthnRegistrationCeremony();
  });
}

var registrationOptionsPath = "/account/security/webauthn/registration/options";
var registartionCallbackPath = "/account/security/webauthn/registration/callback"
var securityPathWithKeysID = "/account/security#security-keys"

// Full registration ceremony
// 1. Request the registration options from the server
// 2. Encode the challenge and user data as an ArrayBuffer
// 3. Send it to the browser API
// 4. Decode the data from ArrayBuffers
// 5. Send it back to the server
function webauthnRegistrationCeremony() {
  requestRegistrationFromServer()
    .then((response) => response.json())
    .then((createOptions) => encodeRegistrationCreateOptions(createOptions))
    .then((encodedCreationOptions)  => create(encodedCreationOptions))
    .then((publicKeyCredential) => decodeRegistrationPublicKeyCredentials(publicKeyCredential))
    .then((decodedPublicKeyCredential) => sendRegistrationResponseToServer(decodedPublicKeyCredential))
    .then((registrationAttemptResponse) => handleRegistrationResponse(registrationAttemptResponse))
    .catch((err) => handleErrors(err))
}

// Error handling
function handleErrors(err) {
  if( err.message === "An attempt was made to use an object that is not, or is no longer, usable") {
    // We should handle this with a flash banner
    console.log("I think you are trying to register a key that is already registered")
  }
}

// Javascript to talk to the browser API
// =====================================
function create(encodedCreateOptions) {
  return navigator.credentials.create({"publicKey": encodedCreateOptions});
}

// To and from the server
// ======================
function requestRegistrationFromServer() {
  return fetch(registrationOptionsPath);
}

function sendRegistrationResponseToServer(decodedPublicKeyCredential) {
  var nickname = document.getElementsByName('credential_nickname')[0].value
  var body = { "publicKeyCredential": decodedPublicKeyCredential }
  if (nickname !== "" && nickname.length < 15) {
    body.credential_nickname = nickname
  }
  return fetch(registartionCallbackPath, {
    "method": "POST",
    "headers": {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": getCSRFToken()
    },
    "credentials": "same-origin",
    "body": JSON.stringify(body)
  });
}

function handleRegistrationResponse(response) {
  if (response.ok) {
    window.location.replace(securityPathWithKeysID)
  } else if (response.status < 500) {
    console.log(response.text)
  } else {
    console.log("Sorry something went wrong")
  }
}

// Encode and decode ArrayBuffers
// ==============================
function decodeRegistrationPublicKeyCredentials(publicKeyCredential) {
  return Object.assign({
    "id": publicKeyCredential.id,
    "rawId": bufferToBase64url(publicKeyCredential.rawId),
    "response": {
      "attestationObject": bufferToBase64url(publicKeyCredential.response.attestationObject),
      "clientDataJSON": bufferToBase64url(publicKeyCredential.response.clientDataJSON),
    },
    "type": publicKeyCredential.type
  })
}

function encodeRegistrationCreateOptions(createOptions) {
  createOptions.challenge = base64urlToBuffer(createOptions.challenge);
  createOptions.user.id = base64urlToBuffer(createOptions.user.id);
  createOptions.excludeCredentials = createOptions.excludeCredentials.map((c) => base64ArrayToArrayBuffer(c))

  if (authenticatorAttachmentToUndefined(createOptions) === true) {
    createOptions.authenticatorSelection.authenticatorAttachment = undefined
  }

  return createOptions;
}

function authenticatorAttachmentToUndefined(createOptions) {
  return (createOptions.authenticatorSelection && createOptions.authenticatorSelection.authenticatorAttachment === null)
}

