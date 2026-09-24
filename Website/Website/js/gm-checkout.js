/* ===== GravelMaster checkout (Optima design) =====
   Views/Checkout/_CheckoutPage.cshtml. The form posts to /checkout/processorder exactly as the old checkout's did.
   This does, on one page, what the old page's script (Scripts/Controllers/Root/Checkout/ProcessOrder.js) and its
   inline updateUI() did over four steps:
   - adds up the delivery charges (the chosen date's and the chosen time's) into deliveryExtraData and shows the
     new total;
   - checks the details before they're sent, as the old page's checks did (required boxes, lengths, the postcode's
     form, the email, the terms), and that the delivery postcode is in the area the basket was priced for;
   - takes away the first seven dates for Isle of Wight postcodes, as the old page did;
   - shows the billing address boxes when "Use a different billing address" is ticked;
   - stops Enter in a box from sending the form (the address finder uses Enter to pick an address).
   And, new: arrows for the row of dates, the progress steps following the part being filled in, labels for the
   address finders' search boxes, messages under the boxes, and one press of "Continue to payment".
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var root = document.querySelector('.gm-checkout');
  var form = root && root.querySelector('[data-checkout-form]');
  if (!form) return;
  form.noValidate = true;   // this script checks the form itself, with a message under each box

  function each(list, fn) { Array.prototype.forEach.call(list, fn); }
  var pound = String.fromCharCode(163);
  function money(n) { return pound + n.toLocaleString('en-GB', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); }
  function price(input) { var n = input ? parseFloat(input.getAttribute('data-price')) : 0; return isNaN(n) ? 0 : n; }
  function checked(name) { return form.querySelector('input[name="' + name + '"]:checked'); }
  function setText(selector, text) { each(root.querySelectorAll(selector), function (el) { el.textContent = text; }); }
  var smooth = !(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);

  // A photo that doesn't load leaves its pale box rather than a broken-image icon
  each(root.querySelectorAll('.chk-item__img'), function (img) {
    var blank = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    function missing() { if (img.src !== blank) img.src = blank; }
    if (img.complete && img.naturalWidth === 0) missing();
    else img.addEventListener('error', missing);
  });

  // Paid dates and times are switched off in the page until this script is here to add up their charge
  each(form.querySelectorAll('[data-paid]'), function (input) { input.disabled = false; });

  /* ---- Delivery charges and the total (the old page's updateUI) ---- */
  var baseTotal = parseFloat(root.getAttribute('data-total')) || 0;
  var extraInput = form.querySelector('[data-extra]');

  function update() {
    var date = checked('selectedDelDay');
    var time = checked('selectedTime');
    var dateCost = date && date.type === 'radio' ? price(date) : 0;
    var timeCost = time && time.type === 'radio' ? price(time) : 0;
    var extra = dateCost + timeCost;
    if (extraInput) extraInput.value = extra.toFixed(2);
    setText('[data-total-text]', money(baseTotal + extra));
    if (root.querySelector('[data-sum-day]')) {
      setText('[data-sum-kind]', date ? date.getAttribute('data-kind') : 'Weekday delivery');
      setText('[data-sum-day]', date ? 'Delivery on ' + date.getAttribute('data-long') : 'Choose a delivery date');
      setText('[data-sum-day-price]', money(dateCost));
    }
    if (time && time.type === 'radio') {
      setText('[data-sum-time]', time.getAttribute('data-label'));
      setText('[data-sum-time-price]', money(timeCost));
    }
    // the chosen date and time, for browsers without :has()
    each(form.querySelectorAll('.chk-date, .chk-time'), function (label) {
      var input = label.querySelector('input');
      label.classList.toggle('is-checked', !!(input && input.checked));
    });
  }

  /* ---- The row of dates ---- */
  var track = form.querySelector('[data-dates-track]');
  var datesField = form.querySelector('[data-dates-field]');
  var prev = form.querySelector('[data-dates-prev]');
  var next = form.querySelector('[data-dates-next]');

  function arrows() {
    if (!track || !prev || !next) return;
    var max = track.scrollWidth - track.clientWidth;
    prev.hidden = next.hidden = max <= 2;
    prev.disabled = track.scrollLeft <= 2;
    next.disabled = track.scrollLeft >= max - 2;
  }
  function showDate(input) {
    if (!track || !input) return;
    var label = input.closest('.chk-date');
    var offset = label.getBoundingClientRect().left - track.getBoundingClientRect().left;
    if (offset < 0 || offset + label.offsetWidth > track.clientWidth) track.scrollLeft += offset - 3;
  }
  if (track && prev && next) {
    var step = function (dir) {
      var by = Math.max(track.clientWidth - 104, 104) * dir;
      if (track.scrollBy) track.scrollBy({ left: by, behavior: smooth ? 'smooth' : 'auto' });
      else track.scrollLeft += by;
    };
    prev.addEventListener('click', function () { step(-1); });
    next.addEventListener('click', function () { step(1); });
    track.addEventListener('scroll', arrows, { passive: true });
    if (window.ResizeObserver) new ResizeObserver(arrows).observe(track);
    else window.addEventListener('resize', arrows);
  }

  /* ---- The delivery postcode ---- */
  var postcode = form.querySelector('[data-postcode]');
  var area = (root.getAttribute('data-area') || '').replace(/\s+/g, '').toLowerCase();
  var strictArea = root.getAttribute('data-area-strict') === 'true';
  var islandNote = form.querySelector('[data-island-note]');

  // The basket was priced for one postcode area (e.g. NG). The server checks a delivery postcode's letters match it
  // exactly (strict); the old page's script only checked the postcode contained it.
  function areaOk(value) {
    if (!area) return true;
    var v = value.replace(/\s+/g, '').toLowerCase();
    if (!strictArea) return v.indexOf(area) !== -1;
    var letters = v.match(/^[a-z]{1,2}/);
    return !!letters && letters[0] === area;
  }

  // Isle of Wight postcodes (PO30 to PO41) don't get the first seven dates, as on the old page. The old page looked
  // for "po30" and so on anywhere in the postcode, which also caught every Portsmouth PO3 postcode (PO3 5AA is
  // "po35aa") and PO4 0.. and 1..; this reads the postcode's first half.
  function isIsland(value) {
    var v = value.replace(/\s+/g, '').toUpperCase();
    return /^PO(3\d|4[01])$/.test(v.length > 3 ? v.slice(0, -3) : v);
  }
  // Returns the new date's long name when the chosen date had to change
  function islandRule() {
    if (!track || !postcode) return '';
    var island = isIsland(postcode.value);
    var lost = false;
    each(track.querySelectorAll('.chk-date'), function (label, i) {
      var input = label.querySelector('input');
      var unavailable = input.hasAttribute('data-unavailable');
      var hide = unavailable || (island && i < 7);
      label.hidden = hide;
      if (!unavailable) input.disabled = hide;
      if (hide && input.checked) { input.checked = false; lost = true; }
    });
    if (islandNote) islandNote.hidden = !island;
    if (!lost) return '';
    // as the old page's first choice: the first free weekday, else the first date there is
    var inputs = [].slice.call(track.querySelectorAll('input:not(:disabled)'));
    var pick = inputs.filter(function (i) { return price(i) === 0 && i.getAttribute('data-kind') === 'Weekday delivery'; })[0] || inputs[0];
    if (pick) pick.checked = true;
    update();
    showDate(pick);
    return pick ? pick.getAttribute('data-long') : '';
  }

  /* ---- The billing address ---- */
  var billing = form.querySelector('[data-billing]');
  var billingToggle = form.querySelector('[data-billing-toggle]');
  if (billing && billingToggle) {
    var showBilling = function () { billing.hidden = !billingToggle.checked; };
    billingToggle.addEventListener('change', showBilling);
    showBilling();   // ticked already when the browser brings the page back
  }

  /* ---- Checking the details ---- */
  var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  function messageFor(input) {
    var required = input.required || input.hasAttribute('data-required');
    if (input.type === 'checkbox') return required && !input.checked ? input.getAttribute('data-msg-required') : '';
    var value = input.value.trim();
    if (!value) return required ? input.getAttribute('data-msg-required') : '';
    // the server's lengths (the address finder can fill in more than a box's maxlength)
    var max = parseInt(input.getAttribute('maxlength'), 10);
    if (max && value.length > max) return input.getAttribute('data-msg-length');
    var pattern = input.getAttribute('pattern');
    if (pattern && !new RegExp('^(?:' + pattern + ')$').test(value)) return input.getAttribute('data-msg-pattern');
    if (input.type === 'email' && !emailPattern.test(value)) return input.getAttribute('data-msg-email');
    if (input === postcode && !areaOk(value)) return input.getAttribute('data-msg-area').replace('{area}', area.toUpperCase());
    return '';
  }

  // Where each box's message goes, and what it describes
  function errorFor(el, make) {
    var id = (el === track ? 'chk-dates' : el.id || el.name.replace(/\W/g, '')) + '-error';
    var msg = document.getElementById(id);
    if (!msg && make) {
      msg = document.createElement('p');
      msg.className = 'chk-error';
      msg.id = id;
      var after = el === track ? track.parentNode : el.type === 'checkbox' ? el.closest('.chk-check') : el;
      after.parentNode.insertBefore(msg, after.nextSibling);
    }
    return msg;
  }
  function describedBy(el, id, on) {
    var target = el === track ? datesField : el;
    var ids = (target.getAttribute('aria-describedby') || '').split(/\s+/).filter(function (x) { return x && x !== id; });
    if (on) ids.push(id);
    if (ids.length) target.setAttribute('aria-describedby', ids.join(' '));
    else target.removeAttribute('aria-describedby');
  }
  function showError(el, text) {
    var msg = errorFor(el, true);
    msg.textContent = text;
    msg.hidden = false;
    if (el !== track) el.setAttribute('aria-invalid', 'true');
    describedBy(el, msg.id, true);
  }
  function clearError(el) {
    var msg = errorFor(el, false);
    if (el !== track) el.removeAttribute('aria-invalid');
    if (!msg) return;
    msg.hidden = true;
    describedBy(el, msg.id, false);
  }
  function check(input) {
    var text = messageFor(input);
    if (text) showError(input, text); else clearError(input);
    return text;
  }
  function skipped(input) {
    return input.type === 'hidden' || input.type === 'radio' || input.disabled || !!input.closest('[hidden]') ||
      input.classList.contains('search');   // the address finders' own search boxes
  }

  // A box with a message is checked again as it changes; any box is checked when left with something in it
  form.addEventListener('input', function (e) {
    if (e.target.getAttribute('aria-invalid') === 'true') check(e.target);
  });
  form.addEventListener('change', function (e) {
    var t = e.target;
    if (t.name === 'selectedDelDay' || t.name === 'selectedTime') {
      update();
      if (t.name === 'selectedDelDay') clearError(track);
      return;
    }
    if (t.type === 'checkbox' && t.getAttribute('aria-invalid') === 'true') check(t);
  });
  form.addEventListener('focusout', function (e) {
    var t = e.target;
    if ((t.tagName === 'INPUT' || t.tagName === 'TEXTAREA') && t.type !== 'checkbox' && !skipped(t) && t.value.trim()) check(t);
    if (t === postcode) islandRule();
  });

  /* ---- Continue to payment ---- */
  var submit = form.querySelector('[data-submit]');
  var submitText = form.querySelector('[data-submit-text]');
  var submitLabel = submitText ? submitText.textContent : '';
  var summary = form.querySelector('[data-error-summary]');
  var sending = false;

  form.addEventListener('submit', function (e) {
    if (sending) { e.preventDefault(); return; }
    each(form.querySelectorAll('input[type="text"], input[type="email"], input[type="tel"], textarea'), function (input) {
      if (input.value !== input.value.trim() && !input.classList.contains('search')) input.value = input.value.trim();
    });
    var moved = islandRule();
    var count = 0;
    var first = null;
    each(form.querySelectorAll('input, textarea, [data-dates-track]'), function (el) {
      var text;
      if (el === track) {
        if (!checked('selectedDelDay')) text = track.getAttribute('data-msg-required');
        else if (moved) text = "The first dates aren't available for Isle of Wight postcodes, so the delivery date is now " + moved + '. Please check it.';
        if (text) showError(track, text); else clearError(track);
      } else {
        if (skipped(el)) return;
        text = check(el);
      }
      if (text) {
        count++;
        if (!first) first = el === track ? (checked('selectedDelDay') || track.querySelector('input:not(:disabled)')) : el;
      }
    });
    if (count) {
      e.preventDefault();
      if (summary) {
        summary.textContent = (count === 1 ? '1 detail needs' : count + ' details need') + ' checking: see the ' + (count === 1 ? 'message' : 'messages') + ' above.';
        summary.hidden = false;
      }
      if (first) {
        first.focus();
        if (first.name === 'selectedDelDay') showDate(first);
      }
      return;
    }
    if (summary) summary.hidden = true;
    sending = true;
    if (submit) submit.disabled = true;
    if (submitText) submitText.textContent = 'Taking you to payment' + String.fromCharCode(8230);
  });

  // Back from the payment page: the button works again
  window.addEventListener('pageshow', function (e) {
    if (!e.persisted) return;
    sending = false;
    if (submit) submit.disabled = false;
    if (submitText) submitText.textContent = submitLabel;
  });

  // Enter in a box doesn't send the form, as on the old page: the address finder uses Enter to pick an address
  form.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && e.target.tagName === 'INPUT') e.preventDefault();
  });

  /* ---- The progress steps follow the part being filled in ---- */
  var steps = root.querySelectorAll('[data-progress-step]');
  function setStep(n) {
    each(steps, function (li) {
      var s = parseInt(li.getAttribute('data-progress-step'), 10);
      li.classList.toggle('is-current', s === n);
      li.classList.toggle('is-done', s < n);
      if (s === n) li.setAttribute('aria-current', 'step'); else li.removeAttribute('aria-current');
    });
  }
  form.addEventListener('focusin', function (e) {
    var section = e.target.closest('[data-step-section]');
    if (section) setStep(parseInt(section.getAttribute('data-step-section'), 10));
    if (datesField && datesField.contains(e.target)) islandRule();
  });

  /* ---- The address finders' search boxes: a label and a hint ---- */
  each(form.querySelectorAll('[data-finder]'), function (box) {
    var labelId = box.getAttribute('data-finder');
    function label() {
      var input = box.querySelector('input.search');
      if (!input) return false;
      input.setAttribute('aria-labelledby', labelId);
      input.setAttribute('placeholder', 'Start typing a postcode or address');
      return true;
    }
    if (!label() && window.MutationObserver) {
      var watch = new MutationObserver(function () { if (label()) watch.disconnect(); });
      watch.observe(box, { childList: true, subtree: true });
    }
  });

  if (postcode && postcode.value) islandRule();   // a saved address
  update();
  arrows();
  showDate(checked('selectedDelDay'));
})();
