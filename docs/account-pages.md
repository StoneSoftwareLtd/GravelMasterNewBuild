# Account pages

The site's account pages in the new design. There's no Optima prototype for them, so they use the new pages' panels, boxes, errors and buttons (the checkout's), with the same colours. Built on 25 September 2026 and tested in the preview. **Not on the site yet**: wiring them in is listed in [merging.md](merging.md#account-pages-signing-in) and [merging.md](merging.md#my-account-pages).

Part 1: signing in, creating an account, applying for a trade account, forgotten and reset password, and the messages those lead to. [Part 2](#part-2-my-account): the pages behind the sign-in (My Account).

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

## Part 2: My Account

The pages a signed-in customer sees: their orders, returns, price match and address. The old pages sit in `_AccountMaster.cshtml`'s grey bar and purple side column; the new ones share a top of their own instead: "Hi *name*" (with a "Trade account" tag for trade customers, where the old column said "Trade Portal"), the email address, Continue shopping, and tabs for the same links as the old column. On phones the tabs become buttons that wrap, so Sign out isn't hidden off the side.

### Files

| File | What it is |
|---|---|
| `Views/MyAccount/_AccountAreaHead.cshtml` | the greeting and tabs at the top of each page |
| `Views/MyAccount/_OrdersPage.cshtml` | your orders (`Orders.cshtml`, which `/myaccount` goes to) |
| `Views/MyAccount/_ReturnsPage.cshtml` | the returns policy (`Returns.cshtml`) |
| `Views/MyAccount/_RequestReturnPage.cshtml` | the return form for one item (`RequestReturn.cshtml`) |
| `Views/MyAccount/_ReturnDonePage.cshtml` | "Return request sent" (`ReturnConfirmation.cshtml`) |
| `Views/MyAccount/_PriceMatchPage.cshtml` | price match (`PriceMatch.cshtml`) |
| `Views/MyAccount/_AddressPage.cshtml` | your address (`EditAddress.cshtml`) |
| `ViewModels/Common/MyAccountPageModels.cs` | the models, and `AccountOrderLine.Describe`, which turns an order line's saved name into its size or options |
| `css/gm-account.css`, `js/gm-account.js` | part 1's files, with the My Account styles and behaviour added |

The returns pages are on `master` only. `AccountAreaModel.ShowReturns` (on by default) hides the Returns tab and the orders' "Request a return" on a branch without them.

### What the old pages do, and where each part went

Read from `Views/MyAccount/*.cshtml`, `Views/Shared/_AccountMaster.cshtml`, `MyAccountController` and the `Agilis.ECommerce.Data` source on `master`. The live `/myaccount` pages need signing in, so they couldn't be compared.

| Old page | New page |
|---|---|
| Order History: one box per item, each with its own order number, date and address | Your orders: one card per order (newest first, as before), with its number, date and delivery address, then its items. "Track order" opens the site's Track Order pop-up with the order number and postcode filled in |
| Each item: photo, name, the saved name without its HTML, "QTY", "Request Return" | Photo, name (linked), size, "Quantity", "Request a return" to the same address. The checkout saves the line as `Product.NameWithVariants`, "*name*&lt;br/&gt;*size*&lt;br/&gt;", and the old page removed the `<br/>`s without a space ("Cotswold Chippings 20mmApprox 850Kg Bulk Bag"); the new page shows the size under the name (several options with commas) |
| Photos at 300px, which most products don't have (the pegs and turf, for example), so most items had no picture | The 330px photo every product has |
| Returns: the policy and "View My Orders" | The same words, the policy as a ticked list |
| Request a Return: the item, then Has it been used, Reason, Resolution and Notes, posted to `/myaccount/requestreturn` | The item beside the form, with the same fields, choices and values, posted to the same address with the anti-forgery token. The note about refunds shows when "Full refund" is chosen (the old page showed it after any reason) |
| Return Request Submitted | "Return request sent", with the same words and links |
| Price Match: the words, a box and Send, which put the message in the address as it was, so a "&amp;" or "#" cut it short ("B&amp;Q" arrived as "B"); "Message Sent" if it worked, nothing if it didn't | The same words and address, with the message encoded so it arrives whole; it's checked first (at least 5 characters, as before), and the page says whether it was sent. Without JavaScript the form opens that address itself |
| Edit Billing Address: Address1, Address2, City, County, Postcode with the anti-forgery token, posted to `/myaccount/editaddress` | "Your address": the same fields to the same address, with labels, and the first line, town and postcode required (the postcode checked as at the checkout). "Billing" is gone: the checkout fills this address in as the delivery address |
| The side column's Orders, Price Match, Returns, Edit Address, Log Out | The tabs: Orders, Returns, Price match, Address, Sign out (`/account/logoff`, as before) |

Not carried over: `/myaccount/quotes`, a page of made-up quotes that nothing links to, and `/myaccount/view`, a page of raw order details that nothing links to ([open questions](open-questions.md#account-pages)).

### Tested

In the whole-website preview on 25 September 2026, at `/myaccount/orders` (with `?empty=1`, `?trade=1` and `?noreturns=1`), `/returns`, `/requestreturn`, `/returnconfirmation`, `/pricematch` and `/editaddress`: a sample customer with two sample orders of real products, in the live forgotten-password page's frame (the live `/myaccount` sends the preview, which is never signed in, to sign in).

- The seven partials compile with MVC 5.2's Razor, and so does the code for the six old views ([merging.md](merging.md#my-account-pages)), against stand-ins copied from the classes in the repository's own `Agilis.ECommerce.Data` source.
- `AccountOrderLine.Describe` with 18 saved names (one and several options, `<br/>`, `<br />` and `<BR>`, no `<br/>` at all, different capitals, a product renamed since, a longer name that starts with the product's, HTML entities, blank): all as expected.
- Nothing wider than the screen at seven widths from 1440 to 320px; screenshots at 1440 and 390px.
- Every text colour on the seven pages measured against its background: all pass AA, the lowest 5.27:1; box edges 3.35:1, the current tab's line 6.1:1.
- In the browser:
  - Track order opened the pop-up with the order number and postcode filled in, and the page stayed where it was.
  - The return form: sending it empty gives three messages and goes to the first; the refund note shows for "Full refund" only; filled in, it sent `__RequestVerificationToken`, `OrderItemId`, `HasBeenUsed`, `Reason`, `Resolution` and `Notes`.
  - The address form: a blank first line and town, and "NG7", are caught; it sent the token, `Address.AddressID`, `Address.Address1`, `Address.Address2`, `Address.City`, `Address.County` and `Address.Postcode`.
  - Price match (with the sending stood in for): empty and 3-character messages are caught; "Cotswold 20mm bulk bag at B&amp;Q for £80 #cheaper" was sent whole and the page said so; a failure keeps the message and gives the phone number. The real address is blocked by the preview.

Not tested: the pages with a real account and real orders, sending a return or price match for real, and saving an address. These need the test website.
