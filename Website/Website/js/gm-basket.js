/* ===== GravelMaster basket page (Optima design) =====
   Views/Basket/_BasketPage.cshtml. It changes the basket exactly as the old basket page did:
   - + and - (or typing a number) change the line's quantity and post the basket form to /basket/updatebasket,
     which answers with the updated basket page. Quick clicks are gathered into one post;
   - Remove posts the line's id to /basket/removefrombasket, then the page reloads with the new totals;
     Empty basket does that for every line;
   - "Add to basket" on a suggestion calls /basket/addtobasket (with basketView, as the old "weekly special
     offers" did), then the page reloads;
   - Checkout Securely sends the Facebook InitiateCheckout event, as the old Checkout button did;
   - a photo that doesn't load is hidden, leaving its pale box.
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var root = document.querySelector('.gm-basket');
  if (!root) return;

  var form = root.querySelector('[data-basket-form]');
  var status = root.querySelector('[data-status]');
  function each(list, fn) { Array.prototype.forEach.call(list, fn); }

  function say(text) { if (status) status.textContent = text; }

  // A photo that doesn't load leaves its pale box rather than a broken-image icon (some products have no photo
  // files, e.g. Empty Waste Bags)
  each(root.querySelectorAll('.bsk-item__img, .bsk-rec__img'), function (img) {
    // a transparent 1px image: with no src at all, browsers still draw a broken-image icon
    var blank = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    function missing() { if (img.src !== blank) { img.src = blank; img.classList.add('is-missing'); } }
    if (img.complete && img.naturalWidth === 0) missing();
    else img.addEventListener('error', missing);
  });

  // While a change is on its way, stop further changes so they can't cross
  function busy(text) {
    say(text);
    root.classList.add('is-busy');
    each(root.querySelectorAll('button, input'), function (el) { el.disabled = true; });
  }
  function ready(text) {
    say(text);
    root.classList.remove('is-busy');
    each(root.querySelectorAll('button, input'), function (el) { el.disabled = false; });
  }

  function post(url, data) {
    var body = Object.keys(data).map(function (k) { return encodeURIComponent(k) + '=' + encodeURIComponent(data[k]); }).join('&');
    return fetch(url, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
      body: body
    }).then(function (res) { if (!res.ok) throw new Error(res.status); return res; });
  }

  /* ---- Quantities ---- */
  if (form) {
    var update = form.querySelector('[data-update]');
    if (update) update.hidden = true;   // the script sends changes itself
    var timer = null;

    function clamp(input) {
      var n = parseInt(input.value, 10);
      if (isNaN(n) || n < 1) n = 1;
      if (n > 999) n = 999;
      input.value = n;
    }
    function sendSoon() {
      clearTimeout(timer);
      say('');
      timer = setTimeout(function () {
        // the form's own fields: disabling them here would leave them out of the post
        say('Updating your basket\u2026');
        root.classList.add('is-busy');
        form.submit();
      }, 700);
    }

    each(form.querySelectorAll('[data-step]'), function (btn) {
      btn.addEventListener('click', function () {
        var input = btn.parentNode.querySelector('[data-qty]');
        var before = parseInt(input.value, 10) || 1;
        input.value = before + parseInt(btn.getAttribute('data-step'), 10);
        clamp(input);
        if (parseInt(input.value, 10) !== before) sendSoon();
      });
    });
    each(form.querySelectorAll('[data-qty]'), function (input) {
      input.addEventListener('change', function () { clamp(input); sendSoon(); });
      input.addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); clamp(input); sendSoon(); } });
    });
  }

  /* ---- Remove and Empty basket ---- */
  function removeLines(ids, doneText) {
    busy(ids.length > 1 ? 'Emptying your basket\u2026' : 'Removing the item\u2026');
    var chain = Promise.resolve();
    ids.forEach(function (id) { chain = chain.then(function () { return post('/basket/removefrombasket', { id: id }); }); });
    chain.then(function () {
      say(doneText);
      location.reload();
    }, function () {
      ready('Sorry, that couldn\u2019t be done. Please try again, or call us on 0330 058 5068.');
    });
  }
  each(root.querySelectorAll('[data-remove]'), function (btn) {
    btn.addEventListener('click', function () { removeLines([btn.getAttribute('data-remove')], 'Item removed.'); });
  });
  var empty = root.querySelector('[data-empty]');
  if (empty) {
    empty.addEventListener('click', function () {
      if (!window.confirm('Remove everything from your basket?')) return;
      var ids = [];
      each(root.querySelectorAll('[data-remove]'), function (btn) { ids.push(btn.getAttribute('data-remove')); });
      removeLines(ids, 'Basket emptied.');
    });
  }

  /* ---- Suggestions ---- */
  var area = (root.getAttribute('data-postal-area') || '').trim();
  each(root.querySelectorAll('[data-add]'), function (btn) {
    btn.addEventListener('click', function () {
      busy('Adding to your basket\u2026');
      var url = '/basket/addtobasket?id=' + encodeURIComponent(btn.getAttribute('data-add')) + '&qty=1' +
        '&postcodeData=' + encodeURIComponent(area) +
        '&selectedVariantCode=' + encodeURIComponent(btn.getAttribute('data-variant')) + '&basketView=1';
      fetch(url, { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } })
        .then(function (res) { if (!res.ok) throw new Error(res.status); location.reload(); })
        .catch(function () { ready('Sorry, that couldn\u2019t be added. Please try again, or call us on 0330 058 5068.'); });
    });
  });

  /* ---- Voucher ---- */
  var voucher = root.querySelector('[data-voucher]');
  if (voucher) {
    var toggle = voucher.querySelector('[data-voucher-toggle]');
    toggle.addEventListener('click', function () {
      var open = voucher.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      if (open) voucher.querySelector('input').focus();
    });
  }

  /* ---- Checkout ---- */
  var checkout = root.querySelector('[data-checkout]');
  if (checkout) {
    checkout.addEventListener('click', function () {
      if (typeof window.fbq === 'function') window.fbq('track', 'InitiateCheckout', { eventref: '' });
    });
  }
})();
