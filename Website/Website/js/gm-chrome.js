/* ===== GravelMaster header, footer and mobile menu behaviour =====
   menu.js and foot-features.js from the Optima prototype, plus the live basket
   total and the Track Order pop-up. Loaded at the end of <body> only when _Layout
   renders the new chrome. */

/* Slide-in mobile menu */
(function () {
  var toggle   = document.querySelector('.menu-toggle');
  var menu     = document.getElementById('mobile-menu');
  var backdrop = document.querySelector('.menu-backdrop');
  var closeBtn = document.querySelector('.mobile-menu__close');

  if (!toggle || !menu || !backdrop) return;

  function openMenu() {
    menu.classList.add('is-open');
    backdrop.hidden = false;
    // next frame so the transition runs
    requestAnimationFrame(function () { backdrop.classList.add('is-open'); });
    toggle.classList.add('is-active');
    toggle.setAttribute('aria-expanded', 'true');
    menu.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
    // move keyboard focus into the menu (it becomes visible straight away, see gm-chrome.css)
    if (closeBtn) closeBtn.focus();
  }

  function closeMenu() {
    var hadFocus = menu.contains(document.activeElement);
    // collapse any expanded category submenus
    menu.querySelectorAll('.mobile-menu__item.is-open').forEach(function (item) {
      item.classList.remove('is-open');
      var b = item.querySelector('.mobile-menu__toggle');
      if (b) b.setAttribute('aria-expanded', 'false');
    });
    menu.classList.remove('is-open');
    backdrop.classList.remove('is-open');
    toggle.classList.remove('is-active');
    toggle.setAttribute('aria-expanded', 'false');
    menu.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
    // hand focus back to the button that opened the menu
    if (hadFocus) toggle.focus();
    // hide backdrop after the fade-out
    setTimeout(function () {
      if (!menu.classList.contains('is-open')) backdrop.hidden = true;
    }, 300);
  }

  toggle.addEventListener('click', function () {
    menu.classList.contains('is-open') ? closeMenu() : openMenu();
  });
  backdrop.addEventListener('click', closeMenu);
  if (closeBtn) closeBtn.addEventListener('click', closeMenu);

  // Close on Escape
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && menu.classList.contains('is-open')) closeMenu();
  });

  // Keep Tab inside the open menu: it covers the whole page, so focus shouldn't move behind it
  menu.addEventListener('keydown', function (e) {
    if (e.key !== 'Tab') return;
    var items = Array.prototype.filter.call(menu.querySelectorAll('a[href], button, input'), function (el) {
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

  // Close when a menu link is tapped
  menu.querySelectorAll('a').forEach(function (link) {
    link.addEventListener('click', closeMenu);
  });

  // Expand / collapse category submenus (accordion)
  menu.querySelectorAll('.mobile-menu__toggle').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var item = btn.parentNode;
      var isOpen = item.classList.toggle('is-open');
      btn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    });
  });
})();

/* Footer feature band: swipe carousel controls on narrow screens */
(function () {
  var grid = document.querySelector('.foot-features__grid');
  if (!grid) return;
  var band = grid.parentNode;

  var controls = document.createElement('div');
  controls.className = 'foot-features__controls';
  controls.setAttribute('aria-hidden', 'true');

  var progress = document.createElement('div');
  progress.className = 'foot-features__progress';
  var fill = document.createElement('span');
  fill.className = 'foot-features__progress-fill';
  progress.appendChild(fill);

  var next = document.createElement('button');
  next.type = 'button';
  next.className = 'foot-features__arrow';
  next.setAttribute('aria-label', 'Next');
  next.innerHTML = '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="13 6 19 12 13 18"/></svg>';

  controls.appendChild(progress);
  controls.appendChild(next);
  band.appendChild(controls);

  function step() {
    var card = grid.querySelector('.foot-feature');
    var s = getComputedStyle(grid);
    var gap = parseFloat(s.columnGap || s.gap) || 0;
    return card ? card.getBoundingClientRect().width + gap : grid.clientWidth;
  }
  function update() {
    var max = grid.scrollWidth - grid.clientWidth;
    var pct = max > 2 ? (grid.scrollLeft / max) * 100 : 100;
    fill.style.width = Math.max(14, pct) + '%';
  }

  next.addEventListener('click', function () {
    var max = grid.scrollWidth - grid.clientWidth;
    if (grid.scrollLeft >= max - 2) {
      grid.scrollTo({ left: 0, behavior: 'smooth' });
    } else {
      grid.scrollBy({ left: step(), behavior: 'smooth' });
    }
  });
  grid.addEventListener('scroll', update);
  window.addEventListener('resize', update);
  update();
})();

