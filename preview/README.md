# Previewing the work

Two ways to see the new header, footer, homepage, category page, product page and About us page before they go anywhere near the real site.

## 1. The whole website: http://localhost:8780

Double-click **`Start website preview.cmd`** in the top folder of this repository. Your browser opens the preview. Keep the black window open while you use it, and close it to stop the preview.

In VS Code, **Terminal > Run Task > "Preview: open the whole website with the new header and footer"** does the same.

Every page comes from www.gravelmaster.co.uk with its old header and footer swapped for the new ones. The homepage (`/`) is replaced by the new homepage, and every category and subcategory page, with or without filters, by the new category page filled with that page's products, filters and description. So you can click around and they stay.

Every product page (`/products/<category>/p/<product>`) is replaced by the new product page, filled with that product's photos, sizes, description and related products. Its prices come from the live site's own price lookup (`/product/calculateprices`), which only reads prices, so entering a postcode shows the real prices for that area. Add to cart is blocked like every other basket action: the page says it couldn't add, which is what a customer would see if the basket failed.

The About us page (`/about-us`) and the Trade Accounts page (`/trade`) are replaced by the new ones.

- Saving a `gm-*.css` or `gm-*.js` file, a `gm-*` image or any `.cshtml` file reloads the page with the change. (A change to a script in `tools/`, or to a `ViewModels/Common/*.cs` file, needs the preview restarting: the product page runs the real C# model, compiled when the preview starts.)
- Add `?newchrome=0` to an address to compare with the old header, footer, homepage and category pages (it sticks while you click around). `?newchrome=1` switches back. Page titles start with `[Preview]`.
- It is read-only. Adding to basket, sign-ups, enquiries, "Send me my estimate", Track Order and logging in are blocked (the forms say they couldn't send). The one form let through is **Sort by** on category pages, and only with one of its four choices, because it only changes the order of the products. No cookies are sent, so the basket is always empty. Analytics, Hotjar, Clarity, Facebook and chat are removed so preview visits aren't counted.

### Known limits

- The "page not found" page keeps the old header and footer. That page is built from a different template to the rest of the site, and the branch only changes `_Layout.cshtml`, so the real site would show it the same way.
- Checkout redirects to the basket while the basket is empty, so the checkout version of the header can't be reached here. `preview/checkout.html` shows it.
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
| `category-page.ps1` | Reads an old category page into what the new one shows (the same split of the description as `CategoryDescription.Parse`) and fills in `_CategoryPage.cshtml`. It finds each Razor block in the file, so the markup always comes from the partial, and fails if any Razor is left over. |
| `product-page.ps1` | Reads an old product page into what the new one shows, and fills in `_ProductPage.cshtml` the same way. The description is split by the real `ProductDescription.Parse`, compiled from `ViewModels/Common` with `Add-Type`. |
| `calculator.ps1` | Fills in the shared quantity calculator (`_QuantityCalculator.cshtml`) for the homepage and product pages. |
| `about-page.ps1` | Fills in `_AboutPage.cshtml`, reading its team and photos from the partial's own C# block. |
| `trade-page.ps1` | Fills in `_TradePage.cshtml`, reading its perks and sign-up address from the partial's own C# block. |
| `site-preview.ps1` | The whole-website preview. |
| `fetch-data.ps1` | Re-reads menus, products, banners and a sample category page from the live site, then runs `build.ps1`. |
| `data.json` | The live site's menus, products, prices and homepage banners (fetched 17 September 2026). |
| `old-body.html` | The old Gravels & Chippings category page's content, used to fill `category.html`. |

No Node or Python is needed. Everything runs in Windows PowerShell 5.1.
