# Product page

The Optima prototype's product page (`product2.html` in GravelMasterDesigns), rebuilt to show the site's real products. Built on 23 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#product-page). The quantity calculator was added on 24 September 2026.

## Files

| File | What it is |
|---|---|
| `Views/Shared/_ProductPage.cshtml` | the new product page, as a partial that shows a `ProductPageModel` |
| `ViewModels/Common/ProductPageModels.cs` | `ProductPageModel` and its parts, `ProductDescription.Parse` and `Balance` |
| `css/gm-product.css` | its styles, scoped to `.gm-product`, with the same shield against the old CSS as the category page. Class names start `pdp-` so the old site's `.gallery`, `.promo` and `.step` can't reach them |
| `js/gm-product.js` | photos and zoom, postcode and prices, the buy form, the "added to your basket" pop-up, and "You might also like" |
| `img/gm-prod-*` | the prototype's four bag pictures and four delivery icons |
| `Views/Shared/_BulkEnquiryModal.cshtml`, `css/gm-enquiry.css`, `js/gm-enquiry.js` | the shared bulk delivery pop-up |
| `Views/Shared/_QuantityCalculator.cshtml`, `ViewModels/Common/QuantityCalculatorModel.cs`, `css/gm-calc.css`, `js/gm-calc.js` | the quantity calculator, shared with the homepage |