/* Basket total: page scripts write "N Items: £X" into the hidden #numItems
   after basket changes; mirror the total into the header's basket label. */
(function () {
  var source = document.getElementById('numItems');
  var targets = document.querySelectorAll('.js-basket-total');
  if (!source || !targets.length || !window.MutationObserver) return;

  new MutationObserver(function () {
    var match = /:\s*(.+)$/.exec(source.textContent.trim());
    if (!match) return;
    for (var i = 0; i < targets.length; i++) targets[i].textContent = match[1];
  }).observe(source, { childList: true, characterData: true, subtree: true });
})();

/* The header stays at the top of the screen up to 860px wide (gm-chrome.css). Tell the browser how tall it is, so
   whatever a page moves to - a box with a mistake, a message, a #link - isn't left underneath it. */
(function () {
  var header = document.querySelector('.site-header');
  var root = document.documentElement;
  if (!header || !window.getComputedStyle) return;
  function update() {
    var sticky = getComputedStyle(header).position === 'sticky';
    root.style.scrollPaddingTop = sticky ? (header.offsetHeight + 12) + 'px' : '';
  }
  update();
  if (window.ResizeObserver) new ResizeObserver(update).observe(header);
  window.addEventListener('resize', update);
})();

/* Track Order pop-up (_TrackOrderPopup.cshtml). Any element with data-track-open opens it; data-order and data-postcode
   on it fill the boxes in and look the order up straight away. "Find my order" posts the old pop-up's two fields to
   the site's order lookup, which answers with a sentence: shown as it is, and the steps light up when it's one of
   theirs (each step's data-says). */
