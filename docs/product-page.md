# Product page

The Optima prototype's product page (`product2.html` in GravelMasterDesigns), rebuilt to show the site's real products. **Being built**, started 23 September 2026. Not on the site yet (see [merging.md](merging.md#product-page)).

## What the live product page does, and where each part goes

Read from `Views/Product/Detail.cshtml`, `Scripts/Controllers/Root/Product/Detail.js`, `ProductController.Detail` and `BasketController.AddToBasket` in GravelMasterSoftware (master, 23 September 2026), and checked on eight live pages: Blue Slate 20mm, Cotswold Chippings 20mm, Ballast 20mm, Landscaping Bark, Black Rubber Chippings, Pro Hard Wearing Turf, Pebble Glue and a Begonia.

| Live page | New page |
|---|---|
| Breadcrumb: parent category, category, product | The prototype's breadcrumb, starting from Home |
| Photo with zoom (600px, zooming to 1000px), and a strip of thumbnails | The prototype's gallery: main photo, arrows, thumbnails and "Click to zoom", which opens the 1000px photo |
| A video for eight products (Wistia, chosen by product code in the view) and a 360&deg; view (Spinzam) when the product has one | Extra thumbnails. Their players load only when chosen, so the page doesn't load them up front |
| `h1` and "From &pound;126.00 incl. VAT" (customer or trade price) | The title, and the price in the prototype's roundel on the photo |
| **Step 1**: a drop-down of postcode areas (AB, AL, B...), required except on "simple" products such as glue and bulbs | The prototype's Step 1: type a postcode. The area is taken from it (NG5 6AB is NG) and checked against the same list of areas, so the price is exactly what the drop-down would give |
| **Step 2**: a tile per bag size, priced for the area by `/product/calculateprices` | The prototype's bag size options, with the same prices from the same address |
| Sample: an ordinary option, or on products with a half bag a separate "Try Before You Buy? Add Sample (1Kg) - &pound;4.99" button | The prototype's "Try before you buy?" line, as a button that adds the sample (the live button does the same) |
| Quantity: 1 up, or 10 up for turf | **Step 3**: the prototype's stepper, with the same limits |
| "Total: ... Includes delivery and VAT" | The prototype's total row |
| Add to cart, Pre-Order (for a pre-order size, with its date) or Out of stock | The same three states on the prototype's orange button |
| Adding without an area opens a pop-up asking for one | Step 1 opens, says a postcode is needed, and takes the cursor |
| After adding: a pop-up with the basket summary from the server, "Go to basket" and "Continue shopping"; the header's basket count updates | The same, in a dialog in the new style |
| "Next available delivery day: Thu 24 Sep" (only on products with a calculator) | The prototype's delivery notice, with that date. The prototype's "Order in the next 2h 50m" countdown is a placeholder, as on the category page |
| Quantity calculator, by the product's type (gravel, bark, sand, soil or slate) | The prototype's calculator section. To do as its own step: it means sharing the homepage calculator |
| Description (HTML from the database), with the 360&deg; view floated in it | The "Product Specification" panel: the description, then the product's features (Colour, Size and so on) as the prototype's table |
| "Related Products": the FeatherSnap Bird Feeder, then three random products from the same category | "You might also like", with the same products |
| Trustpilot carousel | The prototype's reviews band, with the real Trustpilot widgets (as the homepage) |
| "Loose load orders" band and the loose load enquiry pop-up | The prototype's "Ordering 10 tonnes or more?" banners, opening the shared bulk enquiry pop-up |
| Schema.org product details (name, code, price, availability) | Kept |
| Page title, description, canonical link, Open Graph tags, and Google's `view_item` event | Unchanged: they are outside the part being replaced |

### In the prototype, but the site has no data for it

These are left out until there's something real to show. See [open-questions.md](open-questions.md#product-page).

- The star rating and "(124 reviews)" under the title: product reviews are switched off in the controller.
- The "A popular choice" badge and the three selling points under the photos ("Stylish blue-grey finish" and so on): written for Blue Slate, with nothing per product behind them.
- The "Product Use" icons, and the empty "Colour & Shape" and "Availability" headings.
- "Add to your order": the live page doesn't offer add-ons, although the controller works out a list of them.

### On the live page, but left out

- **"N purchases during last 24 hours"**, shown on six products. The number is random (`random.Next(10, 30)`), so it isn't true. See [open-questions.md](open-questions.md#product-page).
