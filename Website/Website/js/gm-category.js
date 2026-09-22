/* ===== GravelMaster category page behaviour (Optima design) =====
   Views/Shared/_CategoryPage.cshtml: Sort by, and the phone filter drawer from the Optima prototype's
   category page. "Read more" and the filter groups are <details>, so they need no script.
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */

/* Sort by: send the choice as soon as it changes, as the old page did. requestSubmit() (where the browser
   has it) runs the form's submit handlers, as pressing a submit button would. */
(function () {
  document.querySelectorAll('.gm-category select[data-sort-select]').forEach(function (select) {
    select.addEventListener('change', function () {
      if (select.form.requestSubmit) select.form.requestSubmit();
      else select.form.submit();
    });
  });
})();

/* Keep --hdr-h in step with the header, so the phone filter bar sticks just below it */
(function () {
  var page = document.querySelector('.gm-category');
  var header = document.querySelector('.site-header');
  if (!page || !header) return;
  function set() { page.style.setProperty('--hdr-h', header.offsetHeight + 'px'); }
  set();
  if (window.ResizeObserver) new ResizeObserver(set).observe(header);
  else window.addEventListener('resize', set);
})();

/* Phone filter drawer */
(function () {
  var wrap = document.getElementById('plp-filters');
  var button = document.querySelector('.gm-category .plp-filterbtn');
  var backdrop = document.querySelector('.gm-category .plp-filter-backdrop');
  if (!wrap || !button || !backdrop) return;
  var closeButton = wrap.querySelector('.plp-filterwrap__close');
  var applyButton = wrap.querySelector('.plp-filterwrap__apply');
  var hideTimer;

  function isOpen() { return wrap.classList.contains('is-open'); }

  function open() {
    clearTimeout(hideTimer);
    wrap.classList.add('is-open');
    wrap.setAttribute('role', 'dialog');
    wrap.setAttribute('aria-modal', 'true');
    backdrop.hidden = false;
    requestAnimationFrame(function () { backdrop.classList.add('is-open'); });
    button.setAttribute('aria-expanded', 'true');
    document.body.style.overflow = 'hidden';
    // move keyboard focus into the drawer (it becomes visible straight away, see gm-category.css)
    if (closeButton) closeButton.focus();
  }

  function close() {
    if (!isOpen()) return;
    var hadFocus = wrap.contains(document.activeElement);
    wrap.classList.remove('is-open');
    wrap.removeAttribute('role');
    wrap.removeAttribute('aria-modal');
    backdrop.classList.remove('is-open');
    button.setAttribute('aria-expanded', 'false');
    document.body.style.overflow = '';
    // hand focus back to the Filters button
    if (hadFocus) button.focus();
    // hide the backdrop after its fade-out
    hideTimer = setTimeout(function () { if (!isOpen()) backdrop.hidden = true; }, 300);
  }

  button.addEventListener('click', open);
  backdrop.addEventListener('click', close);
  if (closeButton) closeButton.addEventListener('click', close);
  if (applyButton) applyButton.addEventListener('click', close);
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });

  // Keep Tab inside the open drawer: it covers the page, so focus shouldn't move behind it
  wrap.addEventListener('keydown', function (e) {
    if (e.key !== 'Tab' || !isOpen()) return;
    var items = Array.prototype.filter.call(wrap.querySelectorAll('a[href], button, summary'), function (el) {
      return el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    });
    if (!items.length) return;
    var first = items[0];
    var last = items[items.length - 1];
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  });

  // Widening past phone size turns the drawer back into the sidebar, so close it
  var wide = window.matchMedia('(min-width: 861px)');
  function onWide(e) { if (e.matches) close(); }
  if (wide.addEventListener) wide.addEventListener('change', onWide);
  else if (wide.addListener) wide.addListener(onWide);
})();
