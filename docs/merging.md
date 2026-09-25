# Putting it live: what to do in GravelMasterSoftware

Everything here is done in the GravelMasterSoftware repository, cloned to `Documents\Projects\GravelMasterSoftware` on this PC on 23 September 2026. The files in `Website/Website` are at the same paths as in that repository.

## Before anything: which code is live?

Checked on 24 September 2026 (branches as cloned on 23 September): **no branch in the repository matches the live site.**

- `master` still has the old `_Layout.cshtml` (`global.css?v108`, no Tag Manager or Clarity).
- `stripe` has the live `_Layout` (Tag Manager `GTM-KMX9ZL3`, Clarity, `global.css?v210`, WebFont, the newer footer), a different checkout (`ProcessOrderLive.cshtml`; `ProcessOrderOpayo.cshtml` removed) and a Web Deploy profile. It has 12 commits master doesn't; master has 40 it doesn't.
- The live checkout's script (`/scripts/Controllers/Root/Checkout/ProcessOrder.js`, read on 24 September 2026) is newer than every branch's copy, and uses a variable (`thefirstone`) that only `master`'s `ProcessOrder.cshtml` sets: so the live checkout page looks like `master`'s, not `stripe`'s `ProcessOrderLive.cshtml`.
- The live product page has some of master's later changes but not its "spam" commit of 30 July (the hidden `website` field in the calculator's email form), and some lines found only on `stripe`.

So the live site was probably published from a working copy that isn't on GitHub as it stands. **Get the code that is actually deployed pushed to a branch first**, then start the integration from that branch. Until then, the steps below say "master" but mean "the live code".

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

**"When the new chrome is on"**, in the steps for each page below, means `@if (Agilis.ECommerce.Mvc.Web.ViewModels.Common.NewChrome.IsOn(Request))` (or `NewChrome.IsOn(Request)` with the namespace in a `@using`). A view runs before its layout, so it can't read `_Layout`'s own variable; `NewChrome.IsOn` gives the same answer (`?newchrome=1`/`0`, then the `gm-newchrome` cookie, then `UseNewChrome`), and `_Layout` uses it too.

## Header and footer

- [ ] Latest-master rebase of `_Layout`, `_LegacyHeader`, `_LegacyFooter` (above).
- [ ] Add `<add key="UseNewChrome" value="false" />` to `Web.config` `<appSettings>`.
- [ ] Add `ViewModels/Common/NewChrome.cs` to `Website.csproj` (the switch that `_Layout` and the page views share).
- [ ] The **"page not found" page** (e.g. `/this-page-does-not-exist-123`) isn't built from `_Layout.cshtml`: it has its own copy of the old header and footer (no newsletter band, no product search data). Find its view or layout and give it the same switch.
- [ ] Make a fresh patch from the finished branch. `patches/header-and-footer (before 2026-09-17 fixes).patch` is from before the fixes.

## Homepage

- [ ] **`MasterLayoutViewModel`**: add `GetHomeProduct(string productUrl)` and `GetCheapestHomeProduct(string categoryUrl)`, both returning a `HomeProduct` (name, product link, photo URL pattern, lowest customer price, lowest trade price) or `null`. The cheapest one covers a category or subcategory URL and must ignore sample products such as the £25 Sample Box. Check how product photos and trade prices are stored first; the preview's `Get-HomeProduct` / `Get-CheapestHomeProduct` in `preview/tools/build.ps1` show the intended behaviour.
- [ ] **`Views/Home/Index.cshtml`**: when the new chrome is on, render `_HomePage` instead of the old content, pass the existing banners as `ViewData["HomeBanners"]` (a list of `HomeBanner`), and load `/css/gm-home.css` in `@section Head`.
- [ ] **`_Layout.cshtml`**: on the new homepage (and category page, below), render `#mainBody` without the old white box and orange side borders (full width), as the preview does. A small shared helper for "is the new chrome on" would stop the check being repeated.
- [ ] **`Website.csproj`**: add `Views/Home/_HomePage.cshtml`, `ViewModels/Common/HomePageModels.cs`, `css/gm-home.css`, `js/gm-home.js`, the `img/gm-home-*` files, the shared bulk enquiry pop-up (`Views/Shared/_BulkEnquiryModal.cshtml`, `css/gm-enquiry.css`, `js/gm-enquiry.js`) and the shared quantity calculator (`Views/Shared/_QuantityCalculator.cshtml`, `ViewModels/Common/QuantityCalculatorModel.cs`, `css/gm-calc.css`, `js/gm-calc.js`).
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