Like the category page, the partial takes a small model of its own, so it could be built and previewed without the repository. `Detail.cshtml` fills it from its `ProductViewModel` (see [merging.md](merging.md#product-page)).

## What the live product page does, and where each part went

Read from `Views/Product/Detail.cshtml`, `Scripts/Controllers/Root/Product/Detail.js`, `ProductController.Detail` and `BasketController.AddToBasket` in GravelMasterSoftware (master, 23 September 2026), and checked on eight live pages: Blue Slate 20mm, Cotswold Chippings 20mm, Ballast 20mm, Landscaping Bark, Black Rubber Chippings, Pro Hard Wearing Turf, Pebble Glue and a Begonia.

| Live page | New page |
|---|---|
| Breadcrumb: parent category, category, product | The prototype's breadcrumb, starting from Home |
| Photo with zoom (600px, zooming to 1000px), and a strip of thumbnails | The prototype's gallery: main photo, arrows, thumbnails (four across, scrolling sideways when there are more) and "Click to zoom", which opens the 1000px photo over the page |
| A video for eight products (Wistia, chosen by product code in the view) and a 360&deg; view (Spinzam) when the product has one | Extra thumbnails. Their players load only when chosen |
| `h1` and "From &pound;126.00 incl. VAT" (customer or trade price) | The title, and the price in the prototype's roundel on the photo |
| **Step 1**: a drop-down of postcode areas (AB, AL, B...), required except on "simple" products such as glue and bulbs | The prototype's Step 1: type a postcode. The area is taken from it (NG5 6AB is NG) and checked against the same 118 areas, so the price is exactly what the drop-down would give. Simple products skip it, as before |
| **Step 2**: a tile per size, priced for the area by `/product/calculateprices` | The prototype's size cards, priced by the same address. The four bag sizes get the prototype's bag pictures; other sizes keep the old page's pictures |
| Sample: an ordinary size, or on products with a half bag a separate "Add Sample (1Kg) - &pound;4.99" button | The prototype's "Try before you buy?" line, as a button that adds the sample (one of it) |
| Quantity: 1 up, or 10 up for turf | **Step 3**: the prototype's stepper, with the same limits. Every price updates for the quantity, as before |
| "Total: ... Includes delivery and VAT" | The prototype's total row, with a real Trustpilot widget beside it in place of the prototype's typed-in "4.8/5, 1,200+ reviews" |
| Add to cart, Pre-Order (for a pre-order size, with its date) or Out of stock | The same three states on the prototype's orange button, which becomes a bar fixed to the bottom of the screen on phones and tablets |
| Adding without an area opens a pop-up asking for one | Step 1 opens, says a postcode is needed, and takes the cursor |
| After adding: a pop-up with the basket's own summary (every line, + and -, the total and three "ADD" tiles), "Go to basket" and "Continue shopping"; the header's basket total updates | A pop-up in the new basket page's style. The lines, total and add-ons are read out of the same summary and shown as the new basket shows them, the line just added first; + and - and "Add" make the same requests as before (since 24 September 2026, see below) |
| "Next available delivery day: Thu 24 Sep" (only on products with a calculator) | The prototype's delivery notice: "Next available delivery: Thursday 24 September". The prototype's "Order in the next 2h 50m" countdown is a placeholder, as on the category page |
| Quantity calculator, by the product's type (gravel, bark, sand, soil or slate), on products that have one | The homepage's calculator (now the shared `_QuantityCalculator`), between the buy box and the product details, set to the product's type: gravel and slate use the gravel formula, bark the bark and mulch one, soil the topsoil one. The formulas are the same as the old page's. Products without one (glue, bulbs, turf) still have none |
| Description (HTML from the database) | Split into the prototype's panels (see below): Product Specification, Product Use, then the description's own sections such as "Colour and Shape" and "Availability" |
| "Related Products": the FeatherSnap Bird Feeder, then three random products from the same category | "You might also like", with the same products, but never the product itself or the same product twice (the old page showed the bird feeder twice on Accessories) |
| Trustpilot carousel | The homepage's reviews band, with the same real Trustpilot widgets |
| "Loose load orders" band and the loose load enquiry pop-up | The prototype's "Ordering 10 tonnes or more?" banners, opening the shared bulk enquiry pop-up |
| Schema.org product details (name, code, price, availability) | Kept, with the main photo added |
| Google Analytics `view_item` (on opening, and on choosing a size), `add_to_cart` and `no_postcode_selected` | Sent by `gm-product.js` with the same names and fields |
| Page title, description, canonical link and Open Graph tags | Unchanged: they're in `@section Head`, outside the part being replaced |

### How the description is split

Almost every live description follows the same pattern, which is the prototype's layout: intro paragraphs, a heading over lines like "**Colour:** Blue", then headings such as "Colour and Shape", "Availability" and "Loose Load Deliveries". `ProductDescription.Parse`:

- takes the paragraphs before the first heading as the intro (or the text under a "Description" heading, which some use instead);
- turns the first section made only of "Label: value" lines into the specification table, and its "Uses" line into the Product Use list, with the category page's icons or a tick;
- keeps every other section as its own panel, closed at first, with its heading as written.

A section with anything besides those lines is shown as written rather than as a half-filled table (Landscaping Bark's has plain lines and a value hidden in an HTML comment). Cutting at headings can split an element, so `Balance` makes each piece whole: a stray `</div>` in one would otherwise close the page's own layout. All 153 live descriptions were checked.

### In the prototype, but the site has no data for it

Left out until there's something real to show. See [open-questions.md](open-questions.md#product-page).

- The star rating and "(124 reviews)" under the title: product reviews are switched off in the controller.
- The "A popular choice" badge and the three selling points under the photos: written for Blue Slate, with nothing per product behind them.
- "Add to your order": the live page doesn't offer add-ons, although the controller works out a list of them.

### On the live page, but left out

- **"N purchases during last 24 hours"**, shown on six products. The number is random (`random.Next(10, 30)`), so it isn't true.

## Choices

- **Postcode, not area.** The prototype asks for a postcode, and the site prices by area, so the page works out the area. A full postcode is remembered on the device (the prototype's `gm-postcode`); the area chosen earlier in the same visit, which the server already remembers, comes first. Postcodes the old drop-down didn't offer (Northern Ireland, Shetland, the Outer Hebrides...) get "Sorry, we can't take orders for ... online. Please call us".
- **Prices appear once there's a postcode**, as on the old page. Before that the size cards show no price and the total says "Enter your postcode". The "From" price is in the roundel.
- **The basket pop-up's inside is restyled in the page, not on the server.** The basket answers Add to cart with its own summary (`AddToCartComponent.cshtml`, or `AddToCartComponentGravel.cshtml` for gravel), which every page's pop-up uses. Rather than change those, `gm-product.js` reads the lines (name, link, photo, size, quantity, line price, pre-order date), the total and the add-ons out of the summary and shows them in the new basket page's style:
  - the line just added comes first, marked "Just added" when there are others;
  - + and - call `/basket/updatequantity` as the summary's own buttons did (turf has none, as before), - stops at 1, and a change that fails goes back and says so;
  - the add-ons (listed twice in the summary, for desktop and phone) show once, below "Go to basket" and "Continue shopping" so those stay in view; "Add" calls `/basket/addtobasket` with the same codes as the summary's "ADD", then shows the new summary with that add-on marked "Added";
  - the summary's own scripts and styles aren't used;
  - if the summary ever doesn't look as expected (no lines or no total), it's shown as it comes, with its own scripts, as before.
  The add-ons show their customer price to everyone, as the summary itself does (its trade price is hidden).
- **"You might also like" cards say "Shop now"**, not the prototype's "Add to basket": adding needs a size and a postcode.
- **The delivery panel** is the prototype's text, with "palette" corrected to "pallet" and a link to the full delivery page. Two lines can't be checked from the site; see [open-questions.md](open-questions.md#product-page).
- **Colour contrast.** Every colour passes WCAG AA, measured in the preview against the colour behind it. As on the other pages, the text on the orange (Step badges, Add to cart) is near-black instead of white, and the greens used for text are darker.
- **No JavaScript**: the panels are `<details>`, the zoom is a link to the big photo, and the form still posts to the basket (the basket takes the area from what's typed).

## Accessibility

- Sizes are a real radio group (arrow keys choose), drawn as the prototype's cards, with a focus outline on the card.
- The postcode box has a label, its errors are announced and marked on the box, and confirming it moves the keyboard to "Change delivery address" instead of losing it.
- The total is announced when it changes.
- The basket pop-up and the zoomed photo take focus, keep Tab inside, close with Escape, and return focus to where it was.
- The breadcrumb is an ordered list with the current page marked; each thumbnail says which photo it is and whether it's showing.

## Tested

- `ProductPageModels.cs` compiled with the .NET Framework 4 compiler, warnings as errors. **`_ProductPage.cshtml` compiled with the site's own Razor (MVC 5.2) and the .NET 4 compiler**, which caught two mistakes (`section` is a Razor keyword; an email address with `@@`).
- `Parse` and `Balance` on the eight descriptions, edge cases, and all 153 live products; `GetPostcodeArea` on full, partial, lower-case and invalid postcodes and on BT, ZE and HS.
- In the whole-website preview, Blue Slate 20mm measured against `product2.html` at 1440px: columns, photo, roundel, title, delivery bar, size cards, notice, total, Add to cart, banners, panels and cards match; the differences are the parts left out. Also at 1100, 861, 860, 768, 560 and 375px: no sideways scrolling, one column from 860px, the fixed Add to cart bar under the menu and pop-ups and never covering the footer.
- Postcodes (Nottingham and Birmingham get their own prices), quantity (prices from the server for 3 bags), sizes, sample, photos, video and 360 thumbnails, zoom, keyboard order, colour contrast, no script errors.
- Add to cart sends `postcodeData=NG&selectedVariantItem=435943&qty=1` to `/basket/addtobasket?id=20blsl` as an AJAX request, as the old form did, and the three analytics events carry the old fields. The preview blocks the real post, so the pop-up was tested with a stand-in reply built like `AddToCartComponent.cshtml`: its script ran, + updated the line and total through `/basket/updatequantity`, and the header's basket total updated.
- Eight kinds of product by hand (bags with a half bag, video and 360; glue and bulbs without a postcode; turf from 10; bark; rubber chippings; ballast), and all 153 live products converted and rendered. The 13 out of stock show "Out of stock".

- The restyled basket pop-up (24 September 2026), in headless Edge on Cotswold Chippings 20mm with the reply made exactly as `AddToCartComponent.cshtml` builds it (three lines: the product, pegs on pre-order, turf; the three add-ons, twice) and every request recorded rather than sent: Add to cart sent the same post as before; the line just added came first; the pre-order date showed; turf had no + and -; + sent `/basket/updatequantity?code=20COTSHALF-BBG&quantity=2` and updated the line and total from the reply; - at 1 sent nothing; a failed change went back with a message; "Add" on the 1m membrane sent `/basket/addtobasket?id=WM1M&qty=1&selectedVariantCode=WM1M-15` and showed the new summary with it first and its button "Added"; the header total refreshed; Escape closed it and returned focus to Add to cart; an unexpected reply was shown as it came. Every text colour passes AA. Screenshots at 1440 and 390px.
- The calculator (24 September 2026): each of the eight products gets the calculator its live page shows (gravel for Ballast, Blue Slate and Cotswold; topsoil for Landscaping Bark, whose live page has the "Soil Calculator"; bark and mulch for rubber chippings; none for glue, bulbs and turf); it opens with results for the example size, sends the same estimate email fields as the homepage's, and nothing scrolls sideways at 375px. Its formulas and layout are the homepage's, checked before and after sharing it.

**Not tested yet**: really adding to the basket, the real basket reply, and a trade login (the preview never sends posts or logs in); and the page inside the real site. These need a test environment ([merging.md](merging.md#product-page)).
