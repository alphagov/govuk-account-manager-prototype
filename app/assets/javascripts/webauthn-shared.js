// Taken from @github/webauthn-json:
// https://github.com/github/webauthn-json/blob/3a758a247b11a0dcc60b7aa5ef32b3a72f9f1549/src/base64url.ts#L23
function  bufferToBase64url(buffer) {
  // Buffer to binary string
  var byteView = new Uint8Array(buffer);
  var str = "";
  for (var charCode of byteView) {
    str += String.fromCharCode(charCode);
  }

  // Binary string to base64
  var base64String = btoa(str);

  // Base64 to base64url
  // We assume that the base64url string is well-formed.
  var base64urlString = base64String
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  return base64urlString;
}

// Taken from @github/webauthn-json:
// https://github.com/github/webauthn-json/blob/3a758a247b11a0dcc60b7aa5ef32b3a72f9f1549/src/base64url.ts#L3
function base64urlToBuffer(baseurl64String) {
  // Base64url to Base64
  var padding = "==".slice(0, (4 - (baseurl64String.length % 4)) % 4);
  var base64String =
    baseurl64String.replace(/-/g, "+").replace(/_/g, "/") + padding;

  // Base64 to binary string
  var str = atob(base64String);

  // Binary string to buffer
  var buffer = new ArrayBuffer(str.length);
  var byteView = new Uint8Array(buffer);
  for (let i = 0; i < str.length; i++) {
    byteView[i] = str.charCodeAt(i);
  }
  return buffer;
}

function getCSRFToken() {
  var CSRFSelector = document.querySelector('meta[name="csrf-token"]')
  return CSRFSelector ? CSRFSelector.getAttribute("content") : null
}

function base64ArrayToArrayBuffer(credential) {
  credential.id = base64urlToBuffer(credential.id);
  return credential
}
