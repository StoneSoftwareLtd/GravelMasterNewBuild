# Payment error page

The page at `/checkout/orderresulterror`, in the new design. Built on 28 September 2026 and tested in the preview, where "Continue to payment" ends on it because payment isn't set up there. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#payment-error-page).

## When customers see it

`CheckoutController` sends customers to it in two cases:

- **Before payment**, from "Continue to payment" (`ProcessOrder`), when the delivery postcode isn't in the postcode area the basket was priced for. The address then ends `?loc=ng` (the basket's area). The new checkout already checks this before sending, so customers only get here without its script, or when the basket's area changed in another tab.
- **After payment**, when the payment provider says a payment failed (its notification, `OrderNotify`, points failed payments here). No `?loc`.

(One more: `ProcessOrder` sends one particular address, blocked by name, here with `?loc` set to its postcode. The new page shows it as a postcode outside the basket's area, with the postcode's letters.)

## Files

| File | What it is |
|---|---|
| `Views/Checkout/_PaymentErrorPage.cshtml` | the new page |
| `ViewModels/Common/PaymentErrorModels.cs` | `PaymentErrorModel`: the basket's area from `?loc`, in capitals, or none. Only its first one or two letters are kept |
| `css/gm-info.css` | its styles (`.gm-payerror`), with the information pages' |

`Checkout/Error.cshtml` shows it when the new chrome is on ([merging.md](merging.md#payment-error-page)).

## The old page's security hole (probably live now)

`Error.cshtml` on master writes `?loc` into the page exactly as it's given (`Html.Raw`), so anyone could make a link to `www.gravelmaster.co.uk/checkout/orderresulterror?loc=...` that runs their own script on the site, in the customer's browser, as if it were GravelMaster's page. That's called cross-site scripting. It was found by reading the code. The live page does write the area into the page (a plain page view with `?loc=ng` shows "(ng)"), but nothing was tried against the live site to see whether it's encoded, and the live view is a little newer than master's (it leaves out the phone number in that case).

The new page only takes the letters of the area, and Razor encodes them. The old page should be fixed too, now, whatever happens with the new design: the change is in [merging.md](merging.md#payment-error-page) (one line, no change to what customers see).

## What the old page shows, and where each part went

| Old page | New page |
|---|---|
| "Transaction Error" | "There was a problem with your payment", or with `?loc`, "Your delivery postcode doesn't match your basket". The page title is "Payment problem" (was "Error") |
| "No payment has been taken", at the bottom | "No payment has been taken", with a tick, under the heading |
| "Unfortunately, there was a problem with the transaction. Please call customer services on 0330 058 5068" | The same, with "Please try again, or" before calling, and the number can be tapped |
| "The delivery address entered does not match the selected area (ng) used to add to basket." (master's view adds "Please call customer services on 0330 058 5068"; the live page doesn't) | "The delivery address entered does not match the area (NG) used to add to your basket. Our prices include delivery, so they depend on where we deliver." then "Please check the delivery postcode, or call customer services on 0330 058 5068." |
| Nothing else | Buttons: "Back to your basket" and "Call 0330 058 5068"; with `?loc`, "Back to checkout" and "View your basket". Then customer services' hours (option 2) and email |

## Tested (28 September 2026)

- The page and the model compile. The merge code for `Error.cshtml` compiles and was run with a stand-in for `_Layout`: with the new design on, it shows the new page with `gm-info.css` in the head and the title "Payment problem"; `?loc=ng` gives the NG version, `?loc=CM77 8BE` a CM one, and `?loc=<script>...` the ordinary version with no script in the page. With the design off, it shows the old page, and with the fix, the script comes out as harmless text.
- In the preview, from a real checkout of the working basket: "Continue to payment" landed on the page; a postcode outside the basket's area, sent past the checkout's own check, landed on the `?loc` version.
- Nothing wider than the screen at 8 widths from 1440 to 320px, both versions; screenshots at 1440 and 390px.
- Colours: text 5.5:1 or more.
- No script errors.

Not tested: the page after a real failed payment, which needs the test website with test payments.
