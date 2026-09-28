# Security fixes to pass on

Found on 28 September 2026 by reading GravelMasterSoftware's code (the `master` branch, cloned 23 September). Nothing here was tried against the live site beyond ordinary page views. No passwords or keys are copied anywhere in this folder.

The code that's live isn't on any branch ([merging.md](../docs/merging.md#before-anything-which-code-is-live)), so each fix says what to look for as well as giving a patch against `master`.

| # | What | How serious | What to do |
|---|---|---|---|
| 1 | Four places print what's in a link or form straight into the page | High: anyone can make a link that runs their own code on www.gravelmaster.co.uk | Apply the fix below now. It changes nothing customers see |
| 2 | An old payment test page signs whatever is sent to it | Medium to high | Delete it |
| 3 | Passwords and keys written into the code | High | Change them, then move them out of the code |

## 1. Visitors' text printed into pages without encoding ("cross-site scripting")

When a page puts text from its web address, or from a form, into the page without encoding it, someone can make a link to that page with a small program hidden in the address. Anyone who opens the link sees the real GravelMaster page, but running the program, which can do anything the page can: change what it says, show a fake payment or sign-in form, or act as the customer on the site. Encoding makes the text show as text, never as code.

| Page | File | Find | Replace with |
|---|---|---|---|
| Payment error (`/checkout/orderresulterror?loc=...`) | `Website/Website/Views/Checkout/Error.cshtml` | `@Html.Raw("The delivery address entered does not match the selected area (" + Request.QueryString["loc"] + ") used to add to basket.")` | `@("The delivery address entered does not match the selected area (" + Request.QueryString["loc"] + ") used to add to basket.")` |
| Search results (`/search?searchphrase=...`) | `Website/Website/Views/Category/DisplayProducts.cshtml` | `@Html.Raw("'" + Request.QueryString["searchphrase"] + "'")` | `@("'" + Request.QueryString["searchphrase"] + "'")` |
| Special offers (the same line) | `Website/Website/Views/Product/SpecialOffers.cshtml` | `@Html.Raw("'" + Request.QueryString["searchphrase"] + "'")` | `@("'" + Request.QueryString["searchphrase"] + "'")` |
| Track Order's answer (`/checkout/checkmyorder`) | `Website/Website/Controllers/CheckoutController.cs`, `CheckMyOrder` | `return Content("We have found the order, but the postcode is not: " + postcode);` | `return Content("We have found the order, but the postcode is not: " + System.Web.HttpUtility.HtmlEncode(postcode));` |

In each view, only `Html.Raw` goes: `@( ... )` prints the same words, encoded. The Track Order one is sent by a form rather than a link, but another website can send that form for a visitor, so it matters too.

**The patch.** [encode-visitor-input.patch](encode-visitor-input.patch) makes all four changes. From the top folder of GravelMasterSoftware:

```bash
git apply --check security-fixes/encode-visitor-input.patch
```

(with the patch copied there, or its full path), then the same without `--check`. It applies cleanly to `master` as cloned on 23 September 2026. If the live code differs, make the four changes by hand with the table above. `CheckoutController.cs` needs the Website project rebuilding; the views don't.

**Checked:**
- all three views still compile with MVC 5.2's Razor;
- the fixed payment error page was compiled and run:
  - `?loc=ng` gives exactly the same sentence as before, "(ng)";
  - with a script in `?loc`, the script comes out as plain text (`&lt;script&gt;`), so it doesn't run.

**To check on the site after it's deployed**, with harmless bold tags rather than a script:
- `/checkout/orderresulterror?loc=<b>NG</b>` should show `<b>NG</b>` as typed, not a bold **NG**;
- `/search?searchphrase=<b>slate</b>` should do the same on the old search page.

The new-design pages (in the rest of this repository) already encode everything they print. That includes the new payment error page, which keeps only the letters of `?loc`.

## 2. The old CyberSource payment test page (`/checkout/paymentconfirmation`)

`CheckoutController.PaymentConfirmation` shows `Views/Checkout/PaymentConfirmation.cshtml`, a leftover page for CyberSource's test system (`testsecureacceptance.cybersource.com`). It:
- writes every field posted to it straight into the page, unencoded (the same problem as above, from a form);
- signs whatever was posted with a CyberSource secret key that's written into `Website/Website/Services/Security.cs`, so anyone could get CyberSource-signed requests from it.

Nothing else uses it: the checkout's payments start from `ProcessOrder`, through `orderWorkflow.InitiateTransaction`, not this page. The address exists on the live site: a plain visit gives an error page (500) rather than "not found".

**Delete:**
- the `PaymentConfirmation` action in `CheckoutController.cs` (4 lines);
- `Views/Checkout/PaymentConfirmation.cshtml`;
- `Services/Security.cs`;
- their two lines in `Website.csproj`.

If the CyberSource account is still used for anything, have its secret key replaced.

## 3. Passwords and keys written into the code

Anyone who can read the repository, or its history, can read these. Deleting them from the code isn't enough, because git's history keeps them: each needs **changing** (a new password or key), then reading from configuration that isn't in the repository.

- **The database's user names and passwords**, for 2 database servers, in 48 source files. Among them are the website's `Agilis.ECommerce.Business/IdeasRepository.cs`, `ReviewsAdminRepository.cs`, `Agilis.ECommerce.Data/Log.cs` and `Controllers/RefreshController.cs`, plus the admin sites and the utility programs.
- **`Website/Website/Web.config`**, with the live database password, is in the repository.
- **A Mailchimp API key** in `CheckoutController.cs`.
- **A Palletforce tracking access key** in `CheckoutController.cs` (`GetStatus`, used by Track Order).
- **A CyberSource secret key** in `Services/Security.cs` (item 2).
- **Azure Search admin keys** in `Controllers/BrandController.cs` and `Controllers/CategoryController.cs`, which the search no longer uses.
- **Campaign Monitor keys** (the email service) in seven controllers: `AccountController.cs`, `BasketController.cs`, `CheckoutController.cs`, `ContentController.cs`, `EmailController.cs`, `MyAccountController.cs` and `ProductController.cs`. With one, anyone could send email as GravelMaster or read the mailing lists.

## Checked and fine

- After signing in, the site only sends people back to pages on its own site (`Url.IsLocalUrl`), so its links can't be used to send customers to another website.
- The other places that print HTML as it is (`Html.Raw`) print product names, sizes and descriptions typed into the admin site, not anything visitors send.
