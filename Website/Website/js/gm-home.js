/* ===== GravelMaster homepage behaviour (Optima design) =====
   Carousels, tabs and the bulk enquiry modal from the Optima prototype (hero.js and home.html's inline
   scripts), wired to the live site's features:
   - the quantity calculator uses the formulas of the live /calculator page, and "Send me my estimate"
     posts to /email/sendcalculatorcalculation like its Email Results button;
   - the bulk enquiry form posts the same fields as the product page's quick enquiry (#miniForm) to
     /basket/sendlooseenquiry.
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

/* Coloured <select>s: the chosen option's category colour */
(function () {
  document.querySelectorAll('.gm-home select[data-colour-select]').forEach(function (sel) {
    function apply() {
      var opt = sel.options[sel.selectedIndex];
      sel.style.color = (opt && opt.getAttribute('data-color')) || '';
    }
    sel.addEventListener('change', apply);
    apply();
  });
})();

/* Quantity calculator - the live /calculator page's formulas, one per product type */
(function () {
  var root = document.querySelector('.gm-home [data-calc]');
  if (!root) return;

  var form     = root.querySelector('.calc__form');
  var type     = root.querySelector('#calc-type');
  var total    = root.querySelector('[data-calc-total]');
  var totalLbl = root.querySelector('[data-calc-total-label]');
  var first    = root.querySelector('[data-calc-first]');
  var or       = root.querySelector('.calc__or');
  var second   = root.querySelector('[data-calc-second]');
  var estimate = root.querySelector('.calc__estimate');
  var emailBox = root.querySelector('.calc__email');
  var status   = root.querySelector('.calc__email-status');
  var last     = null;

  function toMetres(value, unit) {
    return unit === 'f' ? value * 0.3048 : unit === 'y' ? value * 0.9144 : value;
  }
  function ceilFixed(n, places) { return Math.ceil(Number(n.toFixed(places))); }
  function number(n, places) { return Number(n.toFixed(places)).toLocaleString('en-GB'); }

  // Each returns what to show plus the values the Email Results button sends.
  var types = {
    // Gravel & Chippings: 1.7 tonnes per m3
    gravel: function (area, depth, depthUnit) {
      var m3 = depthUnit === 'in' ? area * depth * 0.0254 : area * depth / 100;
      var tonnes = m3 * 1.7;
      var bulk = ceilFixed(tonnes * 1000 / 800, 3);
      var pallets = ceilFixed(tonnes, 2);
      return {
        totalLabel: 'Total weight', total: number(tonnes * 1000, 0) + 'kg',
        first: ['1 Tonne Pallet (50 x 20kg)', pallets], second: ['Bulk Bag (850kg)', bulk],
        email: { quantity: (tonnes * 1000).toFixed(1) + ' Kg', bags: bulk, pallets: pallets }
      };
    },
    // Barks & Mulches: 350kg per m3, 1m3 bulk bags
    mulch: function (area, depth, depthUnit) {
      var m3 = (depthUnit === 'in' ? area * depth * 25.4 : area * depth * 10) / 1000;
      var kg = m3 * 350;
      var bulk = Math.ceil(m3);
      return {
        totalLabel: 'Total volume', total: number(m3, 1) + 'm³',
        first: ['Bulk Bag (1m³)', bulk], second: null,
        email: { quantity: kg.toFixed(1) + ' Kg', bags: bulk, pallets: '' }
      };
    },
    // Topsoil: 1.5 tonnes per m3
    topsoil: function (area, depth, depthUnit) {
      var m3 = depthUnit === 'in' ? area * depth * 0.0254 : area * depth / 100;
      var tonnes = m3 * 1.5;
      var bulk = Math.ceil(tonnes);
      var pallets = Math.ceil(tonnes * 1000 / 1400);
      return {
        totalLabel: 'Total weight', total: number(tonnes, 1) + ' tonnes',
        first: ['Pre Packed Pallets (56 x 25L)', pallets], second: ['Bulk Bag (850L)', bulk],
        email: { quantity: tonnes.toFixed(1) + ' Tonnes', bags: bulk, pallets: pallets }
      };
    },
    // Sand: as the live calculator (m3 / 0.0015 kg, one bag or pallet per m3)
    sand: function (area, depth, depthUnit) {
      var m3 = (depthUnit === 'in' ? area * depth * 25.4 : area * depth * 10) / 1000;
      var kg = m3 / 0.0015;
      var bulk = Math.ceil(m3);
      return {
        totalLabel: 'Total weight', total: number(kg, 0) + 'kg',
        first: ['Pre Packed Pallets (49 x 20kg)', bulk], second: ['Bulk Bag (850kg)', bulk],
        email: { quantity: kg.toFixed(1) + ' Kg', bags: bulk, pallets: bulk }
      };
    }
  };

  function setResult(el, pair) {
    el.hidden = !pair;
    if (!pair) return;
    el.querySelector('.result__label').textContent = pair[0];
    el.querySelector('.result__count').textContent = pair[1];
  }

  function field(name) { return form.querySelector('[name="' + name + '"]'); }

  function calculate() {
    var len   = parseFloat(field('calc-length').value);
    var wid   = parseFloat(field('calc-width').value);
    var depth = parseFloat(field('calc-depth').value);
    var unit  = field('calc-measure').value;
    if (!(len > 0) || !(wid > 0) || !(depth > 0)) {
      last = null;
      total.textContent = '–';
      setResult(first, null);
      setResult(second, null);
      or.hidden = true;
      estimate.hidden = true;
      emailBox.hidden = true;
      return;
    }
    var area = toMetres(len, unit) * toMetres(wid, unit);
    last = types[type.value](area, depth, field('calc-depth-unit').value);
    totalLbl.textContent = last.totalLabel;
    total.textContent = last.total;
    setResult(first, last.first);
    setResult(second, last.second);
    or.hidden = !last.second;
    estimate.hidden = false;
    status.textContent = '';
  }

  form.addEventListener('submit', function (e) { e.preventDefault(); calculate(); });
  type.addEventListener('change', calculate);
  calculate();   // the example values in the form

  estimate.addEventListener('click', function () {
    emailBox.hidden = !emailBox.hidden;
    if (!emailBox.hidden) emailBox.querySelector('input').focus();
  });

  emailBox.addEventListener('submit', function (e) {
    e.preventDefault();
    if (!last) return;
    var input = emailBox.querySelector('input');
    if (!input.checkValidity()) { input.reportValidity(); return; }
    var button = emailBox.querySelector('button');
    button.disabled = true;
    status.textContent = 'Sending…';
    fetch('/email/sendcalculatorcalculation', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
      body: new URLSearchParams({ email: input.value, quantity: last.email.quantity, bags: last.email.bags, pallets: last.email.pallets })
    }).then(function (res) {
      if (!res.ok) throw new Error(res.status);
      status.textContent = 'Sent - check your inbox for your estimate.';
      input.value = '';
    }).catch(function () {
      status.textContent = 'Sorry, that didn’t send. Please try again or call 0330 058 5068.';
    }).then(function () {
      button.disabled = false;
    });
  });
})();

