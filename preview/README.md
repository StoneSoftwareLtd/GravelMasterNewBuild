# Previewing the work

Two ways to see the new header, footer, homepage, category page, product page and About us page before they go anywhere near the real site.

## 1. The whole website: http://localhost:8780

Double-click **`Start website preview.cmd`** in the top folder of this repository. Your browser opens the preview. Keep the black window open while you use it, and close it to stop the preview.

In VS Code, **Terminal > Run Task > "Preview: open the whole website with the new header and footer"** does the same.

Every page comes from www.gravelmaster.co.uk with its old header and footer swapped for the new ones. The homepage (`/`) is replaced by the new homepage, and every category and subcategory page, with or without filters, by the new category page filled with that page's products, filters and description. So you can click around and they stay.

Every product page (`/products/<category>/p/<product>`) is replaced by the new product page, filled with that product's photos, sizes, description and related products. Its prices come from the live site's own price lookup (`/product/calculateprices`), which only reads prices, so entering a postcode shows the real prices for that area. Add to cart puts it in the preview's own basket (below) and opens the "added to your basket" pop-up, whose + and − and add-ons work too.

The About us page (`/about-us`) and the Trade Accounts page (`/trade`) are replaced by the new ones.

**The basket works.** The preview sends no cookies, so the live site never has a basket for it; the preview keeps its own instead (`tools/preview-basket.ps1`), while it runs, and answers the basket's addresses the way the site's basket does, so the new pages' own scripts work unchanged. Nothing reaches the live site's basket: prices come from its read-only price lookup, for the postcode area each item was added with.

