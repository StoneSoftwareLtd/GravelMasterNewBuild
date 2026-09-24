/* ===== GravelMaster homepage behaviour (Optima design) =====
   Carousels and tabs from the Optima prototype (hero.js and home.html's inline scripts). The quantity
   calculator (js/gm-calc.js) and the bulk enquiry pop-up (js/gm-enquiry.js) are shared with other pages.
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */

/* Hero carousel */
(function () {
  var root = document.querySelector('.gm-home [data-carousel]');
  if (!root) return;

  var track  = root.querySelector('.carousel__track');
  var slides = root.querySelectorAll('.carousel__slide');
  var dots   = root.querySelectorAll('.carousel__dot');
  var prev   = root.querySelector('.carousel__arrow--prev');
  var next   = root.querySelector('.carousel__arrow--next');
  var count  = slides.length;
  var index  = 0;
  var timer;

  if (count < 2) {
    // Nothing to rotate through - hide the controls.
    if (prev) prev.style.display = 'none';
    if (next) next.style.display = 'none';
    return;
  }

  function go(i) {
    index = (i + count) % count;
    track.style.transform = 'translateX(-' + (index * 100) + '%)';
    for (var d = 0; d < dots.length; d++) {
      dots[d].classList.toggle('is-active', d === index);
    }
    // only the visible slide's link can be tabbed to
    for (var s = 0; s < slides.length; s++) {
      if (s === index) slides[s].removeAttribute('tabindex'); else slides[s].setAttribute('tabindex', '-1');
      slides[s].setAttribute('aria-hidden', s === index ? 'false' : 'true');
    }
  }

  function start() { stop(); timer = setInterval(function () { go(index + 1); }, 5000); }
  function stop()  { clearInterval(timer); }

  if (next) next.addEventListener('click', function () { go(index + 1); start(); });
  if (prev) prev.addEventListener('click', function () { go(index - 1); start(); });

  for (var d = 0; d < dots.length; d++) {
    (function (i) {
      dots[i].addEventListener('click', function () { go(i); start(); });
    })(d);
  }

  // Pause while the pointer or keyboard focus is on it, so it doesn't move while being read.
  root.addEventListener('mouseenter', stop);
  root.addEventListener('mouseleave', start);
  root.addEventListener('focusin', stop);
  root.addEventListener('focusout', start);

  // The first banner loads straight away; the rest (about 1MB each) wait until the page has loaded.
  window.addEventListener('load', function () {
    root.querySelectorAll('img[loading="lazy"]').forEach(function (img) { img.loading = 'eager'; });
  });

  go(0);
  start();
})();

/* Offers and Inspiration Gallery sliders */
(function () {
  function slider(viewportSelector, itemSelector, prevSelector, nextSelector, onApply) {
    var vp = document.querySelector(viewportSelector);
    if (!vp) return;
    var track = vp.firstElementChild;
    var prev  = document.querySelector(prevSelector);
    var next  = document.querySelector(nextSelector);
    var pos = 0;

    function step() {
      var item = track.querySelector(itemSelector);
      if (!item) return 0;
      var s = getComputedStyle(track);
      var gap = parseFloat(s.columnGap || s.gap) || 0;
      return item.getBoundingClientRect().width + gap;
    }
    function maxPos() { return Math.max(0, track.scrollWidth - vp.clientWidth); }
    function apply() {
      var m = maxPos();
      pos = Math.max(0, Math.min(pos, m));
      track.style.transform = 'translateX(-' + pos + 'px)';
      if (prev) prev.disabled = pos <= 0;
      if (next) next.disabled = pos >= m - 1;
      if (onApply) onApply(pos, m);
    }

    if (next) next.addEventListener('click', function () { pos += step(); apply(); });
    if (prev) prev.addEventListener('click', function () { pos -= step(); apply(); });
    // re-measure whenever the slider's size changes (window resize, fonts loading, the mobile layout
    // switching on or off), so the arrows are never left disabled from an earlier layout
    if (window.ResizeObserver) {
      var observer = new ResizeObserver(apply);
      observer.observe(vp);
      observer.observe(track);
    } else {
      window.addEventListener('resize', apply);
    }
    // keep a tabbed-to card in view
    track.addEventListener('focusin', function (e) {
      var item = e.target.closest(itemSelector);
      if (!item) return;
      vp.scrollLeft = 0;   // the browser may scroll the viewport itself to reach the focused card
      pos = item.getBoundingClientRect().left - track.getBoundingClientRect().left;
      apply();
    });
    apply();
  }

  slider('.gm-home [data-offers]', '.card', '.gm-home [data-offers-prev]', '.gm-home [data-offers-next]');

  var fill = document.querySelector('.gm-home [data-insta-progress]');
  slider('.gm-home [data-insta]', '.insta__col', '.gm-home [data-insta-prev]', '.gm-home [data-insta-next]', function (pos, m) {
    if (fill) fill.style.width = (m > 0 ? (pos / m) * 75 + 25 : 100) + '%';
  });
})();

/* Our Bestsellers tabs */
(function () {
  var tabs = Array.prototype.slice.call(document.querySelectorAll('.gm-home .bs-tab[aria-controls]'));
  if (!tabs.length) return;

  function select(tab) {
    tabs.forEach(function (t) {
      var on = t === tab;
      t.classList.toggle('bs-tab--active', on);
      t.setAttribute('aria-selected', on ? 'true' : 'false');
      t.tabIndex = on ? 0 : -1;
      var panel = document.getElementById(t.getAttribute('aria-controls'));
      if (panel) panel.hidden = !on;
    });
  }

  tabs.forEach(function (tab, i) {
    tab.addEventListener('click', function () { select(tab); });
    tab.addEventListener('keydown', function (e) {
      var to = e.key === 'ArrowRight' ? i + 1 : e.key === 'ArrowLeft' ? i - 1 : null;
      if (to === null) return;
      e.preventDefault();
      var t = tabs[(to + tabs.length) % tabs.length];
      select(t);
      t.focus();
    });
  });
})();
