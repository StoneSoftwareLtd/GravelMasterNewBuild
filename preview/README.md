# Previewing the work

Two ways to see the new header, footer, homepage, category page, product page and About us page before they go anywhere near the real site.

## 1. The whole website: http://localhost:8780

Double-click **`Start website preview.cmd`** in the top folder of this repository. Your browser opens the preview. Keep the black window open while you use it, and close it to stop the preview.

In VS Code, **Terminal > Run Task > "Preview: open the whole website with the new header and footer"** does the same.

Every page comes from www.gravelmaster.co.uk with its old header and footer swapped for the new ones. The homepage (`/`) is replaced by the new homepage, and every category and subcategory page, with or without filters, by the new category page filled with that page's products, filters and description. So you can click around and they stay.

Every product page (`/products/<category>/p/<product>`) is replaced by the new product page, filled with that product's photos, sizes, description and related products. Its prices come from the live site's own price lookup (`/product/calculateprices`), which only reads prices, so entering a postcode shows the real prices for that area. Add to cart is blocked like every other basket action: the page says it couldn't add, which is what a customer would see if the basket failed.

The About us page (`/about-us`) and the Trade Accounts page (`/trade`) are replaced by the new ones.

The basket (`/basket`) is the new basket page with a **sample basket** in it: the preview sends no cookies, so the live site's basket is always empty. The sample is real products (Cotswold Chippings, turf and plastic pegs) at their live prices. `/basket?empty=1` shows the empty basket, `/basket?voucher=1&discount=1` a voucher message and a 10% discount, and `/basket?stock=1` a line of each stock state (the planter is a real pre-order; the pegs are marked sold out as a sample, since the preview can't see stock). Changing it (quantities, Remove, vouchers, add-ons) is blocked like every other basket action, and the page says so.

