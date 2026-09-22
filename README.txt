GravelMaster website - new header and footer (code)
===================================================

These are all the files added or changed for the new Optima header, footer and
mobile menu, taken from git branch "new-chrome" and compared with "master".
The folders match the layout of the GravelMasterSoftware-master repository.

Commits on the branch (oldest first)
  7463d6c  Move order-tracking modal into _TrackOrderModal partial
  d7df58c  Add gm-chrome.css for the new header and footer
  60f461d  Add new header, footer and mobile-menu partials
  e3385ef  Swap _Layout to the new chrome behind UseNewChrome
  059c57f  Match the prototype's text and image alignment in gm-chrome.css
  f4d6839  Keep live-domain links on localhost during local preview
  54b3d01  Remove the Trustpilot widget from the new header
  75c73d1  Fill the mega menus with real category content

New files
  Website/Website/Views/Shared/_SiteHeader.cshtml      new header
  Website/Website/Views/Shared/_SiteFooter.cshtml      new footer
  Website/Website/Views/Shared/_SiteMobileMenu.cshtml  slide-in phone menu
  Website/Website/Views/Shared/_LegacyHeader.cshtml    old header, unchanged, moved out of _Layout
  Website/Website/Views/Shared/_LegacyFooter.cshtml    old footer, unchanged, moved out of _Layout
  Website/Website/Views/Shared/_TrackOrderModal.cshtml Track Order pop-up, used by both
  Website/Website/css/gm-chrome.css                    styles for the new design
  Website/Website/js/gm-chrome.js                      phone menu, footer carousel, basket total
  Website/Website/img/gm-*.png, gm-*.jpg               logos, photo and payment cards

Changed files
  Website/Website/Views/Shared/_Layout.cshtml          switches between old and new header/footer
  Website/Website/ViewModels/Common/MasterLayoutViewModel.cs
                                                       BasketTotal and mega-menu helpers
  Website/Website/Website.csproj                       lists the new files

Also included
  header-and-footer (before 2026-09-17 fixes).patch - the branch's changes as a
  git patch, from BEFORE the fixes below. Don't apply it on its own: the files
  in this folder are the up-to-date versions. Make a new patch after the fixes
  are committed.

NOT included
  Website/Website/Web.config, because it contains the live database password.
  The only change to it is one new setting inside <appSettings>:

      <add key="UseNewChrome" value="false" />

  "false" keeps the old header and footer; "true" shows the new ones. While
  testing, adding ?newchrome=1 or ?newchrome=0 to any page address overrides
  the setting for that browser.

Building
  MasterLayoutViewModel.cs is C#, so rebuild the Website project after copying
  the files. Views, CSS, JavaScript and images need no build.

BEFORE MERGING: the live site has moved on from this branch's master
  Checked against www.gravelmaster.co.uk on 17 September 2026. The live pages
  are built from a newer _Layout.cshtml than the one this branch changed. The
  live one has things this copy doesn't:
    - Google Tag Manager (GTM-KMX9ZL3) and Microsoft Clarity (skcynpme2d)
    - global.css?v210 (this copy has ?v108)
    - WebFont.load for Montserrat and Quicksand 400/500/700
    - a different old footer: "Find Out About Our Latest Products & Offers",
      an orange Ideas | About | Contact | Trade link bar, and the logo at
      /cdn/logo-comp.jpg
  Copying this _Layout.cshtml, _LegacyHeader.cshtml or _LegacyFooter.cshtml
  over the live code would remove those. Take the latest master first and
  redo the _Layout changes on top of it (the new partials, CSS, JS and images
  can be copied as they are). MasterLayoutViewModel.cs may need the same check.

  The "page not found" page (e.g. /this-page-does-not-exist-123) is not built
  from _Layout.cshtml: it has its own copy of the old header and footer (no
  newsletter band, no product search data). With UseNewChrome on it would
  still show the old header and footer. Find its view or layout in the repo
  and give it the same switch.

