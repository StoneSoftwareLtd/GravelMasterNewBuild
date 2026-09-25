# Account pages

The site's account pages in the new design. There's no Optima prototype for them, so they use the new pages' panels, boxes, errors and buttons (the checkout's), with the same colours. Built on 25 September 2026 and tested in the preview. **Not on the site yet**: wiring them in is listed in [merging.md](merging.md#account-pages-signing-in).

Part 1, here: signing in, creating an account, applying for a trade account, forgotten and reset password, and the messages those lead to. Part 2 is the pages behind the sign-in (My Account).

## Files

| File | What it is |
|---|---|
| `Views/Account/_SignInPage.cshtml` | sign in, create an account and apply for a trade account (`Account/Login.cshtml`), and the "You're in!" page for an approved trade customer |
| `Views/Account/_ForgotPasswordPage.cshtml` | forgotten password (`ForgotPassword.cshtml`) |
| `Views/Account/_ResetPasswordPage.cshtml` | choose a new password, from the reset email's link (`ResetPassword.cshtml`) |
| `Views/Account/_AccountMessagePage.cshtml` | the five pages that only say something: link sent, password changed, email confirmed, registered, trade application sent |
| `ViewModels/Common/AccountPageModels.cs` | `SignInPageModel`, `AccountFormModel` and the `AccountMessage` list |
| `css/gm-account.css` | the styles, scoped to `.gm-account`, with the same shield against the old CSS as the other new pages |
| `js/gm-account.js` | the checks before sending, show/hide password, personal or trade, and moving to errors |

Each partial links `gm-account.css` itself, rather than through a `Head` section: most of the old account views sit in `_AccountMaster.cshtml`, which can't pass a section on to `_Layout`.

## What the old pages do, and where each part went

Read from `Views/Account/*.cshtml`, `Views/Shared/_AccountMaster.cshtml`, `AccountController` and `Models/AccountViewModels.cs` on `master`; the live sign-in and forgotten-password pages match them. `AccountController` differs on `stripe`, but not in these actions' forms.

| Old page | New page |
|---|---|
| Sign in and Register on two tabs (Bootstrap 5, loaded from a CDN just for this page) | Sign in and "New to GravelMaster?" side by side, one above the other on phones |
| Sign in: Email, Password, "Remember me", to `/account/login` | The same fields to the same address. "Remember me" had no name, so it was never sent and never did anything; it's left out ([open question](open-questions.md#account-pages)) |
| Register: a Non-Trade / Trade choice | "Which account would you like?": Personal or Trade, as cards like the checkout's delivery times |
| Non-Trade: FirstName, LastName, Email, Password, ConfirmPassword to `/account/register` | The same fields to the same address, with labels, "At least 6 characters", and show/hide on the password. After a failed registration the email address stays filled in (the old page emptied it) |
| Trade: first, last, email, phone, companyName, typeCustomer, paymentType to `/account/traderegister`, with an "I agree" tick box that sent nothing | The same fields to the same address. The two lists start on "Choose one" and must be chosen, the phone number must start with 0, and the terms must be ticked (see below) |
| "You're In!" for an approved trade customer (`?tradeEmail=`), with their email fixed | "You're in!", with the same form and the email fixed |
| The privacy policy link to `gravemaster.co.uk/privacy` (misspelt, so broken) | `/privacy` |
| Errors in a red list under the button | In a box above the form, which the page moves to when it opens with errors |
| Forgotten password (in `_AccountMaster`'s grey and purple frame) | The new panel, posting Email to `/account/forgotpassword` |
| Reset password | The new panel, posting Email, Password, ConfirmPassword and the link's Code to `/account/resetpassword` |
| Five short pages ("Forgot Password Confirmation", "Reset password confirmation", "Confirm Email", "Thank you!", "Trade Account requested") | One message page each, in words that say what actually happens (below) |

Every form carries the anti-forgery token, as before.

### The trade form's checks

`AccountController.TradeRegister` quietly drops an application whose phone number contains a "+" or doesn't start with 0, or whose payment type is still "Payment Type*" (the old list's first entry), but shows "Trade Account requested" either way. So someone who typed +44, or didn't pick a payment type, thinks they've applied and hasn't. A blank phone number stops the page with an error. The new form checks all three before sending, so a real applicant is told what to change. The server's filter is unchanged, so anything else it catches is still dropped ([open question](open-questions.md#account-pages)).

### The messages

| Page | Old words | New words |
|---|---|---|
| Link sent | "Please check your email to reset your password." | "Check your email. If there's an account for that email address, we've sent it a link to choose a new password." (The server doesn't say whether the address has an account, and only sends to confirmed ones.) |
| Password changed | "Your password has been reset. Please click here to login" | "Your password has been changed. You can now sign in with your new password.", with Sign in |
| Email confirmed | "Thank you for confirming your email. Please click here to login" | The same, with Sign in |
| Registered | "Nearly there! … Open your welcome email, click on the activation button …" | "Nearly there. We've emailed you a link to confirm your email address", then: open the email called "Confirm your account" (its real subject), click the link, sign in. The old steps described a welcome email with an activation button, which isn't what's sent |
| Trade application sent | "We have your application and will be in touch by email shortly" | "Thank you for your application. We have your trade account application, and we'll be in touch by email shortly.", with Continue shopping and About trade accounts |

Not carried over: the "Locked out" page (lockout is switched off, and its view expects a different model, so it can't show) and the two-factor pages (`SendCode`, `VerifyCode`), which nothing reaches.

## Changed on the site as a whole

- `NewChrome.IsOn(Request)` (its own commit): the page views need the same new-design switch as `_Layout`.
- The header now leaves room for itself when a page moves to something on a phone (its own commit), found on this page: the registration error ended up underneath the sticky header.

## Tested

In the whole-website preview on 25 September 2026: `/account/login` (with `?isTradeRegister=true`, `?signinerror=1`, `?registererror=1` and `?tradeconfirm=1` for the other states), `/account/forgotpassword` and `/account/resetpassword` (each with `?error=1`), and the five messages at `/account/forgotpasswordconfirmation`, `/resetpasswordconfirmation`, `/confirmemail`, `/register` and `/traderegister`. The frames are the live sign-in and forgotten-password pages; the preview never loads the live email-confirmation link, which confirms an account.

- The four partials compile with MVC 5.2's Razor. So does the code for `Login.cshtml`, `ForgotPassword.cshtml`, `ResetPassword.cshtml`, a message view and `_AccountMaster.cshtml` ([merging.md](merging.md#account-pages-signing-in)), against stand-ins with the site's own names.
- Screenshots at 1440 and 390px; the layout measured at seven widths from 1440 to 320px, with nothing wider than the screen.
- Every text colour on six of the pages measured against its background: all pass AA, the lowest 5.26:1; box edges 3.35:1 or more.
- In the browser, with every form stopped and what it would send recorded:
  - Sign in: nothing filled in gives two messages and goes to the email box; a bad email is caught; the form sent `__RequestVerificationToken`, `Email` (trimmed) and `Password`, and the button said "Signing in…".
  - Create an account: a 5-character password and a mismatch are caught; fixing the password rechecks the confirmation; the form sent the token, `FirstName`, `LastName`, `Email`, `Password` and `ConfirmPassword`.
  - Trade: "+44 7700 900123" and "7700 900123" are caught, as are the unchosen lists and the unticked terms; the form sent the token, `first`, `last`, `email`, `phone`, `companyName`, `typeCustomer` and `paymentType`, and nothing for the tick box.
  - Personal/Trade switches the forms; Show/Hide switches the password and says which it is.
  - Forgotten password sent the token and `Email`; reset password sent the token, `Code`, `Email`, `Password` and `ConfirmPassword`, after catching a mismatch.
- In headless Edge: opened with an error (or for a trade account) the page moves to it and gives it focus; on a phone it lands just below the header.

Not tested: signing in, registering, applying and resetting for real, and the emails. These need the test website.