The checkout (`/checkout/processorder`, or Checkout Securely on the basket) is the new checkout for that sample basket, shown in the live basket page's frame, since the live site sends a checkout with no basket back to `/basket`. Its delivery dates and prices are samples in the shape the site makes them, run through the real date rules (`CheckoutDates.Build`). `?samples=1`, `?preorder=1`, `?mixed=1`, `?simple=1` and `?notimes=1` show the other kinds of delivery, and `?area=PO` a basket priced for PO postcodes (no Saturdays; try an Isle of Wight postcode such as PO30 5AA). The address finders aren't loaded (typing would use the site's Postcode Anywhere account): a copy of their search box stands in. "Continue to payment" is blocked like every other form.

The order confirmation (`/checkout/orderresult`) is the new confirmation for a **sample order**, in the same frame. The live page is never asked for: loading it marks an order as paid, so the preview refuses any `/checkout/orderresult` address it would have to fetch. Its suggestions are the real products at their live prices; adding them is blocked like every other basket action.

The account pages (`/account/login`, `/account/forgotpassword`, `/account/resetpassword`) are the new ones, and so are the messages they lead to: `/account/forgotpasswordconfirmation`, `/account/resetpasswordconfirmation`, `/account/confirmemail`, `/account/register` and `/account/traderegister` (the last two are only reached by posting a form on the real site). The sign-in page's yellow bar links to every state: the trade form, a wrong password, a registration error and an approved trade customer. Every form is blocked, and the preview never loads the live email-confirmation link, which confirms an account.

My Account (`/myaccount/orders`, `/myaccount/returns`, `/myaccount/requestreturn`, `/myaccount/returnconfirmation`, `/myaccount/pricematch` and `/myaccount/editaddress`) is the new one for a **sample customer** with two sample orders of real products, in the live forgotten-password page's frame: the preview is never signed in, so the live `/myaccount` sends it to sign in. `?empty=1`, `?trade=1` and `?noreturns=1` show a customer with no orders, a trade customer and the Returns tab switched off. The return and address forms are blocked like every other form, and so is sending a price match (`/product/sendpricematchquery`), which emails the team.

The delivery page (`/delivery`) and the calculator page (`/calculator`) are the new ones; the calculator page's three gravels come from `tools/data.json`.

The search results (`/search?searchphrase=…`, or the header's search box) are the new search page, filled with the live search's results for that search, in the same order. Try a search that finds nothing (e.g. `xyzzy`) or one that finds more than fit on the page (e.g. `e`).

- Saving a `gm-*.css` or `gm-*.js` file, a `gm-*` image or any `.cshtml` file reloads the page with the change. (A change to a script in `tools/`, or to a `ViewModels/Common/*.cs` file, needs the preview restarting: the product page runs the real C# model, compiled when the preview starts.)
- Add `?newchrome=0` to an address to compare with the old header, footer, homepage and category pages (it sticks while you click around). `?newchrome=1` switches back. Page titles start with `[Preview]`.
- It is read-only. Adding to basket, sign-ups, enquiries, "Send me my estimate", Track Order and logging in are blocked (the forms say they couldn't send). The one form let through is **Sort by** on category pages, and only with one of its four choices, because it only changes the order of the products. No cookies are sent, so the basket is always empty. Analytics, Hotjar, Clarity, Facebook and chat are removed so preview visits aren't counted.

### Known limits

- The "page not found" page keeps the old header and footer. That page is built from a different template to the rest of the site, and the branch only changes `_Layout.cshtml`, so the real site would show it the same way.
- The live checkout sends an empty basket back to `/basket`, so the preview's checkout is a sample in the basket page's frame (see above).
- The Trustpilot widgets (homepage, product, About and Trade pages) load but stay empty, probably because Trustpilot only fills them on the real site's address.
- The old product pages show two console errors (reading `'className'`, and "Unexpected identifier 'Object'"), on the live site too. They come from the old page's own scripts, so the new product page doesn't have them; add `?newchrome=0` to see them.

## 2. Single saved pages with VS Code Live Server

Open this repository's folder in VS Code, then right-click a page in `preview` > **Open with Live Server**:

| Page | Shows |
|---|---|
| `index.html` | the new homepage |
| `category.html` | the new category page, filled from Gravels & Chippings as saved in `tools/old-body.html` |
| `checkout.html` | the checkout version of the header |

These pages are generated, so they aren't stored in git. Starting the whole-website preview once creates them, or run **Terminal > Run Task > "Preview: rebuild and watch .cshtml files"**.

Clicking a link, or choosing a Sort by option, opens that page in the whole-website preview (start it first; if it isn't running, the page tells you). Saving a `.css`, `.js` or image file updates the page straight away. After editing a `.cshtml` file, run "Preview: rebuild and watch .cshtml files".

## Menu and product data

Menus, product photos and prices come from the live site and are saved in `tools/data.json`. To refresh them: **Terminal > Run Task > "Preview: refresh menu data from the live site"**.

## Files in `tools/`

| File | What it does |
|---|---|
| `build.ps1` | Turns the `.cshtml` files in `Website/Website` into the saved pages and the pieces `site-preview.ps1` uses. Plain markup is taken from the `.cshtml` files as it is; only the Razor loops are re-created, and the build fails if any Razor is left over. |
| `category-page.ps1` | Reads an old category page into what the new one shows (the same split of the description as `CategoryDescription.Parse`) and fills in `_CategoryPage.cshtml`. It finds each Razor block in the file, so the markup always comes from the partial, and fails if any Razor is left over. Its reader for the old product tiles is shared with the search page. |
| `info-pages.ps1` | Fills in the delivery page (`_DeliveryPage.cshtml`, reading its checklist from the partial's own C# block) and the calculator page (`_CalculatorPage.cshtml`, with the shared calculator, the bulk enquiry pop-up and its three gravels from `data.json`). |
| `search-page.ps1` | Reads an old search results page (the phrase, the products, whether more matched than fit) and fills in `_SearchPage.cshtml`. |
| `product-page.ps1` | Reads an old product page into what the new one shows, and fills in `_ProductPage.cshtml` the same way. The description is split by the real `ProductDescription.Parse`, compiled from `ViewModels/Common` with `Add-Type`. |
| `calculator.ps1` | Fills in the shared quantity calculator (`_QuantityCalculator.cshtml`) for the homepage and product pages. |
| `about-page.ps1` | Fills in `_AboutPage.cshtml`, reading its team and photos from the partial's own C# block. |
| `trade-page.ps1` | Fills in `_TradePage.cshtml`, reading its perks and sign-up address from the partial's own C# block. |
| `basket-page.ps1` | Builds the sample basket from live product pages and fills in `_BasketPage.cshtml` with it. |
| `checkout-page.ps1` | Builds the sample checkout for the sample basket, with sample dates run through the real `CheckoutDates.Build` (compiled from `ViewModels/Common/CheckoutPageModels.cs` with `Add-Type`), and fills in `_CheckoutPage.cshtml` with it. |
| `confirmation-page.ps1` | Builds the sample order, with the four suggestions read from their live product pages, and fills in `_ConfirmationPage.cshtml` with it. |
| `account-pages.ps1` | Fills in the four account partials: the sign-in page for a few sample states, the two password forms and the five messages. |
| `myaccount-pages.ps1` | Builds the sample customer and orders from live product pages and fills in the My Account partials, with `_AccountAreaHead.cshtml` at the top of each. |
| `site-preview.ps1` | The whole-website preview. |
| `fetch-data.ps1` | Re-reads menus, products, banners and a sample category page from the live site, then runs `build.ps1`. |
| `data.json` | The live site's menus, products, prices and homepage banners (fetched 17 September 2026). |
| `old-body.html` | The old Gravels & Chippings category page's content, used to fill `category.html`. |

No Node or Python is needed. Everything runs in Windows PowerShell 5.1.
