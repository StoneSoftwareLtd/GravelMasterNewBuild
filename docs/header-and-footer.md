# Header, footer and mobile menu

The Optima prototype's header, footer and slide-in phone menu, ported into the site on the GravelMasterSoftware branch **new-chrome**. This repository started from that branch's changed files (supplied as a zip on 16 September 2026).

The branch's commits, oldest first:

| Commit | |
|---|---|
| 7463d6c | Move order-tracking modal into _TrackOrderModal partial |
| d7df58c | Add gm-chrome.css for the new header and footer |
| 60f461d | Add new header, footer and mobile-menu partials |
| e3385ef | Swap _Layout to the new chrome behind UseNewChrome |
| 059c57f | Match the prototype's text and image alignment in gm-chrome.css |
| f4d6839 | Keep live-domain links on localhost during local preview |
| 54b3d01 | Remove the Trustpilot widget from the new header |
| 75c73d1 | Fill the mega menus with real category content |

Its changes compared with master, from before the 17 September fixes, are in `patches/header-and-footer (before 2026-09-17 fixes).patch`.

## How it switches on

`_Layout.cshtml` reads the `UseNewChrome` app setting in `Web.config`:

- **on**: renders `_SiteHeader`, `_SiteFooter` and `_SiteMobileMenu`, loads `css/gm-chrome.css` and `js/gm-chrome.js`;
- **off**: renders `_LegacyHeader` and `_LegacyFooter`, which are the old header and footer, unchanged, moved out of `_Layout`.

`?newchrome=1` or `?newchrome=0` on any address overrides the setting for that browser, for testing.

The menus come from the database: top-level categories, their subcategories and their products, so the mega menu stays up to date on its own.

## Files

New:

| File | What it is |
|---|---|
| `Views/Shared/_SiteHeader.cshtml` | new header: top bar, logo, search, trade/calculator/basket links, category bar with mega menus, trust bar |
| `Views/Shared/_SiteFooter.cshtml` | new footer |
| `Views/Shared/_SiteMobileMenu.cshtml` | slide-in phone menu |
| `Views/Shared/_LegacyHeader.cshtml` | old header, unchanged, moved out of `_Layout` |
| `Views/Shared/_LegacyFooter.cshtml` | old footer, unchanged, moved out of `_Layout` |
| `Views/Shared/_TrackOrderModal.cshtml` | Track Order pop-up, used by both |
| `css/gm-chrome.css` | styles for the new design |
| `js/gm-chrome.js` | phone menu, footer carousel, basket total |
| `img/gm-*.png`, `gm-*.jpg` | logos, advisor photo and payment cards |

Changed:

| File | Change |
|---|---|
| `Views/Shared/_Layout.cshtml` | switches between the old and new header and footer |
| `ViewModels/Common/MasterLayoutViewModel.cs` | `BasketTotal` and the mega-menu helpers (`GetMenuProducts`, `GetMenuProductUrl`, `GetIdealFor`) |
| `Website.csproj` | lists the new files |

`MasterLayoutViewModel.cs` is C#, so the Website project needs rebuilding after copying it. Views, CSS, JavaScript and images need no build.

## Keeping the new styles away from the old page

The old page content still sits underneath the new header and footer, with Bootstrap 4 and the site's `global.css` loaded first. `gm-chrome.css` is written so it can't change anything outside `.site-header`, `.footer`, `.mobile-menu` and `.postcode-modal`:

- every rule is scoped to those elements;
- class names shared with Bootstrap (`.container`, `.dropdown`) are scoped too;
- the colour variables are set on the chrome elements, not `:root` (Bootstrap defines `--green`, `--blue`, `--red` and others on `:root` for the whole page);
- a "shield" resets the old element rules (Bootstrap Reboot, `global.css`) inside the chrome.

## Fixes made on 17 September 2026

Each fix has its own commit. They were tested in a static preview built from these files, sitting on the live site's stylesheets and a real category page, at 1440, 1100, 1000, 900, 861, 768 and 375px wide. The layout measured the same before and after.

1. **Search: Enter didn't search.** `autocomplete()` in `_Layout.cshtml` blocked Enter even with no suggestion highlighted, so the form never submitted. Enter now searches, and Enter on a highlighted suggestion still opens that product. The old header uses the same function, so the live site has this bug too.
2. **gm-chrome.css changed the rest of the page.** The colour variables were set on `:root`, replacing Bootstrap's `--green`, `--blue`, `--red` and so on for the whole page. They are now set on the chrome elements only. `_Layout` only loads `gm-chrome.css` when the new chrome is on, so with `UseNewChrome` off the site is unchanged. The css link went from `?v1` to `?v2`.
3. **Mobile menu: keyboard access.** While closed, the menu's 31 links and buttons could still be tabbed to, even though they were off-screen, and so could the links in collapsed categories. They are now hidden until shown. Opening the menu moves focus to its close button, Tab stays inside the open menu, and closing it returns focus to the menu button. The js link went from `?v1` to `?v2`.
4. **Images.** `img/gm-payment-cards.png` was 1486x242 (125 KB) for a 215x35 space; it's now 645x105 (42 KB), which is still sharp on high-resolution screens. Every image in `_SiteHeader` and `_SiteFooter` has width and height so the page doesn't jump as images load, and the footer images use `loading="lazy"`.
5. **Mega menu read the product list 12 times per page.** `GetMenuProducts` called `productRepository.GetAllProducts()` for every category and subcategory. It now loads the list once and filters it. A test comparing the old and new method on 17,500 random cases gave identical results in the same order.

## Gaps

Each needs a decision (see [open-questions.md](open-questions.md)):

- the prototype's "Delivering to: postcode" box isn't ported;
- the prototype's LinkedIn icon isn't in the footer;
- the old site's Contact link isn't in the new header (the prototype doesn't have one either);
- the prototype's mobile menu lists sub-sections for every category, but the live site only has 4 subcategories across its 8 categories, so four categories open to just a "Shop all" link.

## Before merging

See [merging.md](merging.md): the live `_Layout.cshtml` is newer than the branch's master, and the "page not found" page has its own copy of the old header.
