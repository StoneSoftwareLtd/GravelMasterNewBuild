# Checkout

The Optima prototype's checkout (`checkout.html` in GravelMasterDesigns), rebuilt for the site's `/checkout/processorder` page. Built on 24 September 2026 and tested in the preview with a sample basket. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#checkout). It sends customers on to the same payment page as before; nothing about payment changes.

## Files

| File | What it is |
|---|---|
| `Views/Checkout/_CheckoutPage.cshtml` | the new page, as a partial that shows a `CheckoutPageModel` |
| `ViewModels/Common/CheckoutPageModels.cs` | `CheckoutPageModel` and its parts, and `CheckoutDates.Build`: the old page's delivery-date rules |
| `css/gm-checkout.css` | its styles, scoped to `.gm-checkout`, with the same shield against the old CSS as the other new pages |
| `js/gm-checkout.js` | the delivery charges and total, the checks before sending, the Isle of Wight dates, the billing address boxes |

Like the basket, the partial takes a small model of its own, so it could be built and previewed without the repository. `Checkout/ProcessOrder.cshtml` fills it from its `OrderViewModel` ([merging.md](merging.md#checkout)). It uses the site's existing payment cards picture and no new images.

## Which checkout is live

The repository has three versions of the checkout page: `master`'s, `stripe`'s and `new-checkout`'s. The live checkout can't be seen from here without putting something in a real basket. But its script (`/scripts/Controllers/Root/Checkout/ProcessOrder.js`) can be read, and it's newer than every branch's copy. It uses a variable, `thefirstone`, that only `master`'s view sets. So the new page is built from **`master`'s** `ProcessOrder.cshtml` and `CheckoutController`: the SMS tick box, "Is this a trade order?", the pre-order steps and the Royal Mail wording are all `master`'s. Check this against the live code once it's on a branch.

## What the old checkout does, and where each part went

Read from `Views/Checkout/ProcessOrder.cshtml`, the live `ProcessOrder.js`, `CheckoutController` (`ProcessOrder`, `CreateOrder`, `BuildDeliveryDays`), `OrderViewModel`, `AddressViewModel` and `Cart`.

| Old page | New page |
|---|---|
| Four steps on tabs: Address, Delivery date, Contact details, Payment | One page, as the prototype has it: contact details, delivery address, delivery date and time, additional information. The prototype's progress steps (Your details, Delivery, Payment) follow the part being filled in |
| Delivery address with the Postcode Anywhere finder (key `hm12-dh93-hc52-bz76`), which fills the boxes by their ids | The same finder and key, restyled as the prototype's "Find your address" box. The address boxes keep the old ids (`ContentPlaceHolder1_txtAddr1` and so on) and names (`Address.Address1` and so on) |
| "Is the billing address same as the delivery address?" Yes / No, with a second finder (`bg99-nd82-ge98-kr99`) and boxes for No | The prototype's "Use a different billing address" tick box. Ticked, it shows the same second finder and boxes and sends `addressCheck=0`, as No did. The boxes post as `DeliveryAddress.*`, as before (the old page's own naming: the server swaps them) |
| Delivery dates: a slider of dates from `BuildDeliveryDays`, filtered by the view (the first date skipped for PL, TA, TQ, TR, EX and KT postcodes, the first nine for GY, JE and IM, the first for rubber, 24 December to 3 January, turf's first two days and 24 April), the next-day charge on a bulk order's first weekday, the eco-friendly truck picture, and the first free weekday picked | The prototype's row of dates, from the same list with the same rules: they're now in `CheckoutDates.Build`, compared with the old view's loop (below). Free dates say "Free", charged ones their price; the eco-friendly dates get the prototype's "Eco" tag |
| "Weekday delivery" / "Saturday available (£50 delivery charge)" buttons that switch the Saturdays on | Saturdays sit in the row with their price, when the old page offered them (not for GY, IM, JE, KW, SL, ZE, HS, PA, PH, PO and IV postcodes, or with the Saturday setting off). Otherwise they're left out |
| "All Day 8am - 6pm" or "Morning 7am-12:30pm" (£15), when the delivery-time setting is on | The prototype's two time cards, with the same times and charge, shown under the same setting |
| The chosen charges added up by `updateUI()` into `deliveryExtraData` and the total | The same sum into the same field, shown in the summary's delivery lines, its total and a new "Total to pay" by the button |
| Isle of Wight postcodes lose the first seven dates | The same, with a note saying why. If the address finder fills in an Isle of Wight postcode without the page noticing, "Continue to payment" catches it, moves the date and says so before anything is sent |
| A pop-up when the postcode isn't in the area the basket was priced for | A message under the postcode, checked as the server checks it (the postcode's letters must be the area) |
| Samples and bird feeders: "Delivery by Royal Mail: 10-12 Days", no dates | The same, in its own Delivery panel and the summary |
| Only pre-order sizes: no date step; delivered from the pre-order date | The same, with the week it's due |
| A pre-order size with others: "Your Pre-Order will be delivered on or after its Pre-Order date" above the dates | The same, in the prototype's style |
| Products marked "simple": no date step; the first free weekday is sent | The same; the summary says which day |
| Special delivery instructions | The prototype's "Delivery instructions" box, with the old page's note that only the driver sees them |
| "I agree to the Terms and Conditions / Delivery Method" | The same, unticked (the prototype had it ticked) |
| "Subscribe to Newsletter" | Left out: it had no name, so it never sent anything |
| Name ("Payee Forename and Surname"), email, phone number, "SMS Messages" (ticked), "Is this a trade order?" | "Full name" (the site stores one name; the prototype had two boxes), email, contact number, "Send me text updates about my delivery" (ticked) and "This is a trade order", sending the same fields |
| Continue buttons between the steps, then Continue to the payment page | "Continue to payment", posting the same form to `/checkout/processorder`. The server then sends the customer to the payment page, as before |
| The `begin_checkout` Google Analytics event | Unchanged: it's in the view's `analyticscripts` section, outside the part being replaced |
| Basket Summary: name, size, pre-order date, quantity, line price, delivery, total | The prototype's order summary, with each product's photo, and "Edit basket" |

From the prototype, not on the old page: "Already have an account? Log in", the help panel (phone number and FAQs), the three promises, the payment cards, "Trade customer? Get trade prices" (not shown to trade accounts) and the bottom strip.

## Changed from the prototype

- **Colours**, measured against what's behind them. The prototype's green (`#388038`) is 4.4:1 on the summary card, so text and icons use the darker green of the other new pages; prices use the basket's price green. The boxes' edges (`#c9d1c0`, 1.6:1 on white) and the placeholders (`#8a9189`, 3.2:1) were too faint and are darker. "Continue to payment" keeps the brand orange with dark text, as on the other new pages. Every text colour on the page passes WCAG AA.
- **One name box**, since the site keeps one name per order.
- **The terms box starts unticked.** Agreeing has to be the customer's own act.
- **"A more sustainable choice"** is left out. It makes an environmental claim the live site doesn't make.
- **"Sustainable materials"** in the bottom strip is replaced by "Quality products", for the same reason.
- **Mistakes are explained under each box**, and "Continue to payment" says how many there are and goes to the first. It then shows "Taking you to payment…" and can't be pressed twice.
- **On phones**, the row of dates is swiped rather than using arrows, so three dates show instead of two. The order summary comes after the form there, so "Total to pay" sits by the button.

## Found in the old code

- **The delivery charge comes from the browser.** `CreateOrder` sets the order's delivery charge from the `deliveryExtraData` field, which the page's script fills in. Anyone who edits the page before sending can pay no delivery charge on a Saturday or a morning slot. The new page sends the charge exactly as the old one did. The fix is on the server: work the charge out from `selectedDelDay` and `selectedTime`. Raised in [open-questions.md](open-questions.md#checkout).
- The old Isle of Wight check looked for "po30" and so on anywhere in the postcode, so every Portsmouth PO3 postcode (PO3 5AA becomes po35aa) and PO4 0.. and PO4 1.. lost their first seven dates too. The new page reads the postcode's first half.
- The old script's Christmas Eve rules only apply to 24 December 2024, and the dates from 24 December to 3 January are never offered anyway. So they're not carried over.
- Logging in from the checkout always ends on My Account (`AccountController.SuccessLogin`), not back at the checkout.
- The Royal Mail wait is "10-12 Days" on the delivery step and "3-5 Days" on the contact step. The new page says 10–12 days.
- The old page checked the terms box only on the delivery step, which "simple" and pre-order-only baskets skip. The new page asks every customer.

## Tested

In the whole-website preview (`/checkout/processorder`), on 24 September 2026, with the sample basket: Cotswold Chippings 20mm (2 bulk bags), turf (10 rolls) and plastic pegs, at their live prices. The dates and prices are samples in the shape `BuildDeliveryDays` makes them (Saturdays £50, the next day £15, the morning £15), run through the real date rules. `?samples=1`, `?preorder=1`, `?mixed=1`, `?simple=1` and `?notimes=1` show the other kinds of delivery, and `?area=PO` a basket priced for PO postcodes.

- **The date rules:** the old view's date loop was copied as it is and run beside `CheckoutDates.Build` on 20,000 random cases. The cases covered every day of 2026 and 2027, 17 postcode areas, turf, rubber, bulk, weekends on and off, and random charges. Both gave the same dates, charges, weekend dates, eco dates and first choice every time. A change made on purpose showed up as a difference.
- **Compiling:** the partial compiles with MVC 5.2's Razor. So does the code `ProcessOrder.cshtml` will need ([merging.md](merging.md#checkout)), against stand-ins with the site's own class and property names.
- **Screenshots:** at 1440, 1024, 768 and 390px, and for samples, a mixed pre-order and a pre-order. The layout was measured at 11 widths from 1440 to 320px, with nothing wider than the screen.
- **Colours:** every text colour was measured against its background (all pass AA), and the edges of the boxes and dates (3.35:1 or more).
- **In the browser, with every "Continue to payment" stopped and what it would send recorded:**
  - An empty form shows seven messages, says "7 details need checking" and goes to Full name. Nothing is sent.
  - A bad email, a postcode outside the basket's area, and a part postcode each get their own message. Each message goes as soon as the box is put right.
  - A Saturday and the morning slot make `deliveryExtraData=65.00` and a total of £325.50. The summary says "Saturday delivery, Delivery on Saturday 26 September, £50.00" and "Morning (7am - 12:30pm), £15.00".
  - The form sent `Name`, `Email`, `Telephone`, `SmsOptIn=on`, `Address.*`, `DeliveryAddress.*`, `selectedDelDay=26-09-26`, `selectedTime=am`, `deliveryExtraData=65.00`, `DeliveryInstructions`, `TradeOrder=true,false` and `AgreeToTerms=true,false`, with the name's spaces trimmed. A second press sent nothing.
  - With a different billing address, its three required boxes are checked. The form then sent `addressCheck=0` and the billing address.
  - With no date chosen, it says "Please choose a delivery date."
  - Enter in a box doesn't send the form.
  - In headless Edge:
    - The progress steps move to Delivery when the dates get focus.
    - The arrow keys move along the dates, updating the summary.
    - PO30 5AA hides the first seven dates and moves the choice from 29 September to 5 October. PO3 0AA (Portsmouth) doesn't.
    - An Isle of Wight postcode put in without the page noticing is caught by "Continue to payment": a £15 date becomes a free one, and nothing is sent until the customer presses again.
- **Without its script:** the paid dates and the morning slot stay switched off, so they can't be sent without their charge. The browser's own checks stop an empty form.

Not tested:
- The real Postcode Anywhere finders. The preview doesn't load them, since typing would use the site's account. The preview shows a copy of the search box they draw, so the restyling can be seen.
- Sending a real order and reaching the payment page, which needs the test website.
- The real delivery dates and prices, which come from the site's settings.
