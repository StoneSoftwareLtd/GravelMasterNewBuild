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
  header-and-footer.patch - the same changes as a git patch. To apply it, run
  this from the repository root on a branch taken from master:
      git apply header-and-footer.patch

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
