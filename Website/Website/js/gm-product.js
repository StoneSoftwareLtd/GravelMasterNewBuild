/* ===== GravelMaster product page (Optima design) =====
   Views/Shared/_ProductPage.cshtml: photos, the postcode step and prices, the buy form, the "added to your
   basket" pop-up and "You might also like".
   It talks to the site exactly as the old product page did:
   - /basket/getselectedpostcode      the postcode area already chosen in this visit
   - /product/calculateprices         each size's price for the area and quantity (trade prices for trade)
   - the form's action                /basket/addtobasket?id=<code>, posting postcodeData, selectedVariantItem
                                      and qty as an AJAX request, which answers with the basket summary
   - /basket/updatequantity           the + and - buttons in that summary
   - /basket/getbasketsummary         "N Items: £X" for the header
   and sends the same Google Analytics events (view_item, add_to_cart, no_postcode_selected).
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var root = document.querySelector('.gm-product');
  if (!root) return;

  var gbp = window.Intl ? new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' }) : null;
  function money(n) { return gbp ? gbp.format(n) : '£' + Number(n).toFixed(2); }
  function each(list, fn) { Array.prototype.forEach.call(list, fn); }

  function track(name, data) {
    if (typeof window.gtag === 'function') window.gtag('event', name, data);
  }

  // Keep Tab inside an open pop-up: it covers the page, so focus shouldn't move behind it
  function trapTab(box, e) {
    if (e.key !== 'Tab') return;
    var items = Array.prototype.filter.call(box.querySelectorAll('a[href], button, input, select, textarea, iframe'), function (el) {
      return !el.disabled && el.tabIndex >= 0 && el.getClientRects().length > 0;
    });
    if (!items.length) { e.preventDefault(); return; }
    var first = items[0];
    var last = items[items.length - 1];
    if (e.shiftKey && (document.activeElement === first || !box.contains(document.activeElement))) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  }

  /* ---------- Photos ---------- */
  (function () {
    var gallery = root.querySelector('[data-gallery]');
    if (!gallery) return;
    var main = gallery.querySelector('[data-gallery-main]');
    var frame = gallery.querySelector('[data-gallery-frame]');
    var zoom = gallery.querySelector('[data-gallery-zoom]');
    var list = gallery.querySelector('[data-gallery-thumbs]');
    var thumbs = gallery.querySelectorAll('.pdp-thumb');
    var current = 0;

    function show(i) {
      if (!thumbs.length) return;
      current = (i + thumbs.length) % thumbs.length;
      var thumb = thumbs[current];
      each(thumbs, function (t, n) {
        t.classList.toggle('is-active', n === current);
        t.setAttribute('aria-pressed', n === current ? 'true' : 'false');
      });
      var frameUrl = thumb.getAttribute('data-frame');
      // Emptying the frame also stops a playing video
      frame.innerHTML = '';
      if (frameUrl) {
        var iframe = document.createElement('iframe');
        iframe.src = frameUrl;
        iframe.title = thumb.getAttribute('aria-label');
        iframe.setAttribute('allow', 'autoplay; fullscreen');
        iframe.setAttribute('allowfullscreen', '');
        frame.appendChild(iframe);
        frame.hidden = false;
        if (main) main.hidden = true;
        gallery.classList.add('is-frame');
      } else {
        frame.hidden = true;
        if (main) {
          main.hidden = false;
          main.src = thumb.getAttribute('data-src');
        }
        if (zoom) zoom.href = thumb.getAttribute('data-zoom');
        gallery.classList.remove('is-frame');
      }
      // Bring the chosen thumbnail into view by scrolling the strip only, not the page
      if (list) {
        var item = thumb.parentNode;
        if (item.offsetLeft < list.scrollLeft) list.scrollLeft = item.offsetLeft;
        else if (item.offsetLeft + item.offsetWidth > list.scrollLeft + list.clientWidth) list.scrollLeft = item.offsetLeft + item.offsetWidth - list.clientWidth;
      }
    }

    each(thumbs, function (t, n) { t.addEventListener('click', function () { show(n); }); });
    var prev = gallery.querySelector('[data-gallery-prev]');
    var next = gallery.querySelector('[data-gallery-next]');
    if (prev) prev.addEventListener('click', function () { show(current - 1); });
    if (next) next.addEventListener('click', function () { show(current + 1); });

    // "Click to zoom" opens the 1000px photo over the page (the link opens it in a new tab without the script)
    if (!zoom) return;
    zoom.addEventListener('click', function (e) {
      e.preventDefault();
      var opener = document.activeElement;
      var box = document.createElement('div');
      box.className = 'pdp-zoom';
      box.setAttribute('role', 'dialog');
      box.setAttribute('aria-modal', 'true');
      box.setAttribute('aria-label', 'Zoomed photo');
      box.innerHTML = '<div class="pdp-zoom__overlay"></div><img class="pdp-zoom__img" alt=""><button type="button" class="pdp-zoom__close" aria-label="Close"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg></button>';
      var img = box.querySelector('img');
      img.alt = main ? main.alt : '';
      img.src = zoom.href;
      function close() {
        document.removeEventListener('keydown', onKey);
        root.removeChild(box);
        document.body.style.overflow = '';
        if (opener && opener.focus) opener.focus();
      }
      function onKey(ev) {
        if (ev.key === 'Escape') close();
        else trapTab(box, ev);
      }
      box.querySelector('.pdp-zoom__overlay').addEventListener('click', close);
      box.querySelector('.pdp-zoom__close').addEventListener('click', close);
      img.addEventListener('click', close);
      document.addEventListener('keydown', onKey);
      root.appendChild(box);
      document.body.style.overflow = 'hidden';
      box.querySelector('.pdp-zoom__close').focus();
    });
  })();

  /* ---------- Size pictures the site doesn't have ---------- */
  each(root.querySelectorAll('.pdp-option__img'), function (img) {
    function hide() { img.style.visibility = 'hidden'; }
    if (img.complete && img.naturalWidth === 0) hide();
    else img.addEventListener('error', hide);
  });

  /* ---------- Buy box ---------- */
  var form = root.querySelector('[data-buy]');
  if (form) buyBox(form);

  function buyBox(form) {
    var productId = form.getAttribute('data-product-id');
    var productName = form.getAttribute('data-name');
    var category = form.getAttribute('data-category');
    var isSimple = form.getAttribute('data-simple') === 'true';
    var areas = (form.getAttribute('data-areas') || '').split(',');
    var STORAGE_KEY = 'gm-postcode';   // the prototype's key, shared with its postcode pop-up

    var step = form.querySelector('[data-postcode]');
    var input = form.querySelector('[data-postcode-input]');
    var panel = form.querySelector('[data-postcode-panel]');
    var bar = form.querySelector('[data-postcode-bar]');
    var ok = form.querySelector('[data-postcode-ok]');
    var pcError = form.querySelector('[data-postcode-error]');
    var pcSubmit = form.querySelector('[data-postcode-submit]');
    var radios = form.querySelectorAll('input[name="selectedVariantItem"]');
    var qtyInput = form.querySelector('[data-qty-input]');
    var minQty = parseInt(qtyInput.getAttribute('min'), 10) || 1;
    var total = form.querySelector('[data-total]');
    var buyError = form.querySelector('[data-buy-error]');
    var addBtn = form.querySelector('[data-addcart]');
    var addText = form.querySelector('[data-addcart-text]');
    var sampleBtn = form.querySelector('[data-sample]');
    var stockText = root.querySelector('[data-stock-text]');
    var dateLine = root.querySelector('[data-delivery-date]');
    var preLine = root.querySelector('[data-delivery-pre]');
    var preDate = root.querySelector('[data-delivery-pre-date]');

    var area = null;       // the postcode area in use, e.g. "NG" (what the old drop-down held)
    var prices = {};       // size id -> price for the current area and quantity
    var round = 0;         // numbers each round of price lookups, so a slow old answer can't overwrite a newer one

    function selectedRadio() {
      for (var i = 0; i < radios.length; i++) if (radios[i].checked) return radios[i];
      return radios[0];
    }
    function quantity() {
      var q = parseInt(qtyInput.value, 10);
      return isNaN(q) || q < minQty ? minQty : Math.min(q, 9999);
    }

    /* The Google Analytics events the old page sent, with the same fields */
    function itemEvent(name, source, extra) {
      var data = {
        currency: 'GBP',
        value: parseFloat(source.getAttribute('data-price')),
        items: [{ item_id: source.getAttribute('data-code'), item_name: productName + '_' + source.getAttribute('data-code'), item_category: category }]
      };
      for (var k in extra) data[k] = extra[k];
      track(name, data);
    }

    /* ----- Postcode ----- */
    // "NG5 6AB", "ng5" or "NG" -> "NG" (ProductPageModel.GetPostcodeArea); false: not a postcode; null: an area we don't deliver to
    function areaOf(value) {
      var m = /^([A-Z]{1,2})(?:[0-9][0-9A-Z]?(?:\s*[0-9][A-Z]{2})?)?$/i.exec((value || '').trim());
      if (!m) return false;
      var a = m[1].toUpperCase();
      return areas.indexOf(a) >= 0 ? a : null;
    }
    function tidy(value) {
      var s = value.trim().toUpperCase().replace(/\s+/g, '');
      return s.length > 4 ? s.slice(0, -3) + ' ' + s.slice(-3) : s;
    }
    function showError(message) {
      pcError.textContent = message;
      input.setAttribute('aria-invalid', message ? 'true' : 'false');
    }
    function setOpen(open) {
      panel.hidden = !open;
      step.classList.toggle('is-open', open && !!area);
      each(root.querySelectorAll('[data-postcode-toggle]'), function (t) { t.setAttribute('aria-expanded', open ? 'true' : 'false'); });
    }
    // Shows a postcode (or area) as the delivery address and prices everything for its area
    function useArea(a, shown, announce) {
      area = a;
      each(root.querySelectorAll('[data-postcode-current]'), function (el) { el.textContent = shown; });
      bar.hidden = false;
      var line = root.querySelector('[data-postcode-line]');
      if (line) line.hidden = false;
      var label = root.querySelector('[data-postcode-change-label]');
      if (label) label.textContent = 'Change delivery address';
      input.value = shown;
      showError('');
      var hadFocus = panel.contains(document.activeElement);
      setOpen(false);
      ok.hidden = !announce;
      // The postcode box is gone, so keep the keyboard where the address now shows
      if (hadFocus) bar.querySelector('[data-postcode-toggle]').focus();
      updatePrices();
    }
    function needPostcode() {
      setOpen(true);
      showError('Please enter your postcode so we can work out the delivery.');
      step.scrollIntoView({ behavior: 'smooth', block: 'center' });
      input.focus({ preventScroll: true });
      track('no_postcode_selected', { modal: 'show' });
    }
    function submitPostcode() {
      var value = input.value;
      if (!value.trim()) { showError('Please enter a postcode.'); input.focus(); return; }
      var a = areaOf(value);
      if (a === false) { showError('That doesn’t look like a UK postcode. Please check it and try again.'); input.focus(); return; }
      if (a === null) { showError('Sorry, we can’t take orders for ' + tidy(value) + ' online. Please call us on 0330 058 5068.'); input.focus(); return; }
      var shown = tidy(value);
      try { localStorage.setItem(STORAGE_KEY, shown); } catch (err) {}
      useArea(a, shown, true);
    }

    if (!isSimple) {
      pcSubmit.addEventListener('click', submitPostcode);
      input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') { e.preventDefault(); submitPostcode(); }
      });
      each(root.querySelectorAll('[data-postcode-toggle]'), function (t) {
        t.addEventListener('click', function () {
          if (!area) {   // no postcode yet: the panel is already open, so take them to it
            step.scrollIntoView({ behavior: 'smooth', block: 'center' });
            input.focus({ preventScroll: true });
            return;
          }
          var opening = panel.hidden;
          setOpen(opening);
          ok.hidden = true;
          if (opening) {
            if (t.closest('.pdp-notice')) step.scrollIntoView({ behavior: 'smooth', block: 'center' });
            input.focus({ preventScroll: true });
            input.select();
          }
        });
      });

      // The area chosen earlier in this visit (the old page's drop-down read the same), else the postcode
      // remembered on this device
      var saved = null;
      try { saved = localStorage.getItem(STORAGE_KEY); } catch (err) {}
      var restore = function (serverArea) {
        var fromServer = serverArea && areas.indexOf(serverArea) >= 0 ? serverArea : null;
        var savedArea = saved ? areaOf(saved) : null;
        if (fromServer) useArea(fromServer, savedArea === fromServer ? saved : fromServer, false);
        else if (savedArea) useArea(savedArea, saved, false);
      };
      fetch('/basket/getselectedpostcode', { credentials: 'same-origin', cache: 'no-store' })
        .then(function (res) { return res.ok ? res.text() : ''; })
        .then(function (text) { restore(text.trim().replace(/^"|"$/g, '').toUpperCase()); })
        .catch(function () { restore(null); });
    }

    /* ----- Prices ----- */
    function showTotal() {
      var id = selectedRadio().value;
      total.classList.remove('is-prompt');
      if (!isSimple && !area) {
        total.textContent = 'Enter your postcode';
        total.classList.add('is-prompt');
      } else if (prices[id] != null) {
        total.textContent = money(prices[id]);
      } else {
        total.textContent = '';
      }
    }
    function updatePrices() {
      var no = ++round;
      prices = {};
      buyError.textContent = '';
      each(form.querySelectorAll('[data-option-price]'), function (el) { el.textContent = ''; });
      showTotal();
      if (!isSimple && !area) return;
      var q = quantity();
      each(radios, function (radio) {
        var id = radio.value;
        var url = '/product/calculateprices?quantity=' + q + '&postarea=' + encodeURIComponent(area || '') + '&variantitem=' + id + '&productId=' + productId;
        fetch(url, { credentials: 'same-origin', cache: 'no-store', headers: { 'Accept': 'application/json' } })
          .then(function (res) { if (!res.ok) throw new Error(res.status); return res.json(); })
          .then(function (data) {
            if (no !== round) return;
            var price = Array.isArray(data) ? data[0] : data;
            if (typeof price !== 'number') throw new Error('no price');
            prices[id] = price;
            var el = form.querySelector('[data-option-price="' + id + '"]');
            if (el) el.textContent = money(price);
            showTotal();
          })
          .catch(function () {
            if (no !== round) return;
            buyError.textContent = 'Sorry, we couldn’t get ' + (area ? 'prices for ' + area + ' postcodes' : 'the price') + ' just now. Please try again, or call us on 0330 058 5068.';
          });
      });
    }

    /* ----- Sizes ----- */
    function sizeChanged(announce) {
      var radio = selectedRadio();
      each(radios, function (r) { r.closest('.pdp-option').classList.toggle('is-active', r.checked); });
      var pre = radio.getAttribute('data-preorder');
      if (addText) addText.textContent = pre ? 'Pre-order' : 'Add to cart';
      if (stockText) stockText.textContent = pre ? 'Available to pre-order' : 'In stock';
      if (dateLine) dateLine.hidden = !!pre;
      if (preLine) preLine.hidden = !pre;
      if (preDate) preDate.textContent = pre;
      showTotal();
      if (announce) itemEvent('view_item', radio, {});
    }
    each(radios, function (r) { r.addEventListener('change', function () { sizeChanged(true); }); });
    sizeChanged(false);
    itemEvent('view_item', selectedRadio(), {});   // as the old page, on opening

    /* ----- Quantity ----- */
    var qtyTimer = null;
    function setQty(q) {
      qtyInput.value = Math.max(minQty, Math.min(q, 9999));
      clearTimeout(qtyTimer);
      qtyTimer = setTimeout(updatePrices, 250);
    }
    form.querySelector('[data-qty-down]').addEventListener('click', function () { setQty(quantity() - 1); });
    form.querySelector('[data-qty-up]').addEventListener('click', function () { setQty(quantity() + 1); });
    qtyInput.addEventListener('change', function () { setQty(quantity()); });

    /* ----- Adding to the basket ----- */
    function addToBasket(variantId, qty, button, source) {
      buyError.textContent = '';
      if (!isSimple && !area) { needPostcode(); return; }
      var data = new URLSearchParams();
      if (!isSimple) data.append('postcodeData', area);
      data.append('selectedVariantItem', variantId);
      data.append('qty', qty);
      button.disabled = true;
      button.classList.add('is-busy');
      fetch(form.action, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
        body: data.toString()
      }).then(function (res) {
        if (!res.ok) throw new Error(res.status);
        return res.text();
      }).then(function (html) {
        // The basket answers with this one line, instead of the summary, when the size has just sold out
        if (/just gone out of stock/i.test(html) && html.indexOf('modal-item') < 0) {
          buyError.textContent = 'Sorry, this size has just gone out of stock. Please try again later, or call us on 0330 058 5068.';
          return;
        }
        itemEvent('add_to_cart', source, { postcode: isSimple ? undefined : area });
        added.open(html, button);
      }).catch(function () {
        buyError.textContent = 'Sorry, we couldn’t add that to your basket. Please try again, or call us on 0330 058 5068.';
      }).then(function () {
        button.disabled = false;
        button.classList.remove('is-busy');
      });
    }

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      if (!addBtn) return;
      var radio = selectedRadio();
      addToBasket(radio.value, quantity(), addBtn, radio);
    });
    if (sampleBtn) {
      sampleBtn.addEventListener('click', function () {
        addToBasket(sampleBtn.getAttribute('data-sample'), 1, sampleBtn, sampleBtn);
      });
    }

    if (isSimple) updatePrices();
  }

  /* ---------- "Added to your basket" pop-up ---------- */
  var added = (function () {
    var box = root.querySelector('[data-added]');
    var dialog = box.querySelector('[role="dialog"]');
    var summary = box.querySelector('[data-added-summary]');
    var opener = null;

    // The summary's own "ADD" buttons and the old page's scripts put the next summary in #insertBefore
    summary.id = 'insertBefore';

    // Inserts the basket's HTML and runs its scripts, as the old page's jQuery did
    function setHtml(html) {
      if (window.jQuery) { window.jQuery(summary).html(html); return; }
      summary.innerHTML = html;
      each(summary.querySelectorAll('script'), function (old) {
        var s = document.createElement('script');
        s.text = old.text;
        old.parentNode.replaceChild(s, old);
      });
    }

    function refreshHeader() {
      fetch('/basket/getbasketsummary', { credentials: 'same-origin', cache: 'no-store' })
        .then(function (res) { return res.ok ? res.text() : Promise.reject(); })
        .then(function (text) {
          var line = text.split('|')[0];
          // gm-chrome.js copies this into the header's basket total
          each(document.querySelectorAll('#numItems, #numItems2'), function (el) { el.innerHTML = line; });
        })
        .catch(function () {});
    }

    // The old page's name for "the summary changed": the summary's "ADD" buttons call it after adding
    window.handleUpdate = function () { refreshHeader(); };

    function close() {
      box.hidden = true;
      document.body.style.overflow = '';
      if (opener && opener.focus && opener.getClientRects().length) opener.focus();
    }
    each(box.querySelectorAll('[data-added-close]'), function (el) { el.addEventListener('click', close); });
    document.addEventListener('keydown', function (e) {
      if (box.hidden) return;
      if (e.key === 'Escape') close();
      else trapTab(dialog, e);
    });

    // The + and - buttons in the summary change a basket line, as the old page's Detail.js did
    summary.addEventListener('click', function (e) {
      var button = e.target.closest('.plus, .minus');
      if (!button) return;
      var field = button.parentNode.querySelector('.qty');
      if (!field) return;
      var q = parseInt(field.value, 10) || 1;
      q = button.classList.contains('plus') ? q + 1 : Math.max(1, q - 1);
      field.value = q;
      var code = field.getAttribute('data-code');
      if (!code) return;
      fetch('/basket/updatequantity?code=' + encodeURIComponent(code) + '&quantity=' + q, { credentials: 'same-origin', cache: 'no-store' })
        .then(function (res) { return res.ok ? res.text() : Promise.reject(); })
        .then(function (text) {
          var parts = text.split(':');   // "basket total:line total"
          var line = summary.querySelector('[id="bask-' + code + '"] #popupLine');
          if (line) line.textContent = parts[1];
          var totalEl = summary.querySelector('#popupTotal');
          if (totalEl) {
            totalEl.innerHTML = 'Basket Total: <b></b>';
            totalEl.querySelector('b').textContent = parts[0];
          }
          refreshHeader();
        })
        .catch(function () {});
    });

    return {
      open: function (html, from) {
        opener = from;
        setHtml(html);
        box.hidden = false;
        document.body.style.overflow = 'hidden';
        dialog.focus();
        refreshHeader();
      }
    };
  })();

  /* ---------- You might also like ---------- */
  each(root.querySelectorAll('[data-carousel]'), function (section) {
    var viewport = section.querySelector('[data-carousel-viewport]');
    var track = section.querySelector('[data-carousel-track]');
    var prev = section.querySelector('[data-carousel-prev]');
    var next = section.querySelector('[data-carousel-next]');
    var fill = section.querySelector('[data-carousel-progress]');
    var pos = 0;

    function stepWidth() {
      var card = track.firstElementChild;
      if (!card) return 0;
      var style = getComputedStyle(track);
      return card.getBoundingClientRect().width + (parseFloat(style.columnGap || style.gap) || 0);
    }
    function maxPos() { return Math.max(0, track.scrollWidth - viewport.clientWidth); }
    function apply() {
      var max = maxPos();
      pos = Math.max(0, Math.min(pos, max));
      track.style.transform = pos ? 'translateX(-' + pos + 'px)' : '';
      section.classList.toggle('is-static', max <= 1);
      if (fill) fill.style.width = (max > 0 ? (pos / max) * 75 + 25 : 100) + '%';
      if (prev) prev.disabled = pos <= 0;
      if (next) next.disabled = pos >= max - 1;
    }
    if (next) next.addEventListener('click', function () { pos += stepWidth(); apply(); });
    if (prev) prev.addEventListener('click', function () { pos -= stepWidth(); apply(); });
    // A card that gets focus (Tab) is scrolled into view
    track.addEventListener('focusin', function (e) {
      var card = e.target.closest('.pdp-rec');
      if (!card) return;
      var left = card.offsetLeft;
      if (left < pos || left + card.offsetWidth > pos + viewport.clientWidth) { pos = left; apply(); }
      viewport.scrollLeft = 0;
    });
    // Card widths change with the screen, so start again rather than keep an offset between cards
    window.addEventListener('resize', function () { pos = 0; apply(); });
    apply();
  });
})();
