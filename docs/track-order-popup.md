# Track Order pop-up

The pop-up that opens from "Track Order" in the header and the phone menu, and from "Track your order" on the delivery, FAQ, contact and order confirmation pages and each order in My Account. Built 28 September 2026. There's no Optima prototype for it; its look is the Track Order modal in the July 2026 prototypes (`GravelMasterDesigns/archive/2026-07-prototypes/track-order-component.html`), in the new pages' colours.

## Files

| File | What it is |
|---|---|
| `Views/Shared/_TrackOrderPopup.cshtml` | the pop-up, rendered once on every page by `_Layout` with the new header and footer |
| `css/gm-chrome.css` | its styles, at the end (`.gm-track`) |
| `js/gm-chrome.js` | opening and closing it, and looking the order up |

With the new header and footer off, the old pop-up (`_TrackOrderModal`) is still there, unchanged.

## How it works

- Any element with `data-track-open` opens it. With `data-order` and `data-postcode` as well (the order confirmation and My Account), it fills both boxes in and looks the order up straight away.
- "Find my order" sends the old pop-up's two fields (`orderId`, `postcode`) to the same address, `/checkout/checkmyorder?id=track` (`CheckoutController.CheckMyOrder`, unchanged). The lookup answers with a sentence; the pop-up shows it.
- The lookup has four sentences for an order that's been found, one per stage (from Palletforce's tracking). Each step in the pop-up names a few words of its sentence (`data-says`), so those answers also light up the steps: Being prepared, At your local depot, Out for delivery, Delivered. If the sentences in `CheckMyOrder` are ever reworded, change `data-says` to match; until then the sentence still shows, just without the steps.
- Any other answer (no such order, a different postcode, the lookup not working) is shown on its own, in yellow. So is a failed request, with the phone number.
- Only the answer's words and bold are kept. One answer repeats the postcode as it was typed, so this stops anything typed there being read as part of the page.
- "#123456" and "123 456" are tidied to 123456 before sending. Letters are stopped with a message ("Order numbers are only numbers, like 123456."), because the lookup would otherwise say the tracking system isn't working.
- It doesn't need Bootstrap or jQuery (the old one needed both), so it works as soon as the page has loaded.
- Keyboard: it opens with the cursor in the first empty box; Tab stays inside it; Escape, the cross and the dark background close it, and the cursor goes back to what opened it (the menu button, when it was opened from the phone menu). The answer is read out to screen readers, and each step says whether it's done, now or to come.

## Where the old pop-up's parts went

| Old | New |
|---|---|
| "Check Order status", in a black box | "Track your order", with a lorry, in a green bar |
| "Order ID:" and "Delivery or Billing Postcode:" (the labels weren't linked to their boxes) | "Order number" (with "It's in your order confirmation email.") and "Delivery or billing postcode", linked, sized for phones |
| "STATUS:" with the answer under it, shown even before searching | The steps and the answer, shown after searching |
| Nothing | "Questions about a delivery? Call 0330 058 5068, option 2, Monday to Friday, 8am - 5pm." |

## In the preview

The preview never asks the live lookup, as it reads real customers' orders. It answers for sample orders instead, with the lookup's own sentences (`preview/tools/track-order.ps1`), and says so in the pop-up: postcode NG7 2RD with 123456 (being prepared; the sample confirmation's and My Account's order), 123457 (at the depot), 123458 (out for delivery) or 118870 (delivered; My Account's older order). Any other number or postcode gets the lookup's other answers.

## Tested (28 September 2026)

- The pop-up compiles as the site would build it, and so do the six pages whose buttons changed; the header, phone menu and `_Layout` parse. The preview's pop-up is the same markup as the compiled one.
- In headless Edge, from the header on the contact page: each sample order lit the right steps and showed its sentence, with its bold; "#123 456" became 123456; an unknown order and a wrong postcode showed the yellow answer without steps; a postcode with HTML in it came back as plain words (no picture, no script); letters and an empty box were stopped before sending; Tab stayed inside; Escape and the dark background closed it and gave focus back.
- From My Account's two orders and the order confirmation: each looked its order up straight away.
- At 390 and 320px, opened from the phone menu: the menu closed, the steps go down the pop-up, nothing runs off the screen, and closing it gave focus back to the menu button.
- Colours: text 5.5:1 or more.
- No script errors.

Not tested: the real lookup (it needs the test site, with real orders in each state).
