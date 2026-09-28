/* GravelMaster privacy and terms pages (Views/Content/_LegalPage.cshtml).
   When the admin site's content has three or more <h2> headings, lists them under "On this page": beside the words on
   a computer, where it stays in view and marks the section being read, and on a phone as a list that opens and
   closes, under the title. Headings without an id are given one from their words. Without headings, or without this script, the
   page is the words alone. */
(function () {
  "use strict";
  var page = document.querySelector(".gm-legal");
  if (!page) return;
  var box = page.querySelector(".leg-contents");
  var list = page.querySelector(".leg-contents__list");
  var heads = [].slice.call(page.querySelectorAll(".leg-body h2"));
  if (!box || !list || heads.length < 3) return;

  heads.forEach(function (h) {
    if (!h.id) {
      var slug = h.textContent.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "section";
      var id = slug, n = 2;
      while (document.getElementById(id)) id = slug + "-" + n++;
      h.id = id;
    }
    var li = document.createElement("li");
    var a = document.createElement("a");
    a.href = "#" + h.id;
    a.textContent = h.textContent.replace(/\s+/g, " ").trim();
    li.appendChild(a);
    list.appendChild(li);
  });
  var links = [].slice.call(list.querySelectorAll("a"));
  box.hidden = false;
  page.querySelector(".leg-layout").classList.add("leg-layout--contents");

  // open beside the words on a computer; on a phone, closed and under the title (the admin content's own <h1>)
  var wide = window.matchMedia("(min-width: 861px)");
  var layout = page.querySelector(".leg-layout");
  var body = page.querySelector(".leg-body");
  var title = body.querySelector("h1");
  function fit() {
    box.open = wide.matches;
    if (wide.matches) { if (box.parentNode !== layout) layout.insertBefore(box, body); }
    else if (title && title.nextElementSibling !== box) title.parentNode.insertBefore(box, title.nextSibling);
  }
  fit();
  if (wide.addEventListener) wide.addEventListener("change", fit); else if (wide.addListener) wide.addListener(fit);
  list.addEventListener("click", function (e) {
    if (!wide.matches && e.target.closest && e.target.closest("a")) box.open = false;
  });

  // mark the section being read: the last heading near the top of the screen (below the header, which sticks on
  // phones: gm-chrome.js gives the page room for it), or the last one once the page is scrolled to the end
  var ticking = false;
  function mark() {
    ticking = false;
    var root = document.documentElement;
    var line = (parseFloat(getComputedStyle(root).scrollPaddingTop) || 0) + 80;
    var current = 0;
    heads.forEach(function (h, i) { if (h.getBoundingClientRect().top <= line) current = i; });
    if (window.innerHeight + window.pageYOffset >= root.scrollHeight - 2) current = heads.length - 1;
    links.forEach(function (a, i) {
      if (i === current) a.setAttribute("aria-current", "location"); else a.removeAttribute("aria-current");
    });
  }
  window.addEventListener("scroll", function () {
    if (!ticking) { ticking = true; window.requestAnimationFrame(mark); }
  }, { passive: true });
  mark();
})();