## Product page

Product addresses (`/products/{category}/p/{product}`) are routed to `ProductController.Detail`, which renders `Views/Product/Detail.cshtml`. The `DetailNew`, `DetailNewVideo` and `Detail2` actions answer other addresses (`/pnew/`, `/pvid/`, `/p2/`) and are left alone.

- [ ] **`Views/Product/Detail.cshtml`**: when the new chrome is on, render `_ProductPage` in place of everything from the breadcrumb to the end of the view (including its inline scripts and pop-ups, and the `view_item` script at the end: the new page sends the analytics events itself). Keep `@section Head` (canonical link, Open Graph tags, TrustBox script) and add `/css/gm-product.css` to it. Build the `ProductPageModel` from the view's own model, exactly as the old view shows it:
  - `Name`, `Code`, `ProductId`, `CategoryName` (`Model.Category.Name`), `AddToBasketUrl` (`Url.Action("AddToBasket", "Basket", new { id = Model.Code })`, which the old `Ajax.BeginForm` used);
  - `Breadcrumbs`: the parent category (if `Category.ParentCategoryId > 0`), the category, then the product with no link, with the old view's links (`/<url>/products`);
  - `Photos`: first `FullLargeGraphicUrl` / `FullLargeZoomGraphicUrl` / `FullGraphicUrl`, then each of `Model.Images` as `FullLargeGraphicUrl` / `FullZoomGraphicUrl` / the 330px file (`string.Format(ConfigurationManager.AppSettings["ImagePathFormat"], "330", image.Filename)`). Not `FullProductGraphicUrl`: it's the 300px file, which many photos don't have (Pebble Glue's and the turf's, for example), so their thumbnails would be blank. Leave out any whose filename contains "youtube" (`ProductImageViewModel` turns those into a video link, which the new gallery doesn't show as a photo);
  - `VideoUrl`: `https://fast.wistia.net/embed/iframe/<id>?videoFoam=true`, with the ids the old view picks by product code (20COTS, 20ICEB, 20FLAM, 20GOLD, 20MOON, 20YORCR, 20ONYX, 10POLAR); `ThreeSixtyUrl`: `https://spinzam.com/shot/embed/?idx=` + `Model.Threed` when it's set;
  - `Price` and `TradePrice`: `Model.Price` and `Model.Cost`; `IsSimple`, `IsInStock` (`Model.IsVisible`), `MinQuantity` (10 when `Model.IsTurf`, else 1);
  - `Options`: the items of the variant whose Type is 11, as the old view loops over them, without the sample: `new ProductOption(id, row["Name"], Model.GetVariantCode(id), decimal.Parse(Model.GetVariantPrice(id)), row["PreOrderDate"] as DateTime?)`; `SelectedOptionId`: `GetDefaultVariantItemId` of that variant;
  - `SampleOption`: `Model.SampleWithHalf` when `Model.HasHalf`, otherwise the item whose name contains "sample", or null;
  - `NextDeliveryDate`: `Model.FastestAvailableDate` when `Model.Calc` is set (the old view only shows it then);
  - `Description`: `ProductDescription.Parse(Model.Description)`;
  - `CalculatorType`: `QuantityCalculatorModel.ForProduct(Model.Calc)` (null, so no calculator, for products the old page showed none on);
  - `Related`: the FeatherSnap Bird Feeder (unless this is it), then `Model.Related`, leaving out this product and repeats, up to four, as `HomeProduct`s (the old view's photo is `FullGraphicUrl`; the image format is that URL with the width as `{0}`);
  - `EnquiryCategories`: the top-level category names in menu order.
- [ ] **`@section requirecontroller`** in `Detail.cshtml`: when the new page shows, require `/scripts/Controllers/Root/Content/Display.js` instead of `Product/Detail.js`. `Detail.js` calls functions that only the old view defines (`calculatePrices`, `onJqueryLoaded`) and would throw. The new page does its jobs (the quantity buttons in the basket pop-up, the postcode).
- [ ] **`_Layout.cshtml`**: render `#mainBody` full width for the new product page too, as for the homepage and category page.
- [ ] **`Website.csproj`**: add `Views/Shared/_ProductPage.cshtml`, `ViewModels/Common/ProductPageModels.cs`, `css/gm-product.css`, `js/gm-product.js` and the `img/gm-prod-*` files.
- [ ] Test on the real site with the new chrome on: add each kind of size to the basket (bulk bag, sealed bags, sample, a pre-order size if there is one), check the basket's lines and delivery prices against the old page for the same postcode, the pop-up for a gravel product and a non-gravel one (the basket answers with `AddToCartComponentGravel.cshtml` or `AddToCartComponent.cshtml`, which the new page reads and restyles; neither file changes), its + and - buttons and its add-ons' "Add", the header's basket total, turf (10 up), glue or bulbs (no postcode), an out-of-stock product, a trade login (trade prices in the sizes and total), and the three analytics events in Google Tag Assistant.

## About us page

`/about-us` is `ContentController`'s `about-us` key, which renders `Views/Content/AboutUs.cshtml`. The new page has no model: its text is written into the partial, as the old page's is.

- [ ] **`Views/Content/AboutUs.cshtml`**: when the new chrome is on, render `@Html.Partial("_AboutPage")` in place of everything after the `@{ ... }` block (the owl-carousel links and script, the page's own `<style>` and all its sections). Keep the `ViewBag.Title` and meta lines. Add a `@section Head` with the Caveat font and the page's stylesheet:
  ```html
  <link href="https://fonts.googleapis.com/css2?family=Caveat:wght@600&display=swap" rel="stylesheet" />
  <link href="/css/gm-about.css?v1" rel="stylesheet" />
  ```
- [ ] **`_Layout.cshtml`**: render `#mainBody` full width for the new About page too, as for the other new pages.
- [ ] **`Website.csproj`**: add `Views/Content/_AboutPage.cshtml`, `css/gm-about.css`, `js/gm-about.js` and the `img/gm-about-*` files. It also uses the homepage's `img/gm-home-insp-*` photos.
- [ ] Test on the real site: the Trustpilot widgets fill in (they load but stay empty in the preview), and "Meet the team" on a phone.

## Trade Accounts page

`/trade` is `ContentController`'s `trade` key, which renders `Views/Content/Trade.cshtml` (after handling a posted reCAPTCHA form, which the live page no longer has). The new page has no model.

- [ ] **`Views/Content/Trade.cshtml`**: when the new chrome is on, render `@Html.Partial("_TradePage")` in place of everything after the `@{ ... }` block (the reCAPTCHA script, the page's `<style>`, its sections and the jQuery scripts at the end). Keep the lines that set `ViewBag.Title` and the meta tags, and the `404-error` status line. Add a `@section Head` with `<link href="/css/gm-trade.css?v1" rel="stylesheet" />`.
- [ ] Give the page a title and description in the admin site: the live page's `<title>` and meta description are empty ([open-questions.md](open-questions.md#trade-accounts-page)).
- [ ] **`_Layout.cshtml`**: render `#mainBody` full width for the new trade page too.
- [ ] **`Website.csproj`**: add `Views/Content/_TradePage.cshtml`, `css/gm-trade.css` and the `img/gm-trade-*` files.
- [ ] Test on the real site: "Open a trade account" and "Get trade prices" open the Trade tab of the sign-up form, and the Trustpilot widgets fill in.

## Basket page

`/basket` is `BasketController.Index`, which renders `Views/Basket/Index.cshtml` with a `BasketViewModel` (its `Cart`, `ShowCoupon` and `PostalArea`).

- [ ] **`Views/Basket/Index.cshtml`**: when the new chrome is on, render `_BasketPage` in place of everything between the `requirecontroller` section and the `analyticscripts` section (the page's `<style>`, its two inline scripts, the basket and the empty message). Keep `@section analyticscripts` (the `view_cart` event) as it is. Add the Caveat font and `/css/gm-basket.css?v1` to `@section head`. Build the `BasketPageModel` from the view's own model, exactly as the old view shows it:
  - `Lines`: one `BasketLine` per `Model.Cart.Items`, **in the cart's order** (the quantities are posted in that order):
    - `Id` = `item.ItemGuid`;
    - `NameHtml` = `item.Product.Name`; `Url` = `Html.GetProductUrl(item.Product.Name, item.Product.Url, item.Product.Category.Url)`;
    - `ImageUrl` = `string.Format(ConfigurationManager.AppSettings["ImagePathFormat"], "330", item.Product.Image1)`;
    - `SizeHtml` = `item.Product.VariantsNameWithoutImage`;
    - `UnitPrice` = `item.Product.Price`; `Quantity` = `item.Quantity`;
    - `CanChangeQuantity` = the code doesn't start with `tt2` or `tt3` (the old view's test);
    - `Discount` = `item.LineDiscountView`; `LinePrice` = `item.LinePrice`; `PreOrderDate` = `item.Product.PreOrderDate`.
  - `ItemCount` = `Model.Cart.NumItems`; `SubTotal` = `Model.Cart.SubTotalExclDiscount`; `Total` = `Model.Cart.Total`.
  - `ShowVoucher` = `Model.ShowCoupon`; `VoucherMessage` = `Model.Cart.CouponMessage`; `PostalArea` = `Model.PostalArea`.
  - `Suggestions`: the old view's four "weekly special offers", with its names, and each size's own price rather than the typed-in one (they matched on 24 September 2026):
    - `EMPTYGM` / `EMPTYGMBBG`, "Empty Waste Bag", picture `/img/800.png` (the product has no photos on the image server);
    - `WM1M` / `WM1M-15`, "1m x 15m Weed Membrane", "per roll", its 330px product photo;
    - `WM2M` / `WM2M-10`, "2m x 10m Weed Membrane", "per roll", its 330px product photo;
    - `PLASPEG` / `PLASPEG10`, "10 Plastic Fixing Pegs", "per set", its 330px product photo.
- [ ] **`@section requirecontroller`**: when the new page shows, require `/scripts/Controllers/Root/Content/Display.js` instead of `Basket/Index.js`, which calls functions only the old view defines (`onJqueryLoaded`, `wcqib_refresh_quantity_increments`) and would throw.
- [ ] **`_Layout.cshtml`**: render `#mainBody` full width for the new basket too.
- [ ] **`Website.csproj`**: add `Views/Basket/_BasketPage.cshtml`, `ViewModels/Common/BasketPageModels.cs`, `css/gm-basket.css` and `js/gm-basket.js`.
- [ ] Test on the real site: + and - on each line (with and without turf in the basket), typing a quantity, Remove, Empty basket, a voucher that works, one that doesn't and one under £40, each add-on, a pre-order size, Checkout, a trade login (trade prices), and the basket total in the header after each change.

## Checkout

`/checkout/processorder` is `CheckoutController.ProcessOrder`, which renders `Views/Checkout/ProcessOrder.cshtml` with an `OrderViewModel` (or sends an empty basket back to `/basket`). The new page follows **master's** checkout, which the live page's script points to ([checkout-page.md](checkout-page.md#which-checkout-is-live)): check that against the live code first.

- [ ] **`Views/Checkout/ProcessOrder.cshtml`**: when the new chrome is on, render `_CheckoutPage` in place of the old page: the inline script (`sectorArray`, `runModal`) and `<style>` above the `requirecontroller` section, and below it the hidden tab `<nav>`, the `fieldInfo` form, the `updateUI` script, the SMS box's `<style>`, the `selectedArea` input and the "Sorry" postcode pop-up, up to the `analyticscripts` section. Keep `@section analyticscripts` (the `begin_checkout` event) as it is. Add `<link href="/css/gm-checkout.css?v1" rel="stylesheet" />` to `@section Head`. Build the model from the view's own model like this (with `@using Agilis.ECommerce.Mvc.Web.ViewModels.Common` at the top). This code was compiled with MVC 5.2's Razor against stand-ins with the repository's class and property names:
  ```cshtml
  @{
      string area = Session["PA"] != null ? Session["PA"].ToString().ToUpper() : null;
      var checkout = new CheckoutPageModel
      {
          Total = Model.Cart.Total,
          IsLoggedIn = User.Identity.IsAuthenticated,
          PostalArea = area,
          StrictPostalArea = !Model.Cart.IsSimple,
          ShowTimes = Model.Prices.DeliveryTimeVisible,
          MorningCost = Model.Prices.DeliveryTimeCost,
          IsMixedPreOrder = Model.Cart.IsMixedPreOrder,
          ShowTradeLink = !(User.Identity.IsAuthenticated && Agilis.ECommerce.Data.TradeRegister.IsTrade(User.Identity.Name)),
          Address = new CheckoutAddress
          {
              Address1 = Model.DefaultAddress.Address1,
              Address2 = Model.DefaultAddress.Address2,
              City = Model.DefaultAddress.City,
              County = Model.DefaultAddress.County,
              Postcode = Model.DefaultAddress.Postcode
          }
      };
      foreach (var item in Model.Cart.Items)
      {
          checkout.Lines.Add(new CheckoutLine
          {
              NameHtml = item.Product.Name,
              SizeHtml = item.Product.VariantsNameWithoutImage,
              ImageUrl = string.Format(System.Configuration.ConfigurationManager.AppSettings["ImagePathFormat"], "330", item.Product.Image1),
              Quantity = item.Quantity,
              LinePrice = item.OrderLinePrice,
              PreOrderDate = item.Product.PreOrderDate
          });
          if (checkout.PreOrderDate == null && item.Product.PreOrderDate.HasValue)
          {
              checkout.PreOrderDate = item.Product.PreOrderDate;
          }
      }
      checkout.Delivery = Model.Cart.IsSamples || Model.Cart.IsBirdFeeder ? CheckoutDelivery.RoyalMail
          : Model.Cart.IsOnlyPreOrder ? CheckoutDelivery.PreOrder
          : Model.Cart.IsSimple ? CheckoutDelivery.NoChoice
          : CheckoutDelivery.ChooseDate;
  
      // The old view's date loop ran for every cart but samples and bird feeders
      var dates = new List<CheckoutDate>();
      if (!Model.Cart.IsSamples && !Model.Cart.IsBirdFeeder)
      {
          dates = CheckoutDates.Build(
              Model.DeliveryDays.Select(d => new KeyValuePair<DateTime, decimal>(d.Day, d.Cost)),
              new CheckoutDateRules
              {
                  PostalArea = area,
                  IsRubber = Model.Cart.IsRubber,
                  IsBulk = Model.Cart.IsBulk,
                  IsTurf = Model.Cart.IsTurf,
                  NextDayCost = Model.Prices.NextDayCost,
                  EcoDayOfMonth = Model.NumDaysTruck,
                  WeekendAllowed = !Model.SpecialAreas.Contains(area ?? "") && Model.Prices.SaturdayVisible
              },
              DateTime.Now);
      }
      if (checkout.Delivery == CheckoutDelivery.ChooseDate)
      {
          checkout.Dates = dates;
      }
      // What the old page posted when there was no date to pick: the first free weekday, else the first day
      var firstFree = dates.FirstOrDefault(d => d.IsDefault);
      checkout.PostedDate = firstFree != null ? firstFree.Day : Model.DeliveryDays[0].Day;
      checkout.PostedDay = checkout.PostedDate.Value.ToString("dd-MM-yy", System.Globalization.CultureInfo.InvariantCulture);
  }
  @Html.Partial("~/Views/Checkout/_CheckoutPage.cshtml", checkout)
  ```
  The date rules in `CheckoutDates.Build` are the old view's loop, moved; they were checked against it on 20,000 random cases ([checkout-page.md](checkout-page.md#tested)).
- [ ] **`@section requirecontroller`**: when the new page shows, require `/scripts/Controllers/Root/Content/Display.js` instead of `Checkout/ProcessOrder.js`, which works the old form's steps, slider and pop-up.
- [ ] **`_Layout.cshtml`**: render `#mainBody` full width for the new checkout too.
- [ ] **`Website.csproj`**: add `Views/Checkout/_CheckoutPage.cshtml`, `ViewModels/Common/CheckoutPageModels.cs`, `css/gm-checkout.css` and `js/gm-checkout.js`.
- [ ] Test on the real site, with test payments: a basket of bulk bags (dates, the next-day charge, a Saturday, the morning slot if the setting is on), turf, samples (Royal Mail), a pre-order size alone and with others, a postcode outside the basket's area, an Isle of Wight postcode, a different billing address, both address finders, a logged-in customer with a saved address, a trade login, and that each order's address, date, time, delivery charge, instructions, SMS choice and trade tick arrive as they did from the old page.
## Order confirmation

`/checkout/orderresult?transId=…` is `CheckoutController.OrderResult`, which marks the order as paid, sends the confirmation emails (once per order), empties the basket and renders `Views/Checkout/OrderResult.cshtml` with an `OrderResultViewModel`. By then `SendEmails` has loaded `Order.DeliveryAddress`.

- [ ] **`Views/Checkout/OrderResult.cshtml`**: when the new chrome is on, render `_ConfirmationPage` in place of the `checkout-thanks` block. Keep `@section Head` (the Bing revenue), `@section analyticscripts` (the purchase event), `@section facebook` and the `trade_order` script after them as they are. Add the Caveat font and `<link href="/css/gm-confirmation.css?v1" rel="stylesheet" />` to `@section Head`. Build the model like this (with `@using Agilis.ECommerce.Mvc.Web.ViewModels.Common` at the top). This code was compiled with MVC 5.2's Razor against stand-ins with the repository's class and property names:
  ```cshtml
  @{
      var delivery = Model.Order.DeliveryAddress;   // SendEmails loads it before the page is drawn
      var confirmation = new ConfirmationPageModel
      {
          OrderNumber = Model.Order.OrderID.ToString(),
          AmountPaid = Model.Order.Amount,
          Email = Model.Order.Email,
          // its lines without the blank ones (an empty second line is saved as a space)
          DeliveryAddress = delivery == null ? null : string.Join(", ", new[] { delivery.Address1, delivery.Address2, delivery.City, delivery.County, delivery.Postcode }
              .Where(line => !string.IsNullOrWhiteSpace(line)).Select(line => line.Trim())),
          DeliveryPostcode = delivery == null ? null : delivery.Postcode,
          PostalArea = Session["PA"] != null ? Session["PA"].ToString() : null
      };
      // "You might also like": the prototype's picks that are on the site. Each size's price is looked up as
      // CheckoutController.CreateProducts looks sizes up; a product or size that's gone is left out.
      var picks = new[]
      {
          new { Name = "FeatherSnap Bird Feeder", Url = "/products/accessories/p/bird-feeder", Code = "Feathsnapparent", Size = "Feathsnap" },
          new { Name = "Large Galvanised Stainless Steel Planter", Url = "/products/accessories/p/large-galvanised", Code = "RSDBED1", Size = "RSDBED" },
          new { Name = "Trowel", Url = "/products/accessories/p/trowel", Code = "TROWEL", Size = "TROWEL1" },
          new { Name = "Gardening Gloves", Url = "/products/accessories/p/gardening-gloves", Code = "GDNGLOVE1", Size = "GDNGLOVE" }
      };
      foreach (var pick in picks)
      {
          var product = Model.ProductRepo.GetProduct(pick.Code);
          var size = Model.ProductRepo.GetProduct(pick.Size);
          if (product == null || size == null) { continue; }
          confirmation.Suggestions.Add(new BasketSuggestion(pick.Name, pick.Url,
              string.Format(System.Configuration.ConfigurationManager.AppSettings["ImagePathFormat"], "330", product.Image1),
              size.Price, null, pick.Code, pick.Size));
      }
  }
  @Html.Partial("~/Views/Checkout/_ConfirmationPage.cshtml", confirmation)
  ```
  Check on the test site that `ProductRepo.GetProduct` gives each size's customer price for the area, as the product pages show it.
- [ ] **`@section requirecontroller`**: nothing to change. The old view has none, so `_Layout` loads `Content/Display.js`, which brings jQuery and Bootstrap for the Track Order pop-up (as in the preview, where "Track your order" opened it).
- [ ] **`_Layout.cshtml`**: render `#mainBody` full width for the new confirmation too.
- [ ] **`Website.csproj`**: add `Views/Checkout/_ConfirmationPage.cshtml`, `ViewModels/Common/ConfirmationPageModels.cs`, `css/gm-confirmation.css`, `js/gm-confirmation.js` and `img/gm-confirm-bag.png`.
- [ ] Test on the real site, with test payments: the order number, amount, email and delivery address after a real order (with and without a second address line, and with a different billing address); "Track your order"; each suggestion's price and Add to basket; reloading the page (no second email); a trade login (the `trade_order` event); and that the purchase events still fire once.
## After merging

- [ ] Switch `UseNewChrome` on in a test environment and click through the main page types: home, category, subcategory, filtered category, product, basket, checkout, order confirmation, account, search, content pages and the 404 page.
- [ ] Check with a trade login that trade prices show in the new homepage and category cards.
