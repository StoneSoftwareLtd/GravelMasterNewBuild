# Previewing the work

Two ways to see the new header, footer and homepage before they go anywhere near the real site.

## 1. The whole website: http://localhost:8780

Double-click **`Start website preview.cmd`** in the top folder of this repository. Your browser opens the preview. Keep the black window open while you use it, and close it to stop the preview.

In VS Code, **Terminal > Run Task > "Preview: open the whole website with the new header and footer"** does the same.

Every page comes from www.gravelmaster.co.uk with its old header and footer swapped for the new ones, and the homepage (`/`) replaced by the new homepage, so you can click around and they stay.

- Saving `gm-chrome.css`, `gm-home.css`, the `.js` files, a `gm-*` image or any `.cshtml` file reloads the page with the change.
- Add `?newchrome=0` to an address to compare with the old header, footer and homepage (it sticks while you click around). `?newchrome=1` switches back. Page titles start with `[Preview]`.
- It is read-only. Adding to basket, sign-ups, enquiries, "Send me my estimate", Track Order and logging in are blocked (the forms say they couldn't send). No cookies are sent, so the basket is always empty. Analytics, Hotjar, Clarity, Facebook and chat are removed so preview visits aren't counted.

### Known limits

- The "page not found" page keeps the old header and footer. That page is built from a different template to the rest of the site, and the branch only changes `_Layout.cshtml`, so the real site would show it the same way.
- Checkout redirects to the basket while the basket is empty, so the checkout version of the header can't be reached here. `preview/checkout.html` shows it.
- The two console errors on product pages (reading `'className'`, and "Unexpected identifier 'Object'") happen on the live site too. They are not caused by the new header or footer.

## 2. Single saved pages with VS Code Live Server

Open this repository's folder in VS Code, then right-click a page in `preview` > **Open with Live Server**:

| Page | Shows |
|---|---|
| `index.html` | the new homepage |
| `category.html` | an old category page with the new header and footer |
| `checkout.html` | the checkout version of the header |

These pages are generated, so they aren't stored in git. Starting the whole-website preview once creates them, or run **Terminal > Run Task > "Preview: rebuild and watch .cshtml files"**.

Clicking a link opens that page in the whole-website preview (start it first; if it isn't running, the page tells you). Saving a `.css`, `.js` or image file updates the page straight away. After editing a `.cshtml` file, run "Preview: rebuild and watch .cshtml files".

## Menu and product data

Menus, product photos and prices come from the live site and are saved in `tools/data.json`. To refresh them: **Terminal > Run Task > "Preview: refresh menu data from the live site"**.

## Files in `tools/`

| File | What it does |
|---|---|
| `build.ps1` | Turns the `.cshtml` files in `Website/Website` into the saved pages and the pieces `site-preview.ps1` uses. Plain markup is taken from the `.cshtml` files as it is; only the Razor loops are re-created, and the build fails if any Razor is left over. |
| `site-preview.ps1` | The whole-website preview. |
| `fetch-data.ps1` | Re-reads menus, products, banners and a sample category page from the live site, then runs `build.ps1`. |
| `data.json` | The live site's menus, products, prices and homepage banners (fetched 17 September 2026). |
| `old-body.html` | The old Gravels & Chippings category page's content, used by `category.html`. |

No Node or Python is needed. Everything runs in Windows PowerShell 5.1.
