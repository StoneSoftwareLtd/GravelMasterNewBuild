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

## 23 September 2026: product page (in progress)

Rebuilding the prototype's product page (`product2.html`). The GravelMasterSoftware repository is on this PC now, so the page is being mapped from the real code as well as the live pages. Details: [product-page.md](product-page.md).

1. Mapped what the live product page does, from `Detail.cshtml`, its script, the product controller and the basket's add-to-basket action, checked on eight live pages, and where each part goes in the prototype.
2. Added `ProductPageModel` and `ProductDescription.Parse`. The live descriptions follow the prototype's layout already (intro, a list of "Label: value" lines, then "Colour and Shape" and "Availability"), so Parse splits them into the intro, the specification table, the uses and the other sections. A section that has anything besides those lines is shown as written. Tested on the eight live descriptions and edge cases; `GetPostcodeArea` tested on full, partial and invalid postcodes and areas the site doesn't deliver to.

Raised for a decision: the random "purchases during last 24 hours" pop-up, the rating, badge and selling points the site has no data for, add-ons, and Blue Slate's photos. See [open-questions.md](open-questions.md#product-page).

## Next

Waiting on the GravelMasterSoftware repository to wire the homepage and category page in ([merging.md](merging.md)). The prototype's other pages (product, basket, checkout, about, trade) are still to come.
