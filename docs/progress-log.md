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

## Next: category page

Mapped what the live category pages do, and how that fits the prototype's category page: [category-page.md](category-page.md).
