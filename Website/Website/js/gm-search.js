/* GravelMaster search results page (Views/Category/_SearchPage.cshtml).
   Puts what was searched for back into the header's search box (and the mobile menu's), so it can be changed and
   searched again. Loaded with defer, so the mobile menu, which comes after the page, is there too. */
(function () {
  "use strict";
  var page = document.querySelector(".gm-search");
  var phrase = page ? page.getAttribute("data-search-phrase") : "";
  if (!phrase) return;
  ["myInput", "myInput2"].forEach(function (id) {
    var box = document.getElementById(id);
    // left alone if the browser has already put something back in it (e.g. going back to this page)
    if (box && !box.value) box.value = phrase;
  });
})();
