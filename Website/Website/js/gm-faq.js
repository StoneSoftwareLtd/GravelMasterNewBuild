/* GravelMaster FAQ page (Views/Content/_FaqPage.cshtml).
   Shows the search box and filters the questions as you type: a question stays if it, or its answer, has every word
   typed. Topics with nothing left are hidden, and their link beside them too; the counts follow.
   Without this script every question shows and the search box stays hidden. (The topic links need nothing: on phones,
   gm-chrome.js already makes the page's jumps stop below the sticky header.) */
(function () {
  "use strict";
  var page = document.querySelector(".gm-faqpage");
  if (!page) return;

  var box = page.querySelector("[data-faq-search]");
  var input = document.getElementById("faq-search");
  if (!box || !input) return;
  var status = document.getElementById("faq-status");
  var none = page.querySelector(".faq-none");
  var term = page.querySelector("[data-faq-term]");
  var items = [].slice.call(page.querySelectorAll(".faq-topic .inf-faq__item"));
  var words = items.map(function (item) { return item.textContent.toLowerCase().replace(/\s+/g, " "); });
  var topics = [].slice.call(page.querySelectorAll(".faq-topic")).map(function (section) {
    var link = page.querySelector('.faq-topics__link[href="#' + section.id + '"]');
    return {
      section: section,
      items: [].slice.call(section.querySelectorAll(".inf-faq__item")),
      li: link ? link.parentNode : null,
      count: link ? link.querySelector(".faq-topics__count") : null
    };
  });

  function filter() {
    var typed = input.value.trim();
    var wanted = typed.toLowerCase().split(/\s+/).filter(Boolean);
    var shown = 0;
    items.forEach(function (item, i) {
      var match = wanted.every(function (w) { return words[i].indexOf(w) >= 0; });
      item.hidden = !match;
      if (match) shown++;
    });
    topics.forEach(function (t) {
      var n = t.items.filter(function (item) { return !item.hidden; }).length;
      t.section.hidden = n === 0;
      if (t.li) t.li.hidden = n === 0;
      if (t.count) t.count.textContent = n;
    });
    if (none) none.hidden = shown > 0;
    if (term) term.textContent = typed;
    if (status) {
      status.textContent = !wanted.length ? "" :
        shown === 0 ? "No questions match" :
        shown === 1 ? "1 question matches" : shown + " questions match";
    }
  }

  box.hidden = false;
  input.addEventListener("input", filter);
  // the browser may have put back what was typed before (e.g. going back to this page)
  if (input.value) filter();
})();
