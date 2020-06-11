Account Management
==================

![Flowchart of the registration process](registration-flowchart.png)

The registration process is quite standard, there are two parts to it:

1. The user fills in the registration form and we send them an email
   to confirm their account.

2. The user clicks the link in the email we sent them, to confirm they
   can access that email.

We're not necessarily confirming that the user is the *owner* of the
inbox.  For example, someone could have compromised their email
account.

We may display error pages at the following points of the process:

- In part 1:
  1. If an account already exists with that email address.

- In part 2:
  1. If the confirmation link refers to a user who doesn't exist.
  2. If the email address has already been confirmed.
  3. If the token in the confirmation link is incorrect or has expired.

For part 1 we also will need to implement: checking that the given
email address is plausibly an email address and that the given
password meets any requirements we set.  Such requirements will be
based on industry recommendations.

In case 2.3, we give the user an option to send a new confirmation
email.