- **Adding**: Add to cart and "Order a sample" on any product page; + and −, and the three add-ons, in the "added to your basket" pop-up; "Add to basket" on the basket page's and the order confirmation's suggestions. The same size again adds to its line, as on the site (not turf).
- **Postcode area**: as on the site, adding with a postcode in another area moves the whole basket to that area and re-prices it (samples and fixed-price items stay as they are).
- **The basket** (`/basket`): change quantities, Remove, Empty basket, and a voucher: **PREVIEW10** is a sample 10% voucher for orders over £40 (the site's real vouchers are in its database, which the preview can't read); any other code is "Invalid coupon code". Turf has no + and −, as on the site. The header's basket total is the preview basket's.
- **The checkout** (`/checkout/processorder`, or Checkout Securely): the new checkout for your basket, in the live basket page's frame. An empty basket goes back to `/basket`, as on the site. Its delivery dates and prices are samples in the shape the site makes them, run through the real date rules (`CheckoutDates.Build`). The address finders aren't loaded (typing would use the site's Postcode Anywhere account): a copy of their search box stands in, so type the address into the boxes.
- **Continue to payment** checks the delivery postcode is in the basket's area, as `CheckoutController.ProcessOrder` does, then goes to the new **payment error page** (`/checkout/orderresulterror`): payment isn't set up in the preview. A postcode outside the area goes to the same page's other version (`?loc=ng`), as on the site. Nothing is sent anywhere, and no order is made.
- The basket lasts until the preview is closed. It's one basket for everyone using this preview.

The sample baskets and checkouts are still there to look at every state: `/basket?sample=1`, `?empty=1`, `?voucher=1&discount=1` and `?stock=1` (the planter is a real pre-order; the pegs are marked sold out as a sample, since the preview can't see stock); `/checkout/processorder?sample=1`, `?samples=1`, `?preorder=1`, `?mixed=1`, `?simple=1`, `?notimes=1` and `?area=PO` (no Saturdays; try an Isle of Wight postcode such as PO30 5AA). Changing a sample basket does nothing, and its checkout's Continue to payment checks out your own basket.

The order confirmation (`/checkout/orderresult`) is the new confirmation for a **sample order**, in the same frame: no checkout reaches it, as payment isn't set up. The live page is never asked for: loading it marks an order as paid, so the preview refuses any `/checkout/orderresult` address it would have to fetch. Its suggestions are the real products at their live prices; adding one puts it in your basket.

**Accounts work too.** The preview can never sign in to the live site, so it keeps accounts of its own (`tools/preview-account.ps1`), while it runs, and answers the account pages' forms the way the site's `AccountController` and `MyAccountController` do. No email is sent: where the site would email a link, the next page's yellow bar shows the link instead.

- **Sign in** (`/account/login`, or Login in the header) with the sample customer, whose email and test password are on the sign-in page's yellow bar (it has two sample orders of real products), or with an account made in the preview. A wrong password gives "Either your email or password was wrong"; an account whose email isn't confirmed yet gives "You haven't confirmed your email", as on the site. Signed in, the header shows the first name, and Sign out works.
- **Create an account**: "Thank you for registering!", with the confirmation email's link on the yellow bar; follow it to confirm, then sign in. The same email twice gives the site's "already taken" message.
- **Apply for a trade account** (`/account/login?isTradeRegister=true`): "Thank you for your application", with the approval email's link on the yellow bar (on the site the team approves it first). It opens "You're in!", and the account made there is a trade one: My Account shows the Trade account tag and `/product/istrade` says so. (Prices stay the customer ones: the live price lookup only gives trade prices to a signed-in trade customer.)
- **Forgotten password**: "Check your email", with the reset email's link on the yellow bar for a confirmed account (none for an unknown one, as the site sends nothing); it opens "Choose a new password", which changes it.
- **My Account** (`/myaccount/orders` and its tabs) needs signing in, as on the site. The address form saves (and the checkout then fills the address in for you), "Request a return" on an item sends its form and shows "Return request sent" with the order number, and the price match message says it's been sent.
- Accounts made in the preview have no orders: payment isn't set up, so no checkout makes one.

The sign-in page's yellow bar still links to samples of each state for looking at: the trade form, a wrong password, a registration error, an approved trade customer and the five messages. `/myaccount/orders?sample=1`, `?empty=1`, `?trade=1` and `?noreturns=1` show the sample customer without signing in, with orders, none, a trade account and the Returns tab switched off. The preview never loads the live email-confirmation link, which confirms a real account.

**Forms that would send an email** answer as the site does, and send nothing: the bulk delivery enquiry, "Send me my estimate", the price match message and the newsletter sign-up. The preview's black window lists what each would have sent.

The delivery page (`/delivery`), the calculator page (`/calculator`), the FAQ page (`/faq`) and the contact page (`/contact-us`) are the new ones; the calculator page's three gravels come from `tools/data.json`. The contact page's map comes from Google Maps, not the live site. The privacy policy (`/privacy`) and the terms (`/term-conditions`) are the admin site's words as they are now, in the new design; add `?tidy=1` to see the tidied copies from `docs/admin-content` instead. Meet the team (`/meet-the-team`) and the Price Match Promise page (`/price-match`) are the new ones, and so is "page not found" for any address the live site doesn't have (shown in a content page's frame, still answering 404). The old Articles pages (`/articles` and its categories) go to Ideas & Advice, as they will with the new design on. The Ideas & Advice pages (`/ideas-advice`, its topics and its articles) are the new ones. The live landing page doesn't show the 20 newest articles the new one lists, so the preview stands in with the topic pages' articles, newest first by their number.

The search results (`/search?searchphrase=…`, or the header's search box) are the new search page, filled with the live search's results for that search, in the same order. Try a search that finds nothing (e.g. `xyzzy`) or one that finds more than fit on the page (e.g. `e`). The special offers page (`/special-offers`) is the new one, with the live page's products; `?empty=1` shows it with none.

- Saving a `gm-*.css` or `gm-*.js` file, a `gm-*` image or any `.cshtml` file reloads the page with the change. (A change to a script in `tools/`, or to a `ViewModels/Common/*.cs` file, needs the preview restarting: the product page runs the real C# model, compiled when the preview starts.)
- Add `?newchrome=0` to an address to compare with the old header, footer, homepage and category pages (it sticks while you click around). `?newchrome=1` switches back. Page titles start with `[Preview]`.
- The Track Order pop-up is the new one. The live order lookup is never asked (it reads real customers' orders): the preview answers for sample orders with the lookup's own sentences, and the pop-up lists them (postcode NG7 2RD with 123456, 123457, 123458 or 118870; see `tools/track-order.ps1`).
- Nothing is sent to the real site except page views and its read-only lookups. The basket, checkout and accounts are the preview's own, and email forms send nothing (above). Anything else that would change something is blocked. The one form let through is **Sort by** on category pages, and only with one of its four choices, because it only changes the order of the products. No cookies are sent. Analytics, Hotjar, Clarity, Facebook and chat are removed so preview visits aren't counted.
- The basket and accounts last until the preview is closed, and they're shared by everyone using the same preview (one basket, one signed-in customer).

### Known limits

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
| `info-pages.ps1` | Fills in Meet the team (`_MeetTeamPage.cshtml`, reading its people from the partial's own C# block), the Price Match Promise page (`_PriceMatchPromisePage.cshtml`), "page not found" (`_NotFoundPage.cshtml`, with the header's categories from `data.json`), the delivery page (`_DeliveryPage.cshtml`, reading its checklist from the partial's own C# block), the calculator page (`_CalculatorPage.cshtml`, with the shared calculator, the bulk enquiry pop-up and its three gravels from `data.json`), the FAQ page (`_FaqPage.cshtml`, reading its topics and questions from the partial's own C# block), the contact page (`_ContactPage.cshtml`, plain markup) and the privacy and terms pages (`_LegalPage.cshtml`, around the admin site's HTML read from the live page, or `docs/admin-content`'s copy with `?tidy=1`). |
| `ideas-pages.ps1` | Reads the old Ideas & Advice pages (the topics, a topic's articles, an article's title, picture and words) and fills in the three Ideas partials, as `_ContentHubLayout.cshtml`'s new branch puts them together. |
| `search-page.ps1` | Reads an old search results page (the phrase, the products, whether more matched than fit) and fills in `_SearchPage.cshtml`; reads the old special offers page's products the same way and fills in `_OffersPage.cshtml`. |
| `product-page.ps1` | Reads an old product page into what the new one shows, and fills in `_ProductPage.cshtml` the same way. The description is split by the real `ProductDescription.Parse`, compiled from `ViewModels/Common` with `Add-Type`. |
| `calculator.ps1` | Fills in the shared quantity calculator (`_QuantityCalculator.cshtml`) for the homepage and product pages. |
| `about-page.ps1` | Fills in `_AboutPage.cshtml`, reading its team and photos from the partial's own C# block. |
| `trade-page.ps1` | Fills in `_TradePage.cshtml`, reading its perks and sign-up address from the partial's own C# block. |
| `basket-page.ps1` | Builds the sample basket from live product pages and fills in `_BasketPage.cshtml` with a basket. |
| `checkout-page.ps1` | Builds a checkout for a basket, with sample dates run through the real `CheckoutDates.Build` (compiled from `ViewModels/Common/CheckoutPageModels.cs` with `Add-Type`), and fills in `_CheckoutPage.cshtml` with it; fills in the payment error page (`_PaymentErrorPage.cshtml`, with the real `PaymentErrorModel`). |
| `preview-basket.ps1` | The preview's working basket: answers the basket's addresses as the site's basket does, prices from the live price lookup, and Continue to payment. |
| `preview-account.ps1` | The preview's accounts (and the sample customer's test password): signing in, registering, trade applications, passwords and My Account's forms, and the forms that would send an email. |
| `confirmation-page.ps1` | Builds the sample order, with the four suggestions read from their live product pages, and fills in `_ConfirmationPage.cshtml` with it. |
| `account-pages.ps1` | Fills in the four account partials: the sign-in page for a few sample states, the two password forms and the five messages. |
| `myaccount-pages.ps1` | Builds the sample customer and orders from live product pages and fills in the My Account partials, with `_AccountAreaHead.cshtml` at the top of each. |
| `track-order.ps1` | The Track Order pop-up's answers for the sample orders, as the site's order lookup gives them. |
| `site-preview.ps1` | The whole-website preview. |
| `fetch-data.ps1` | Re-reads menus, products, banners and a sample category page from the live site, then runs `build.ps1`. |
| `data.json` | The live site's menus, products, prices and homepage banners (fetched 17 September 2026). |
| `old-body.html` | The old Gravels & Chippings category page's content, used to fill `category.html`. |

No Node or Python is needed. Everything runs in Windows PowerShell 5.1.
