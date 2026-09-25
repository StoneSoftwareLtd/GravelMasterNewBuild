# Order confirmation

The Optima prototype's order confirmation (`confirmation.html` in GravelMasterDesigns), rebuilt for the page customers see after paying, `/checkout/orderresult`. Built on 24 and 25 September 2026 and tested in the preview with a sample order. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#order-confirmation).

## Files

| File | What it is |
|---|---|
| `Views/Checkout/_ConfirmationPage.cshtml` | the new page, as a partial that shows a `ConfirmationPageModel` |
| `ViewModels/Common/ConfirmationPageModels.cs` | `ConfirmationPageModel`; its suggestions use the basket's `BasketSuggestion` |
| `css/gm-confirmation.css` | its styles, scoped to `.gm-confirm`, with the same shield against the old CSS as the other new pages |
| `js/gm-confirmation.js` | Track your order, the suggestions' Add to basket, and photos that don't load |
| `img/gm-confirm-bag.png` | the prototype's branded bulk bag (`half-bag.jpg` there, which is really a PNG with a see-through background): 600px, 253 KB, drawn twice in the illustration |

`Checkout/OrderResult.cshtml` fills the model from its `OrderResultViewModel` ([merging.md](merging.md#order-confirmation)).

## How the page is reached

After payment, Opayo (SagePay) tells the site the result (`CheckoutController.OrderNotify`) and sends the customer to `/checkout/orderresult?transId=…`. **Loading that page isn't only a page view.** `CheckoutController.OrderResult` marks the order as paid (`SetSuccessfullTransaction`), sends the confirmation emails if they haven't gone yet, and empties the basket. So:

- the new page never reloads itself (after adding a suggestion it goes to the basket instead);
- the preview never asks the live site for it. `Get-Live` refuses any `/checkout/orderresult` address, and the preview's sample page is shown in the live basket page's frame.

The emails are only sent once per order (`SendEmails` checks `EmailSent`), so a customer reloading the page doesn't get them twice. The Google, Bing and Facebook purchase events are only written the first time too.

## What the old page shows, and where each part went

Read from `Views/Checkout/OrderResult.cshtml`, `OrderResultViewModel` and `CheckoutController` (`OrderResult`, `SendEmails`) on `master`. The `stripe` branch's view differs only in leaving out the `trade_order` event.

| Old page | New page |
|---|---|
| "Thanks *name*, your order has been confirmed!" | The prototype's "Thank you for your order!" |
| "Your order number is *number*" | "Order number: *number*" |
| "We have recieved your payment of *amount*…" | "We've received your payment of *amount*, and your order is now being processed by our team." |
| "We'll send your confirmation email to *email*" | The prototype's email panel: "Your confirmation email is on its way to *email*. Check your inbox (and spam folder) for your order details." |
| "Delivery to *address*" (with the name, a blank for an empty second line, and "GB") | "Delivering to: *address*", without the name, the country or blank lines |
| The purchase events for Google Analytics, Bing and Facebook, and `trade_order` for trade accounts | Unchanged: they're in the view's `Head`, `analyticscripts` and `facebook` sections and after the page, outside the part being replaced |

From the prototype, not on the old page: the illustration, "Track your order" and "Continue shopping", "You might also like", and the help strip with the phone number.

## Choices

- **"Track your order"** opens the site's own Track Order pop-up (`_TrackOrderModal`), the same one as the header's link, with the order number and the delivery postcode already filled in.
- **"You might also like"** has the prototype's picks that are on the site: the FeatherSnap Bird Feeder, the Large Galvanised Stainless Steel Planter, the Trowel and the Gardening Gloves. The prototype's fifth, a wheelbarrow, isn't sold on the site. Their prices come from the site (the prototype's were made up: the planter is £62.99, not £45.99, and the gloves £9.99, not £4.99). "Add to basket" makes the same request as the basket page's suggestions, then goes to the basket.
- **The customer's name** isn't in the heading. The prototype's heading has none, and the name is whatever was typed as the full name.
- **Colours**, measured against what's behind them: the prototype's green (`#388038`) is 4.4:1 on the email panel, so text, buttons and the tick use the darker green of the other new pages. Every text colour on the page passes WCAG AA.
- **The email address** sits on its own line and breaks after the @ when the panel is narrow, rather than mid-word.
- **On phones** the illustration is smaller (at most 300px), so the message comes sooner. The suggestions' buttons stay on one line; the basket page now does the same (its own commit).

## Tested

In the whole-website preview (`/checkout/orderresult`), on 24 and 25 September 2026, with a sample order: order 123456, £260.50, sample.customer@example.com, 1 Sample Street, Nottingham, NG7 2RD. The suggestions are the real products at their live prices.

- The partial compiles with MVC 5.2's Razor. So does the code `OrderResult.cshtml` will need ([merging.md](merging.md#order-confirmation)), against stand-ins with the site's own class and property names.
- The preview refuses `/checkout/orderresultx?transId=…` ("The preview never loads the live order confirmation"). The sample page itself was served without asking the live site for it (its log shows the basket page fetched as the frame).
- Screenshots at 1440, 1024, 768 and 390px; the layout measured at 11 widths from 1440 to 320px, with nothing wider than the screen.
- Every text colour measured against its background: all pass AA, the lowest 4.87:1.
- In the browser:
  - "Track your order" opened the Track Order pop-up with 123456 and NG7 2RD filled in, and didn't change the address in the address bar.
  - "Add to basket" on the Trowel sent `/basket/addtobasket?id=TROWEL&qty=1&postcodeData=NG&selectedVariantCode=TROWEL1&basketView=1` and then went to the basket. The request was recorded rather than sent.
  - For real in the read-only preview, "Add to basket" is refused: the page said "Sorry, that couldn't be added…", gave the buttons back and stayed where it was.
- In headless Edge, the suggestions' buttons stay on one line at 390 and 320px, and the email breaks after the @ in the desktop panel.

Not tested: the real page after a real payment, with a real order's details, the purchase events, and the Track Order pop-up's answer. These need the test website, with test payments.
