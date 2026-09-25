# Progress log

Every step, oldest first. Add a new entry for each step. The commit history has the detail of each change.

## Before 17 September 2026: the new-chrome branch

The GravelMasterSoftware branch **new-chrome** (8 commits) ported the Optima prototype's header, footer and mobile menu into the site behind a `UseNewChrome` setting. Its changed files and a patch were supplied as a zip on 16 September 2026.

Commit: *Add the new-chrome header and footer package as received*.

## 17 September 2026: header and footer reviewed and fixed

Reviewed the package against the live site and fixed five problems, one commit each:

1. Enter in the search box didn't search.
2. `gm-chrome.css` changed Bootstrap's colour variables for the whole page.
3. The closed mobile menu could still be reached with Tab, and focus wasn't managed.
4. The payment cards image was five times too big, and header and footer images had no dimensions.
5. The mega menu read the whole product list 12 times per page.

Each was tested in a static preview at seven widths from 1440px to 375px. Details: [header-and-footer.md](header-and-footer.md#fixes-made-on-17-september-2026).

Also found: the live site's `_Layout.cshtml` is newer than the branch's master, so the branch has to be redone on the latest master before merging. See [merging.md](merging.md).

## 17 September 2026: previews

- **Saved pages for VS Code Live Server**: `preview/tools/build.ps1` builds pages from the `.cshtml` files with the live site's menus, products and stylesheets.
- **Whole-website preview** on http://localhost:8780: live pages with the new header and footer swapped in, read-only, so it's possible to click around the real site. Clicking around found that the "page not found" page has its own copy of the old header ([merging.md](merging.md)).
- **`Start website preview.cmd`** to start it with a double-click.

Details: [preview/README.md](../preview/README.md).

## 17 September 2026: homepage

Rebuilt the prototype's homepage as `_HomePage.cshtml` with real data: admin banners, prices from the product data, the live calculator formulas and enquiry posts, and the real Trustpilot widgets. Tested in the preview at nine widths. Details: [homepage.md](homepage.md).

Raised for a decision: the sand calculator formula, trade prices above retail, 1MB banners, prototype colour contrast and a small gallery photo. See [open-questions.md](open-questions.md).

## 22 September 2026: this repository

- Put the work into this repository, with the history rebuilt as one commit per step from the original zip and the finished files.
- Fixed the preview scripts' text encoding (the saved pages showed "previewâ€¦").
- The "rebuild and watch" task now also rebuilds when the homepage partial changes.
- Wrote these documents.

## 22 September 2026: category page

Rebuilt the prototype's category page as `_CategoryPage.cshtml`, for every category, subcategory and filtered page. Details: [category-page.md](category-page.md).

1. Mapped what the live category pages do (six pages checked) and how each part fits the prototype.
2. Moved the homepage's bulk enquiry pop-up into a shared partial so the category page can use it, and made Tab stay inside it while it's open.
3. Added `CategoryPageModel` and `CategoryDescription.Parse`, which splits a category description into its "Ideal for" uses, intro and "Read more" part. Tested on six live descriptions.
4. Built the page: the live filters (as links, shown as the prototype's checkboxes), Sort by, every product with customer and trade prices, the description with Read more, the promo card, trade card, PayPal message and the bulk banner.
5. The previews now show it on every live category page, and let Sort by through to the live site (the only form they pass on).

Found and fixed along the way:

- the old base CSS hides every `<nav>` below 900px wide, which would have hidden the breadcrumb;
- the promo card broke the order of sorted pages, so it now shows in the default order only;
- PayPal hid its message in the 280px sidebar, so it now uses the style that fits.

Raised for a decision: "Ideal for" icons, which product each promo card shows, the old left-column images, a real delivery countdown, Klarna, and some of the prototype's colours. See [open-questions.md](open-questions.md).

## 23 September 2026: page weight and colour contrast

Answering open questions: the prices and the quantity calculator stay exactly as they are.

- **Page weight.** The header logo was 600x200 (78 KB) for a 192x64 space, and is now 384x128 (37 KB). The widest gallery photo is capped at 860px (181 KB to 148 KB) and the advisor photo re-encoded (29 KB to 23 KB). The other gallery photos were left alone: re-encoding them saved less than 15%, which is not worth the quality loss. The gallery photos now carry their sizes so the page does not jump as they load, images decode off the main thread, and the homepage script is deferred.
- **The admin site's banners are the homepage's real weight**: six PNGs, 5.6 MB in total. Optimised JPEGs of the same 1400x467 size, 911 KB in total, are ready to upload; see [open-questions.md](open-questions.md).
- **Colour contrast.** Ten text and icon colours on the homepage and category page, and five in the header, footer and mobile menu, were below WCAG AA. All now pass, measured against the colour behind them. On orange the text is near-black rather than white, which keeps the brand colour and reads better than a darker orange would. The worst was the mobile menu's yellow category name at 1.9:1.
- Left for a decision: white on the header's main green is 3.04:1, and changing it means changing the site's dominant colour.

## 23 September 2026: product page

Rebuilt the prototype's product page (`product2.html`) as `_ProductPage.cshtml`, for every product. The GravelMasterSoftware repository is on this PC now, so the page was mapped from the real code as well as the live pages. Details: [product-page.md](product-page.md). The quantity calculator section is still to do.

1. Mapped what the live product page does, from `Detail.cshtml`, its script, the product controller and the basket's add-to-basket action, checked on eight live pages, and where each part goes in the prototype.
2. Added `ProductPageModel` and `ProductDescription.Parse`. The live descriptions follow the prototype's layout already (intro, a list of "Label: value" lines, then "Colour and Shape" and "Availability"), so Parse splits them into the intro, the specification table, the uses and the other sections. A section that has anything besides those lines is shown as written. Tested on the eight live descriptions and edge cases; `GetPostcodeArea` tested on full, partial and invalid postcodes and areas the site doesn't deliver to.
3. Made each piece of a split description whole. Cutting at the headings split Blue Slate's `<div><h3>Loose Load Deliveries</h3>...</div>`, and the stray `</div>` closed the page's own layout, so the reviews and everything after them fell outside it. `ProductDescription.Balance` drops closing tags with nothing to close and closes what's left open. Also added what the page turned out to need: the basket address, the category name, and each size's code and base price (for the analytics events).
4. Built the page (`_ProductPage.cshtml`, `gm-product.css`, `gm-product.js`, `img/gm-prod-*`): photos with the video and 360&deg; view as extra thumbnails, the three steps (postcode, size, quantity) priced by the live site's own price lookup, the sample, the delivery date, Add to cart posting exactly what the old form posted, the basket pop-up, the description panels, the delivery panel, Trustpilot, and "You might also like". It sends the old page's three Google Analytics events with the same fields. The view was compiled with MVC 5.2's own Razor, which caught two mistakes before they could reach the site.
5. The whole-website preview now shows the new page on every product page, with real prices from the live site's price lookup. `preview/tools/product-page.ps1` reads an old product page and fills in the partial; it runs the real C# model rather than a copy, so the preview can't drift from the site. Ran it over all 153 live products.

6. Wrote up the page, the merge steps and the questions.
7. Recording a walkthrough for Mollie showed blank thumbnails on some products: the 300px photo files only exist for some products, while every photo has a 330px one. Thumbnails now use 330px (preview and merging.md). The preview's check for Razor left in a page now also catches C# statements without an `@`, which it missed once while the preview was running an older script.

Found and fixed along the way:

- the stray `</div>` from splitting descriptions (step 3);
- out-of-stock products with no sizes said "can't be ordered online"; they now say "Out of stock", as the old page does;
- "You might also like" showed the bird feeder twice on Accessories, and a product among its own suggestions;
- keyboard focus was lost after confirming a postcode.

Found on the live site: seven slate descriptions have a phone link that dials a different number from the one shown, and the controller deletes dashes from descriptions ("30-50cm" shows as "3050cm").

Raised for a decision: the random "purchases during last 24 hours" pop-up, the rating, badge and selling points the site has no data for, add-ons, use icons, the delivery panel's wording, the basket pop-up's old styling, the two live content problems, and Blue Slate's photos. See [open-questions.md](open-questions.md#product-page).

## 24 September 2026: getting ready to integrate

Decided to put the three finished pages into the site before building more. Checking the GravelMasterSoftware repository first found:

- this PC can't build or run the site (no Visual Studio, MSBuild, IIS or SQL Server), so the integration can be written and compile-checked here, but tested only on a test website;
- no branch matches the live site: the layout is `stripe`'s, the product page is partly `master`'s. The deployed code needs pushing before the integration starts ([merging.md](merging.md#before-anything-which-code-is-live));
- the test website will use a copy of the live database; where it runs is still to decide.

## 24 September 2026: product page calculator

1. Fixed the preview homepage, which had had no script since 23 September: the homepage's script tag gained `defer`, and the preview's build only looked for the tag without it, so it silently left the script out (no carousels, tabs or calculator). It now accepts attributes and stops with an error if the script is missing. The site's own partial was never affected.
2. Moved the homepage's quantity calculator into a shared partial (`_QuantityCalculator.cshtml`, with `QuantityCalculatorModel`, `gm-calc.css` and `gm-calc.js`), unchanged, so the product page can use it too. The homepage was measured before and after: the same results for 24 calculations (every type and unit), and the calculator's 53 elements in exactly the same place, size and colour at 1440, 860 and 375px.
3. Added the calculator to the product page, between the buy box and the product details, on the products whose live page has one, set to the product's type (`QuantityCalculatorModel.ForProduct`: gravel and slate use the gravel formula, bark the bark and mulch one, soil the topsoil one). Checked on eight products against the calculator their live pages show.
4. On phones the calculator's "Or" was left at the end of the first result's line: the site's real labels ("Pre Packed Pallets (56 x 25L)") are too long for both results to share a line, unlike the prototype's short ones. Below 560px "Or" now has its own line, so the results stack. Checked: unchanged at 1440 and 860px.

## 24 September 2026: About us page

While the live code is being put on a branch, carried on with the prototype's pages that don't depend on it. Rebuilt the prototype's About page (`about.html`) as `Views/Content/_AboutPage.cshtml` for `/about-us`. Details: [about-page.md](about-page.md).

- The live page is text written into its view, with nothing from the database, so the new page is a partial with no model. The live page's paragraphs replace the prototype's placeholder text, word for word.
- The hero and team photos went from 2.1 MB to 208 KB at the same sizes; the inspiration photos are the homepage's.
- White text on the blue band was 2.8:1 and the "Since 2008" badge let the photo show through, so both were darkened just enough to pass AA. Every text colour on the page was measured.
- Fixed two CSS mistakes carried over from the prototype: on phones the trust row sat above the photo instead of below it, and the "About Gravelmaster" label showed as grey body text.
- The team arrows show only when the cards scroll (phones), and follow resizing.
- The preview shows it at `/about-us`. Checked at 1440, 1024, 768 and 390px, and the team arrows clicked through in headless Edge. The partial compiles with MVC 5.2's Razor.

Raised for a decision: the out-of-date "31-years", the hero photo (looks like stock, and small), Harvey Finlayson (not on the live team page), the live content left out, and the blue. See [open-questions.md](open-questions.md#about-us-page).

## 24 September 2026: Trade Accounts page

Rebuilt the prototype's trade page (`trade.html`) as `Views/Content/_TradePage.cshtml` for `/trade`. Details: [trade-page.md](trade-page.md).

- The prototype's perks, "Why Choose Gravel Master?" and FAQ answers were placeholder text. They're now written only from what the live trade page, the live trade sign-up form and the site's code say, each listed in the page's doc, and raised for the business to read.
- "Open a trade account" and "Get trade prices" open the trade sign-up form, as the old page's button did.
- The "Why Choose" greens (3.0 to 3.7:1 with white) and the "Trade Accounts" label (3.9:1) were darkened just enough to pass AA. Every text colour on the page was measured.
- The hero title now scales with the window: at the prototype's fixed sizes "on." fell onto a line of its own from 861 to about 1070px wide. Measured at 13 widths.
- The FAQs are `<details>`, so they need no script; opening and closing with the mouse and the keyboard was checked in headless Edge.
- The preview shows it at `/trade`. Checked at 1440, 1024, 768 and 390px. The partial compiles with MVC 5.2's Razor.

Found on the live site: the trade page has no `<title>` or meta description.

Raised for a decision: the new words, "Speak to our trade team", the "Why" photo, the live "Why us?" pictures, the old phone number on the bulk bag in the hero photo, and the greens. See [open-questions.md](open-questions.md#trade-accounts-page).

## 24 September 2026: product page size heading

The product page's size step said "Select your bag size" on every product with more than one size, including 25 that aren't sold in bags: the stone glue (bottles), 21 bulb products (tubers, bulbs and corms), the two weed membranes (rolls) and the gift card (vouchers). It now says "bag size" only when every size is a bag, and "Select your size" otherwise. Checked by rendering all 153 live products: those 25 say "size", the 61 bag products still say "bag size", and products with one size are unchanged. The partial compiles with MVC 5.2's Razor.

Then the gift card's step became "Select your amount", since its sizes are vouchers (£20, £50, £100). Checked the same way: only the gift card changed.

## 24 September 2026: basket page

Rebuilt the prototype's basket (`basket.html`) as `Views/Basket/_BasketPage.cshtml`, with `BasketPageModel`. Details: [basket-page.md](basket-page.md).

1. Mapped the old basket from its view, its script and `BasketController`: the quantities are one form posted to `/basket/updatebasket` with a quantity per line in the cart's order, Remove posts to `/basket/removefrombasket`, vouchers to `/basket/applycouponcode`, and the four add-ons use `/basket/addtobasket`.
2. Built the page to post exactly those, with the prototype's line cards, total card, voucher box, Checkout Securely, "You might also like" (the old page's four add-ons) and the bottom strip. Quick + and - clicks are gathered into one post.
3. Found in the old code: turf lines have no quantity box, so in a basket with turf and anything else, the other lines' + and - post one quantity too few and nothing changes. The new page sends the turf's quantity in a hidden field.
4. The preview shows it at `/basket` with a sample basket of real products at live prices (the preview can't hold a real basket), and empty or with a voucher on request.
5. Tested: compiles with MVC 5.2's Razor; screenshots at four widths and the layout at 11; every text colour; and every action in headless Edge with the requests recorded, which matched the old page's. Along the way, the add-ons now stay four across down to 700px (at two across their photos were blown up to twice their size), and a photo that fails leaves a plain box: Empty Waste Bags has no photos at all on the image server.

Not tested: changing a real basket, which needs the test website.

Raised for a decision: Empty Waste Bags' missing photos, which add-ons to offer, "In stock" on each line, the old Trustpilot carousel, and restyling the "added to your basket" pop-up. See [open-questions.md](open-questions.md#basket-page).

## 24 September 2026: the "added to your basket" pop-up

The new product page's pop-up showed the basket's own summary (`AddToCartComponent.cshtml`) in the old site's styling. Every page's pop-up uses that summary, so instead of changing it, `gm-product.js` now reads the lines, total and add-ons out of it and shows them in the new basket page's style, with the line just added first and the add-ons below "Go to basket" and "Continue shopping". + and - and "Add" make the same requests as the summary's own buttons, and if the summary ever looks different it's shown as it comes, as before. Details: [product-page.md](product-page.md#choices).

Tested in headless Edge with a reply built exactly as the summary file builds it, and every request recorded rather than sent: the lines, the pre-order date, turf without + and -, + and - (and a failed change), "Add" on an add-on, the header total, Escape and focus, and an unexpected reply. Every text colour passes AA. Not tested: the real reply, on the test website.

## 24 September 2026: the header's search style kept to the header

`gm-chrome.css` styled every element with the class `search`, which was meant for the header's search form. The checkout's address finder (Postcode Anywhere) draws its search box as an `input.search`, so on every checkout page with the new header it picked up the header's rounded, padded style. The rules now name `form.search`. Checked in the preview: the header's search box measured the same before and after at 1440 and 390px wide, and its list of suggestions still gets its colour and layering.

## 24 September 2026: checkout

Rebuilt the prototype's checkout (`checkout.html`) as `Views/Checkout/_CheckoutPage.cshtml`, with `CheckoutPageModel`. Details: [checkout-page.md](checkout-page.md).

1. Worked out which checkout is live. The repository has three, but the live page's script uses a variable only `master`'s view sets, so the new page follows `master` (the SMS tick box, "Is this a trade order?", the pre-order steps).
2. Mapped the old checkout from its view, the live script and `CheckoutController`: the fields it posts to `/checkout/processorder`, the address finders, the delivery-date rules, the charges, the Isle of Wight and postcode-area checks, and the kinds of basket without a date step.
3. Built one page from the four old steps, in the prototype's layout, posting exactly the same fields. The address boxes keep the old ids, so the same Postcode Anywhere finders still fill them.
4. Moved the old view's date rules into `CheckoutDates.Build`, then ran the old loop, copied as it is, beside it on 20,000 random cases: the same dates, charges and first choice every time.
5. The preview shows it at `/checkout/processorder`, for the sample basket, with samples, pre-orders, a basket without a date step and PO postcodes on request.
6. Tested:
   - compiles with MVC 5.2's Razor, and so does the code `ProcessOrder.cshtml` will need;
   - screenshots at four widths, and the layout at 11;
   - every text colour and box edge;
   - in the browser, every check before sending and what the form would send, which matched the old page's fields;
   - in headless Edge, the keyboard, the progress steps and the Isle of Wight dates;
   - without the script, the paid dates stay switched off.

Along the way:
- the header's search style reached the finder's search box, and is now kept to the header (its own commit);
- the old stylesheet's rules for the finder are overridden;
- two selectors were fixed after the check showed the page's stylesheet was losing rules.

Found in the old code: the delivery charge is taken from the browser, so it could be changed before sending; the Isle of Wight check also caught every Portsmouth PO3 postcode; logging in never returns to the checkout. See [open-questions.md](open-questions.md#checkout).

Not tested: the real address finders, a real order and the payment page, and the real dates and prices, which need the test website.

## 24 September 2026: the basket's "Add to basket" buttons on phones

Found while building the order confirmation, which uses the same cards: on phones, where the basket's "You might also like" cards are two across, "Add to basket" wrapped onto two lines (measured at 390 and 320px wide). The buttons now keep to one line: slightly tighter below 560px, and without the basket icon below 420px. Measured at eight widths from 1440 to 320px: one line each time, and nothing wider than the screen.

## 24 and 25 September 2026: order confirmation

Rebuilt the prototype's order confirmation (`confirmation.html`) as `Views/Checkout/_ConfirmationPage.cshtml`, with `ConfirmationPageModel`. Details: [confirmation-page.md](confirmation-page.md).

1. Mapped the old page (`OrderResult.cshtml`) and `CheckoutController.OrderResult`. Loading the page marks the order as paid and sends the confirmation emails (once per order), so the new page never reloads itself, and the preview never asks the live site for it (it refuses any such address).
2. Built the page with what the old one showed (order number, amount paid, email, delivery address) in the prototype's layout, with "Track your order" opening the site's Track Order pop-up already filled in, and "You might also like" with the prototype's picks that are on the site, at their live prices.
3. The analytics and Facebook purchase events stay in the old view's sections, untouched.
4. The preview shows it at `/checkout/orderresult` for a sample order.
5. Tested:
   - the partial and the code `OrderResult.cshtml` will need compile with MVC 5.2's Razor;
   - screenshots at four widths and the layout at 11;
   - every text colour;
   - Track your order, and Add to basket's request (recorded) and its failure in the read-only preview;
   - the preview's refusal to load the live page.

Along the way: the email address now breaks after the @ in its narrow panel, the illustration is smaller on phones, and the suggestions' buttons keep to one line (the basket's too, in its own commit).

Raised: which products to suggest (the planter is a pre-order until May 2027), the page marking the order as paid on every load, and the customer's name. See [open-questions.md](open-questions.md#order-confirmation).

Not tested: the real page after a real test payment.

## 25 September 2026: one switch for the layout and the pages

Every merge step says "when the new chrome is on", but a page's view runs before `_Layout`, so it can't see the layout's own switch. The switch is now `NewChrome.IsOn(Request)` (`ViewModels/Common/NewChrome.cs`), used by `_Layout` and by any view that shows a new page, so they always agree. Checked against the old code copied from `_Layout`: the same answer in all 48 mixes of `?newchrome=` (1, 0, something else, none), the cookie (the same four) and the `UseNewChrome` setting (true, false, missing). The new `_Layout` lines compile with MVC 5.2's Razor. [merging.md](merging.md#first-start-from-the-latest-master) says how the page views use it.

## 25 September 2026: nothing hidden under the header on phones

Found while testing the new sign-in page on a phone: up to 860px wide the new header stays at the top of the screen, so when a page moved to something (the sign-in page's errors, the checkout's first box with a mistake) it ended up underneath the header. `gm-chrome.js` now tells the browser how tall the header is (`scroll-padding-top`), whatever its height: 158px for the normal header on a phone, 92px for the checkout's. Measured in headless Edge at 390, 768, 900 and 1440px: the registration error, the checkout's Full name box and the register form's first box each land just below the header, and from 900px up (where the header doesn't stay) nothing changes. `gm-chrome.js` and `gm-chrome.css` are now `?v3`, the stylesheet's for the search-box change of 24 September.

## 25 September 2026: account pages, part 1 (signing in)

The site's sign-in, register, trade application, forgotten and reset password pages, and the five messages they lead to, in the new design. There's no Optima prototype for them, so they use the checkout's panels, boxes and buttons. Details: [account-pages.md](account-pages.md).

1. Read the old pages, `_AccountMaster` and `AccountController`; the live sign-in and forgotten-password pages match `master`.
2. Built four partials posting exactly the old forms' fields, each with the anti-forgery token. The old "Remember me" was never sent, so it's left out. The trade form now checks what the server silently drops (a phone number not starting with 0 or with a +, a payment type not chosen). The messages now say what actually happens.
3. `_AccountMaster` shows just the page when the new design is on; the merge code for it and for each view compiles against stand-ins ([merging.md](merging.md#account-pages-signing-in)).
4. Tested:
   - screenshots at two widths and the layout at seven;
   - every text colour on six of the pages;
   - every form's checks, and what each would send (recorded, not sent);
   - opening with errors, in headless Edge.

Along the way: the shared `NewChrome.IsOn` switch, and room for the sticky header on phones (both their own commits). Found on the live site: trade applications dropped without a word, a broken privacy link, "Remember me" never working, password resets failing on a second try, and no limit on password guesses. See [open-questions.md](open-questions.md#account-pages).

Not tested: signing in, registering and resetting for real, and the emails.

## 25 September 2026: account pages, part 2 (My Account)

The pages behind the sign-in in the new design: orders, returns, a return request and its confirmation, price match, and the saved address. They share a new top (greeting and tabs) in place of the old purple side column. Details: [account-pages.md](account-pages.md#part-2-my-account).

1. Read the old views, `_AccountMaster`, `MyAccountController` and the `Agilis.ECommerce.Data` source they use (order lines, orders, addresses).
2. Built seven partials. Orders are grouped into one card per order, with Track order filling in the site's Track Order pop-up. The return and address forms post exactly the old fields. The price match message is now encoded, so "&amp;" and "#" no longer cut it short. Order lines show the size, from the saved "name&lt;br/&gt;size" (`AccountOrderLine.Describe`, tested with 18 examples). Photos use the 330px size: the 300px size the old page asked for is missing for most products.
3. Merge code for the six old views, compiled against stand-ins copied from the repository's own classes ([merging.md](merging.md#my-account-pages)).
4. Tested in the preview with a sample customer:
   - screenshots at two widths and the layout at seven (the tabs now wrap on phones, where Sign out had been hidden off the side);
   - every text colour on the seven pages;
   - Track order, the return form's checks and refund note, the address form's checks, and what each form would send (recorded, not sent);
   - the price match message with the sending stood in for, and blocked for real.

Found in the code: return requests emailed to a developer's inbox (and failures hidden), a page of raw payment details at `/myaccount/view`, a page of made-up quotes, an old return link giving an error page, and no message after saving the address. See [open-questions.md](open-questions.md#account-pages).

Not tested: real accounts and orders, sending returns and price matches, and saving an address.

## 25 September 2026: search results page

The page the header's search box goes to (`/search?searchphrase=…`) in the new design. There's no Optima prototype for it, so it's the category page's intro band and cards, four across without the sidebar. Details: [search-page.md](search-page.md).

1. Read how the search works: `CategoryController.Search` (in `BrandController.cs`, the two file names being swapped), `Views/Category/DisplayProducts.cshtml` and its tiles. It lists up to 100 products on sale whose name contains what was typed, and the tiles leave out the turf. Checked against ten live searches.
2. Built `Views/Category/_SearchPage.cshtml` with `SearchPageModel`. It uses the category page's own stylesheet, so the cards match exactly; `gm-search.css` adds the rest. New: a proper title, "Search results for “slate”" and how many were found, help when nothing is found (the old page was blank) or when more than 100 match, and the search put back in the header's box.
3. Merge code for `DisplayProducts.cshtml`, compiled against stand-ins copied from the repository's classes and, for the first time, run with sample data outside IIS: the same products in the same order, the turf left out, the title, `/search/<phrase>`, and the old page with the switch off ([merging.md](merging.md#search-results-page)).
4. The preview shows it for every search, filled from the live results. Its reader for the old product tiles is now shared with the category preview, whose output was checked byte-for-byte unchanged.
5. Tested:
   - the same products, in the same order, as the live search for ten searches;
   - the partial run for real with a search full of HTML and quotes: encoded everywhere (the old heading put the search in as typed);
   - in headless Edge: screenshots at three widths, nothing wider than the screen at 12, every text colour passes AA, Tab and focus outlines, the header's box filled in, no script errors.

Found: the customer price isn't hidden for trade customers on any page (`_Layout` uses a value browsers ignore), Azure Search admin keys written into both controller files, "turf" not finding the turf, `/search` alone giving an error page, and search pages open to Google with no title. See [open-questions.md](open-questions.md#search-results-page).

Not tested: the page on the test website, and a trade login.

## 25 September 2026: "Speak to our team" on the Trade Accounts page

Decided: the trade page's second button says "Speak to our team", not "Speak to our trade team", as there's no separate trade team. It still goes to Contact us. The partial compiles with MVC 5.2's Razor; in headless Edge the button is on one line at 1440 and 390px, with nothing wider than the screen.

## 25 September 2026: stock on each basket line

Decided: every basket line shows its stock with a coloured dot: green "In stock", purple "Pre-order for delivery w/c …" (as before), red "Out of stock" with the phone number. Details: [basket-page.md](basket-page.md#stock-on-each-line).

1. Read how the site keeps stock: per size, as each size's own `StockLevel`, counted down when an order is paid; `AddToBasket` refuses a size at 0. A basket line holds a copy of the main product, so the stock is read fresh from the size's record by the line's size code, with the same test.
2. `BasketLine.IsOutOfStock`, the three states in `_BasketPage.cshtml`, the dot colours in `gm-basket.css`, and the merge lines for `Basket/Index.cshtml` ([merging.md](merging.md#basket-page)).
3. The dot now sits beside the first line of words when they wrap; before, the pre-order dot sat halfway down its three lines on phones.
4. The preview's `/basket?stock=1` shows one of each: the planter (a real pre-order) and the pegs marked sold out as a sample.
5. Tested: the partial and merge lines compile with MVC 5.2's Razor; the merge lines ran on eight kinds of line; in headless Edge at 1440, 390 and 320px, the states, contrast (dots 5.4 to 8.7:1, words 15.4:1), the dot's place, nothing wider than the screen.

Found: a sold-out size can still be ordered (the checkout doesn't check), and a pre-order size added by its code loses its date, which affects the order confirmation's planter. See [open-questions.md](open-questions.md#basket-page).

Not tested: real stock levels, on the test website.

## 25 September 2026: the quantity calculator on the narrowest phones

Found while building the calculator page, which uses the shared calculator: below about 370px wide, "I'm looking for..." and the product type list didn't fit side by side, so at 320px the list ran 29px off the screen, on the homepage and product pages too. The two boxes a row also cut "Metres" to "Met" and squeezed the depth against its unit. From 370px down, the label now sits above the list in the same white box, and the boxes are one a row. Measured in headless Edge on the homepage at 320, 340, 370, 371, 375 and 390px, and on a product page and the calculator page at 320px: nothing wider than the screen, "Metres" shown whole. From 371px up nothing changes: the new rules only apply below it.

## Next

- Wire the finished pages into the site, once the code that's live is on a GravelMasterSoftware branch and there's a test site ([merging.md](merging.md#before-anything-which-code-is-live)).
- Test the checkout and the order confirmation with real orders and test payments on the test site ([merging.md](merging.md#checkout)).
- Still on the old design after that: content pages other than About and Trade, the "page not found" page and the payment error page.
