# Basket page

The Optima prototype's basket (`basket.html` in GravelMasterDesigns), rebuilt for the site's `/basket` page. Built on 24 September 2026 and tested in the preview with a sample basket. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#basket-page). Checkout comes after it.

## Files

| File | What it is |
|---|---|
| `Views/Basket/_BasketPage.cshtml` | the new page, as a partial that shows a `BasketPageModel` |
| `ViewModels/Common/BasketPageModels.cs` | `BasketPageModel`, `BasketLine` and `BasketSuggestion` |
| `css/gm-basket.css` | its styles, scoped to `.gm-basket`, with the same shield against the old CSS as the other new pages |
| `js/gm-basket.js` | quantities, Remove, Empty basket, the add-ons, the voucher box and the checkout event |

Like the product page, the partial takes a small model of its own, so it could be built and previewed without the repository. `Basket/Index.cshtml` fills it from the cart ([merging.md](merging.md#basket-page)). It uses the site's existing payment cards picture (`img/gm-payment-cards.png`) and no new images.

## What the old basket page does, and where each part went

Read from `Views/Basket/Index.cshtml`, `Scripts/Controllers/Root/Basket/Index.js`, `BasketController` (`Index`, `UpdateBasket`, `RemoveFromBasket`, `ApplyCouponCode`, `AddToBasket`) and `Cart` in GravelMasterSoftware (master, 24 September 2026), and the live page's script. The live basket can't be seen with items from here (the preview sends no cookies), so the live page was checked empty.

| Old page | New page |
|---|---|
| A row per line: photo (330px), name (linked), size, price each, discount, line total | The prototype's line cards: photo, name (linked), price each, size, line total, and the voucher saving under it when there is one |
| Pre-order sizes: "Pre-Order For Delivery W/C: 6 Oct", and that the date is an estimate | The same, on the prototype's pre-order line with its purple dot |
| + and - buttons and a number box; each click posts the whole basket form to `/basket/updatebasket` with one `item.Quantity` per line, in the cart's order, and the page reloads | The prototype's joined + / number / - pill, posting the same form. Quick clicks are gathered into one post (it waits 0.7 seconds after the last). - stops at 1, as before; Remove takes a line out |
| Turf (codes starting TT2 or TT3) has no + and -: its quantity is chosen on its product page | The same: "Quantity: 10" instead of the pill. The new page also sends the turf's quantity in a hidden field (see below) |
| Remove posts the line's id to `/basket/removefrombasket` | The same, then the page reloads with the new totals |
| Not on the old page | The prototype's "Empty basket": asks first, then removes each line the same way |
| Voucher box (when the "data-coupon-display" setting is on): posts `couponcode` to `/basket/applycouponcode`, which comes back with a message | The prototype's "Add voucher code", posting the same. After an attempt it opens with the message. A discount shows as its own row under the sub-total |
| "Total ... includes delivery and VAT" | The prototype's total card: sub-total (before any voucher), the discount if any, and "Total Cost (inc. VAT & delivery)" |
| Checkout (twice), to `/checkout/processorder`, sending Facebook's InitiateCheckout | The prototype's "Checkout Securely", to the same address, sending the same event |
| "Back to Shopping" | "Continue shopping", to the homepage as before |
| "Check out our weekly special offers": four add-ons (Empty Waste Bag, 1m x 15m and 2m x 10m weed membrane, 10 plastic pegs), each added by `/basket/addtobasket?...&basketView=1` with the basket's postcode area | The prototype's "You might also like" cards, with the same four products, names and sizes, added the same way |
| The `view_cart` Google Analytics event | Unchanged: it's in the view's `analyticscripts` section, outside the part being replaced |
| "Oops, your basket appears to be empty!" | "Your basket is empty." with Continue shopping |
| Payment methods picture and a Trustpilot carousel at the bottom | The payment cards under the checkout button, as the prototype has them. The carousel isn't in the prototype and is left out |

Not on the old page, from the prototype: the handwritten "Quality garden products, delivered to your door", the "Next day delivery available" panel, and the strip of four promises at the bottom.

## Changed from the prototype

- **Colours**, measured against what's behind them. The prototype's price green (`#2ea549`) is 3.2:1 on white and 2.9:1 on the total card, so prices use a darker green (`#1f7a35`, 5.4:1 and 4.9:1). "Checkout Securely" keeps the brand orange with dark text, as on the other new pages (white on it is 2.3:1). The Apply button's green was 3.2:1 with white text and uses the dark green. The voucher box's edge was 1.5:1 against the card and is now 3.6:1. Every text colour on the page passes WCAG AA.
- **"In stock"** isn't shown on each line. The basket doesn't know a product's stock, and the old page never said it. Pre-order lines still say so.
- **The add-ons** stay four across down to 700px wide, then two. At the prototype's two across from 1100px, each card was about twice the size of its photo.
- **A photo that doesn't load** leaves the card's pale box rather than a broken-image icon. The Empty Waste Bags product has no photos at all on the image server, so its add-on card uses the old basket's own picture (`/img/800.png`).
- **Without JavaScript**, an "Update basket" button sends typed quantities. The script hides it.

## Found in the old code

The old view only gives + and - to lines that aren't turf, and the controller only changes quantities when the number posted matches the number of lines. So in a basket with turf and anything else, the other lines' + and - do nothing: the post has one quantity too few. The new page sends the turf's quantity too, in a hidden field, so the count always matches. This is in the repository's code; the live page couldn't be checked with items in it.

## Tested

In the whole-website preview (`/basket`), on 24 September 2026, with a sample basket: Cotswold Chippings 20mm (2 bulk bags), turf (10 rolls) and plastic pegs, at their live prices. `?empty=1` shows the empty basket, and `?voucher=1&discount=1` a voucher message and a 10% discount.

- The partial compiles with MVC 5.2's own Razor against the page models.
- Screenshots at 1440, 1024, 768 and 390px, empty and with a voucher; the layout measured at 11 widths from 1440 to 320px, with nothing wider than the screen.
- Every text colour measured against its background (all pass AA), and the voucher box's edge.
- In headless Edge, with the requests recorded rather than sent:
  - + twice and - once, quickly, posted once: `item.Quantity=3&item.Quantity=10&item.Quantity=1` to `/basket/updatebasket`, with the turf's 10 in its place;
  - - at 1 posted nothing;
  - Remove posted that line's id to `/basket/removefrombasket` and disabled the page while it went;
  - Empty basket posted each line's id, in order;
  - an add-on called `/basket/addtobasket?id=WM1M&qty=1&postcodeData=NG&selectedVariantCode=WM1M-15&basketView=1`;
  - the voucher box opened, put the cursor in the box, and posts `couponcode` to `/basket/applycouponcode`;
  - a photo made to fail left a plain box.
- For real in the read-only preview: Remove is refused, and the page says "Sorry, that couldn't be done..." and gives the buttons back.

Not tested: anything that changes a real basket (updating, removing, vouchers, add-ons, checkout), which needs the test website. The header's basket total in the preview stays at £0.00, since the sample basket isn't the live site's.