/* Bulk delivery enquiry modal */
(function () {
  var modal = document.querySelector('.gm-home #bulkModal');
  if (!modal) return;
  var form   = modal.querySelector('.bulk-form');
  var status = modal.querySelector('.bulk-form__status');
  var opener = null;

  function open(e) {
    if (e) e.preventDefault();
    opener = document.activeElement;
    modal.hidden = false;
    document.body.style.overflow = 'hidden';
    modal.querySelector('input, select').focus();
  }
  function close() {
    modal.hidden = true;
    document.body.style.overflow = '';
    if (opener && opener.focus) opener.focus();
  }

  document.querySelectorAll('.gm-home [data-bulk-open]').forEach(function (btn) {
    btn.addEventListener('click', open);
  });
  modal.querySelectorAll('[data-bulk-close]').forEach(function (el) {
    el.addEventListener('click', close);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !modal.hidden) close();
  });

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    if (!form.checkValidity()) { form.reportValidity(); return; }
    var button = form.querySelector('.bulk-form__submit');
    button.disabled = true;
    status.hidden = false;
    status.textContent = 'Sending…';
    // Same fields as the product page's quick enquiry (#miniForm); the consent box isn't sent.
    var data = new URLSearchParams();
    ['name-request', 'email-request', 'postcode-request', 'product', 'amount'].forEach(function (name) {
      data.append(name, form.querySelector('[name="' + name + '"]').value);
    });
    fetch('/basket/sendlooseenquiry', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
      body: data
    }).then(function (res) {
      if (!res.ok) throw new Error(res.status);
      status.textContent = 'Thank you - our team will be in touch with your delivery quote.';
      form.reset();
    }).catch(function () {
      status.textContent = 'Sorry, that didn’t send. Please try again or call 0330 058 5068.';
    }).then(function () {
      button.disabled = false;
    });
  });
})();
