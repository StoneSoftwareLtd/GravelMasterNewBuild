# Putting it live: what to do in GravelMasterSoftware

Everything here needs the GravelMasterSoftware repository, which isn't on this PC yet. The files in `Website/Website` are at the same paths as in that repository.

## First: start from the latest master

Checked against www.gravelmaster.co.uk on 17 September 2026: the live pages are built from a **newer `_Layout.cshtml`** than the one the new-chrome branch changed. The live one has things this copy doesn't:

- Google Tag Manager (`GTM-KMX9ZL3`) and Microsoft Clarity (`skcynpme2d`);
- `global.css?v210` (this copy has `?v108`);
- `WebFont.load` for Montserrat and Quicksand 400/500/700;
- a different old footer: "Find Out About Our Latest Products & Offers", an orange Ideas | About | Contact | Trade link bar, and the logo at `/cdn/logo-comp.jpg`.

Copying this repository's `_Layout.cshtml`, `_LegacyHeader.cshtml` or `_LegacyFooter.cshtml` over the live code would remove those. Instead:

1. Take the latest master.
2. Redo the `_Layout` changes on top of it: the `UseNewChrome` switch, the partials, loading `gm-chrome.css`/`gm-chrome.js` only when the new chrome is on, and the search Enter fix. The branch's own changes are in the patch in `patches/`; the fixes since are in this repository's history (`git log -p -- Website/Website/Views/Shared/_Layout.cshtml`).
3. Make `_LegacyHeader` and `_LegacyFooter` from the **latest** `_Layout`'s header and footer.
4. Check `MasterLayoutViewModel.cs` the same way.

The new partials, CSS, JavaScript and images can be copied as they are.

## Header and footer

- [ ] Latest-master rebase of `_Layout`, `_LegacyHeader`, `_LegacyFooter` (above).
- [ ] Add `<add key="UseNewChrome" value="false" />` to `Web.config` `<appSettings>`.
- [ ] The **"page not found" page** (e.g. `/this-page-does-not-exist-123`) isn't built from `_Layout.cshtml`: it has its own copy of the old header and footer (no newsletter band, no product search data). Find its view or layout and give it the same switch.
- [ ] Make a fresh patch from the finished branch. `patches/header-and-footer (before 2026-09-17 fixes).patch` is from before the fixes.

## Homepage

- [ ] **`MasterLayoutViewModel`**: add `GetHomeProduct(string productUrl)` and `GetCheapestHomeProduct(string categoryUrl)`, both returning a `HomeProduct` (name, product link, photo URL pattern, lowest customer price, lowest trade price) or `null`. The cheapest one covers a category or subcategory URL and must ignore sample products such as the £25 Sample Box. Check how product photos and trade prices are stored first; the preview's `Get-HomeProduct` / `Get-CheapestHomeProduct` in `preview/tools/build.ps1` show the intended behaviour.
- [ ] **`Views/Home/Index.cshtml`**: when the new chrome is on, render `_HomePage` instead of the old content, pass the existing banners as `ViewData["HomeBanners"]` (a list of `HomeBanner`), and load `/css/gm-home.css` in `@section Head`.
- [ ] **`_Layout.cshtml`**: on the new homepage (and category page, below), render `#mainBody` without the old white box and orange side borders (full width), as the preview does. A small shared helper for "is the new chrome on" would stop the check being repeated.
- [ ] **`Website.csproj`**: add `Views/Home/_HomePage.cshtml`, `ViewModels/Common/HomePageModels.cs`, `css/gm-home.css`, `js/gm-home.js`, the `img/gm-home-*` files, and the shared bulk enquiry pop-up: `Views/Shared/_BulkEnquiryModal.cshtml`, `css/gm-enquiry.css`, `js/gm-enquiry.js`.
- [ ] Test the two posts for real (they're blocked in the preview): "Send me my estimate" (`/email/sendcalculatorcalculation`) and the bulk enquiry (`/basket/sendlooseenquiry`).

## Category page

The live category pages load `/scripts/Controllers/Root/Brand/DisplayCategory.js`, so their view is probably `Views/Brand/DisplayCategory.cshtml`; subcategory and filtered pages may use others. Confirm in the repository.

- [ ] **The category view(s)**: when the new chrome is on, build a `CategoryPageModel` from the view's own data and render `_CategoryPage` in place of the old content, loading `/css/gm-category.css` in `@section Head`. Fill it with exactly what the old view shows today:
  - `Title`: the old `h1` (on some filtered pages that's `MasterLayoutViewModel.GetPageTitle()`, e.g. "Black Gravels & Chippings");
  - `CategoryUrl`: the category's URL name (`garden-chippings`, `slate-chippings`), which picks its promo product;
  - `Breadcrumbs`: a subcategory's parent (with its link), then this page (no link);
  - `Description`: `CategoryDescription.Parse(...)` of the description the old view shows, which may be a filter's own description;
  - `DeliveryMessage`: the old "Order before 12:00PM for next day delivery" text, from wherever the old view gets it;
  - `FilterGroups`: `MasterLayoutViewModel.FilterAttributes`, with each option's link built exactly as the old view builds it (a chosen option's link takes it off), and `Selected` for the chosen ones;
  - `ClearFiltersUrl`: the unfiltered category page when a filter is chosen, otherwise `null`;
  - `SelectedSort`: the posted `sort` value, if it's one of `CategoryPageModel.SortOptions`;
  - `Products`: every product the old grid shows, in its order, as `CategoryProduct` (name, link, photo URL pattern, "From" customer and trade prices, synopsis), as the old tiles show them;
  - `EnquiryCategories`: the top-level category names in menu order.

  The preview's `ConvertFrom-OldCategoryPage` in `preview/tools/category-page.ps1` reads all of these from a live page, so it shows where each comes from on screen.
- [ ] **`_Layout.cshtml`**: render `#mainBody` full width for the new category page too, as for the homepage.
- [ ] **`Website.csproj`**: add `Views/Shared/_CategoryPage.cshtml`, `ViewModels/Common/CategoryPageModels.cs`, `css/gm-category.css`, `js/gm-category.js` and the `img/gm-cat-*` files.
- [ ] Test on the real site: filters (adding, removing, Clear all), Sort by, the phone filter drawer, a trade login (trade prices and the "Trade price" badge), and the bulk enquiry.

## After merging

- [ ] Switch `UseNewChrome` on in a test environment and click through the main page types: home, category, subcategory, filtered category, product, basket, checkout, account, search, content pages and the 404 page.
- [ ] Check with a trade login that trade prices show in the new homepage and category cards.