(function () {
  var popup = document.getElementById('trackOrder');
  if (!popup || !window.fetch || !window.DOMParser) return;
  var form = popup.querySelector('.trk-form');
  var orderBox = form.querySelector('[name="orderId"]');
  var postcodeBox = form.querySelector('[name="postcode"]');
  var button = form.querySelector('.trk-submit');
  var label = button.textContent;
  var result = popup.querySelector('.trk-result');
  var number = result.querySelector('[data-track-number]');
  var steps = result.querySelectorAll('.trk-step');
  var message = result.querySelector('[data-track-message]');
  var announce = popup.querySelector('[data-track-announce]');
  var ellipsis = String.fromCharCode(8230);
  var apostrophe = String.fromCharCode(8217);
  var opener = null;
  var sending = false;

  function open(trigger) {
    // From the phone menu, which closes as the pop-up opens, focus goes back to the menu button afterwards
    var inMenu = trigger.closest && trigger.closest('.mobile-menu');
    opener = inMenu ? document.querySelector('.menu-toggle') : trigger;
    popup.hidden = false;
    document.body.style.overflow = 'hidden';
    var order = trigger.getAttribute('data-order');
    var postcode = trigger.getAttribute('data-postcode');
    if (order) {
      // an order's own "Track order": its details, looked up straight away
      orderBox.value = order;
      postcodeBox.value = postcode || '';
      result.hidden = true;
      if (postcode) { orderBox.focus(); look(); return; }
    }
    (!orderBox.value ? orderBox : !postcodeBox.value ? postcodeBox : button).focus();
  }

  function close() {
    popup.hidden = true;
    document.body.style.overflow = '';
    if (opener && opener.focus) opener.focus();
  }

  document.addEventListener('click', function (e) {
    var trigger = e.target.closest ? e.target.closest('[data-track-open]') : null;
    if (!trigger) return;
    e.preventDefault();   // the links are only there to open the pop-up
    open(trigger);
  });
  Array.prototype.forEach.call(popup.querySelectorAll('[data-track-close]'), function (el) {
    el.addEventListener('click', close);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !popup.hidden) close();
  });

  // Keep Tab inside the open pop-up: it covers the page, so focus shouldn't move behind it
  popup.addEventListener('keydown', function (e) {
    if (e.key !== 'Tab') return;
    var items = Array.prototype.filter.call(popup.querySelectorAll('a[href], button, input'), function (el) {
      return el.getClientRects().length > 0;
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

  // The answer is a sentence, sometimes with the phone number in bold. Only its words and bold are kept: one answer
  // repeats the postcode typed in, which mustn't be read as HTML.
  function fill(el, html) {
    el.textContent = '';
    var doc = new DOMParser().parseFromString(html, 'text/html');
    Array.prototype.forEach.call(doc.body.childNodes, function (node) {
      if (node.nodeType === 1 && (node.nodeName === 'B' || node.nodeName === 'STRONG')) {
        var strong = document.createElement('strong');
        strong.textContent = node.textContent;
        el.appendChild(strong);
      } else {
        el.appendChild(document.createTextNode(node.textContent));
      }
    });
  }

  function show(order, html) {
    fill(message, html);
    var said = message.textContent.replace(/\s+/g, ' ').trim();
    var reached = -1;
    Array.prototype.forEach.call(steps, function (step, i) {
      if (said.toLowerCase().indexOf(step.getAttribute('data-says')) >= 0) reached = i;
    });
    number.textContent = order;
    number.parentNode.hidden = reached < 0;
    steps[0].parentNode.hidden = reached < 0;
    Array.prototype.forEach.call(steps, function (step, i) {
      var done = i < reached || (i === reached && i === steps.length - 1);   // delivered is the last step, and done
      step.classList.toggle('is-done', done);
      step.classList.toggle('is-current', i === reached && !done);
      if (i === reached) step.setAttribute('aria-current', 'step'); else step.removeAttribute('aria-current');
      step.querySelector('[data-step-state]').textContent = done ? 'Done: ' : i === reached ? 'Now: ' : 'To come: ';
    });
    message.classList.toggle('trk-message--problem', reached < 0);
    result.hidden = false;
    announce.textContent = said;
  }

  function look() {
    if (sending) return;
    sending = true;
    button.setAttribute('aria-disabled', 'true');   // not disabled, so it keeps the focus
    button.textContent = 'Finding your order' + ellipsis;
    announce.textContent = '';
    var order = orderBox.value;
    var data = new URLSearchParams();
    data.append('orderId', order);
    data.append('postcode', postcodeBox.value);
    fetch(form.action, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
      body: data
    }).then(function (res) {
      if (!res.ok) throw new Error(res.status);
      return res.text();
    }).then(function (text) {
      // a sentence, not a whole page (an error page, or signing in)
      if (!text.trim() || /<(html|head|body|script)\b/i.test(text)) throw new Error('not an answer');
      show(order, text);
    }).catch(function () {
      show(order, 'Sorry, we couldn' + apostrophe + 't look up your order just now. Please try again, or call us on <b>0330 058 5068</b>, option 2.');
    }).then(function () {
      sending = false;
      button.removeAttribute('aria-disabled');
      button.textContent = label;
    });
  }

  orderBox.addEventListener('input', function () { orderBox.setCustomValidity(''); });
  form.addEventListener('submit', function (e) {
    e.preventDefault();
    if (sending) return;
    // as order numbers are sometimes written: "#123456", "123 456"
    orderBox.value = orderBox.value.replace(/[\s#]/g, '');
    postcodeBox.value = postcodeBox.value.trim().toUpperCase();
    orderBox.setCustomValidity(orderBox.validity.patternMismatch ? 'Order numbers are only numbers, like 123456.' : '');
    if (!form.checkValidity()) { form.reportValidity(); return; }
    look();
  });
})();
