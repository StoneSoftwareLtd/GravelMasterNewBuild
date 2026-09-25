/* ===== GravelMaster header, footer and mobile menu behaviour =====
   menu.js and foot-features.js from the Optima prototype, plus the live basket
   total. Loaded at the end of <body> only when _Layout renders the new chrome. */

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