New homepage (in progress, 17 September 2026)
  The Optima prototype's homepage, built to take the site's real data. Not
  wired into the site yet: that needs the latest master (see "BEFORE MERGING").

  Done
  Website/Website/Views/Home/_HomePage.cshtml  the new homepage (partial)
  Website/Website/css/gm-home.css             its styles, scoped to .gm-home
  Website/Website/js/gm-home.js               carousels, tabs, calculator, enquiry
  Website/Website/ViewModels/Common/HomePageModels.cs  HomeBanner, HomeProduct
  Website/Website/img/gm-home-*               backgrounds and gallery photos

  What it keeps from the live site
  - hero slides: the banners managed in the admin site
  - offer and bestseller cards: product photos and customer/trade "From"
    prices from the product data (the old homepage had them typed in, and
    some had drifted, e.g. Panda Gravel's trade price showed GBP 106, not 100)
  - quantity calculator: the live /calculator formulas for gravel, barks &
    mulches, topsoil and sand, and its Email Results post
    (/email/sendcalculatorcalculation); checked against the live code on 24
    measurements
  - "Enquire Here": the product page quick enquiry's fields posted to
    /basket/sendlooseenquiry
  - reviews: the real Trustpilot widgets; trade sign-up and page links
  - old homepage tiles (Deals, Cotswold, Scottish Cobbles, Top Soil) and the
    10-tonne phone band are folded into the offers and calculator sections

  Still to do, needs the repo
  - MasterLayoutViewModel: GetHomeProduct(productUrl) and
    GetCheapestHomeProduct(categoryUrl) returning HomeProduct (price, trade
    price, photo), ignoring sample products such as the GBP 25 Sample Box
  - Home/Index.cshtml: show _HomePage when the new chrome is on, pass the
    existing banners as ViewData["HomeBanners"], load gm-home.css in the Head
    section
  - _Layout.cshtml: no white box / orange borders around the new homepage
  - Website.csproj: list the new files

Fixes made on 17 September 2026 (one commit each in this repository)
  Each fix was tested in a static preview built from these files, sitting on
  the live site's stylesheets and a real category page, at 1440, 1100, 1000,
  900, 861, 768 and 375px wide. The layout measured the same before and after.

  1. Search: pressing Enter didn't search
     Views/Shared/_Layout.cshtml - autocomplete() blocked Enter even with no
     suggestion highlighted, so the form never submitted. Enter now searches,
     and Enter on a highlighted suggestion still opens that product. (The old
     header uses the same function, so the live site has this bug too.)

  2. gm-chrome.css no longer affects pages outside the new chrome
     css/gm-chrome.css - the colour variables were set on :root, replacing
     Bootstrap's --green, --blue, --red etc. for the whole page. They are now
     set on the chrome elements only.
     Views/Shared/_Layout.cshtml - gm-chrome.css is only loaded when the new
     chrome is on, so with UseNewChrome off the site is unchanged.
     The css and js links went from ?v1 to ?v2 so browsers fetch the new files.

  3. Mobile menu: keyboard access
     css/gm-chrome.css, js/gm-chrome.js - while closed, the menu's 31 links and
     buttons could still be tabbed to, even though they were off-screen, and so
     could the links in collapsed categories. They are now hidden until shown.
     Opening the menu moves focus to its close button, Tab stays inside the
     open menu, and closing it returns focus to the menu button.

  4. Images
     img/gm-payment-cards.png - was 1486x242 (125 KB) for a 215x35 display;
     now 645x105 (42 KB), which is still sharp on high-resolution screens.
     Views/Shared/_SiteHeader.cshtml, _SiteFooter.cshtml - every image now has
     width and height so the page doesn't jump as images load, and the footer
     images use loading="lazy".

  5. Mega menu reads the product list once per page
     ViewModels/Common/MasterLayoutViewModel.cs - GetMenuProducts called
     productRepository.GetAllProducts() for every category and subcategory
     (12 times per page with today's menu). It now loads the list once and
     filters it. A test comparing the old and new method on 17,500 random
     cases gave identical results in the same order.
