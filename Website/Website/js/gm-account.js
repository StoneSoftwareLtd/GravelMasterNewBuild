/* ===== GravelMaster account pages (Optima design) =====
   Views/Account/_SignInPage, _ForgotPasswordPage and _ResetPasswordPage. The forms post exactly what the old pages'
   forms did; this only helps on the way:
   - checks each form before it's sent, with a message under the box (required boxes, email, the password's length,
     the two passwords matching, the trade form's phone number starting with 0, the choices and the terms). The trade
     check matters: the server quietly drops an application whose phone number doesn't start with 0 or has a +, or
     whose payment type wasn't chosen, while still saying thank you;
   - shows and hides a password;
   - switches between the personal and trade forms;
   - when the page comes back with errors (or opened for a trade account), moves to them;
   - sends each form once;
   - on the My Account pages: fills in the Track Order pop-up, shows the refund note on the return form, and sends a
     price match message without leaving the page.
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var root = document.querySelector('.gm-account[data-account]');
  if (!root) return;

  function each(list, fn) { Array.prototype.forEach.call(list, fn); }
  var ellipsis = String.fromCharCode(8230);
  var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  /* ---- Show or hide a password ---- */
  each(root.querySelectorAll('[data-show-password]'), function (btn) {
    var input = document.getElementById(btn.getAttribute('aria-controls'));
    if (!input) return;
    btn.addEventListener('click', function () {
      var show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      btn.textContent = show ? 'Hide' : 'Show';
      btn.setAttribute('aria-pressed', show ? 'true' : 'false');
      input.focus();
    });
  });

  /* ---- Personal or trade ---- */
  var kinds = root.querySelectorAll('[data-kind]');
  function showKind() {
    each(kinds, function (radio) {
      var form = root.querySelector('[data-kind-form="' + radio.value + '"]');
      if (form) form.hidden = !radio.checked;
      radio.closest('.acc-kind').classList.toggle('is-checked', radio.checked);   // for browsers without :has()
    });
  }
  each(kinds, function (radio) { radio.addEventListener('change', showKind); });
  if (kinds.length) showKind();

  /* ---- Checking a form ---- */
  function messageFor(input) {
    if (input.type === 'checkbox') return input.required && !input.checked ? input.getAttribute('data-msg-required') : '';
    var value = input.value.trim();
    if (!value) return input.required ? input.getAttribute('data-msg-required') : '';
    var min = parseInt(input.getAttribute('minlength'), 10), max = parseInt(input.getAttribute('maxlength'), 10);
    if ((min && input.value.length < min) || (max && input.value.length > max)) return input.getAttribute('data-msg-length');
    var pattern = input.getAttribute('pattern');
    if (pattern && !new RegExp('^(?:' + pattern + ')$').test(input.value)) return input.getAttribute('data-msg-pattern');
    if (input.type === 'email' && !emailPattern.test(value)) return input.getAttribute('data-msg-email');
    var match = input.getAttribute('data-match');
    if (match && document.getElementById(match) && input.value !== document.getElementById(match).value) return input.getAttribute('data-msg-match');
    return '';
  }
  function errorFor(input, make) {
    var id = input.id + '-error';
    var msg = document.getElementById(id);
    if (!msg && make) {
      msg = document.createElement('p');
      msg.className = 'acc-error';
      msg.id = id;
      var after = input.type === 'checkbox' ? input.closest('.acc-check') : (input.closest('.acc-password') || input);
      after.parentNode.insertBefore(msg, after.nextSibling);
    }
    return msg;
  }
  function describedBy(input, id, on) {
    var ids = (input.getAttribute('aria-describedby') || '').split(/\s+/).filter(function (x) { return x && x !== id; });
    if (on) ids.push(id);
    if (ids.length) input.setAttribute('aria-describedby', ids.join(' '));
    else input.removeAttribute('aria-describedby');
  }
  function check(input) {
    var text = messageFor(input);
    var msg = errorFor(input, !!text);
    if (text) {
      msg.textContent = text;
      msg.hidden = false;
      input.setAttribute('aria-invalid', 'true');
      describedBy(input, msg.id, true);
    } else {
      input.removeAttribute('aria-invalid');
      if (msg) { msg.hidden = true; describedBy(input, msg.id, false); }
    }
    return text;
  }
  function fields(form) {
    return [].slice.call(form.querySelectorAll('input, select, textarea')).filter(function (input) {
      return input.type !== 'hidden' && !input.readOnly && !input.disabled && input.id;
    });
  }

  each(root.querySelectorAll('[data-account-form]'), function (form) {
    form.noValidate = true;   // this script checks the form itself, with a message under each box
    var button = form.querySelector('button[type="submit"]');
    var label = button ? button.textContent : '';
    var sending = false;

    // a box with a message is checked again as it changes; any box is checked when left with something in it
    form.addEventListener('input', function (e) {
      if (e.target.getAttribute('aria-invalid') === 'true') check(e.target);
      var other = form.querySelector('[data-match="' + e.target.id + '"]');   // the confirmation of this password
      if (other && other.getAttribute('aria-invalid') === 'true') check(other);
    });
    form.addEventListener('change', function (e) {
      if (e.target.tagName === 'SELECT' || e.target.type === 'checkbox') check(e.target);
    });
    form.addEventListener('focusout', function (e) {
      var t = e.target;
      if (t.tagName === 'INPUT' && t.type !== 'checkbox' && t.id && t.value.trim()) check(t);
    });

    form.addEventListener('submit', function (e) {
      if (sending) { e.preventDefault(); return; }
      var first = null;
      fields(form).forEach(function (input) {
        if (input.type !== 'password' && input.value !== input.value.trim()) input.value = input.value.trim();
        if (check(input) && !first) first = input;
      });
      if (first) {
        e.preventDefault();
        first.focus();
        return;
      }
      sending = true;
      if (button) {
        button.disabled = true;
        button.textContent = (button.getAttribute('data-busy-text') || label) + ellipsis;
      }

      // Price match: the message goes to /product/sendpricematchquery as the old page sent it, now encoded so a
      // message with & or # arrives whole, and the page stays where it is
      if (form.hasAttribute('data-pricematch')) {
        e.preventDefault();
        var status = form.querySelector('[data-status]');
        var box = form.querySelector('textarea');
        var done = function (text) {
          if (status) status.textContent = text;
          sending = false;
          if (button) { button.disabled = false; button.textContent = label; }
        };
        if (status) status.textContent = '';   // so the same answer twice is still read out
        fetch(form.getAttribute('action') + '?query=' + encodeURIComponent(box.value), { credentials: 'same-origin' })
          .then(function (res) { if (!res.ok) throw new Error(res.status); return res.json(); })
          .then(function () { box.value = ''; done('Thank you, your message has been sent.'); })
          .catch(function () { done('Sorry, your message couldn' + String.fromCharCode(8217) + 't be sent. Please try again, or call us on 0330 058 5068.'); });
      }
    });

    // Back from the next page: the button works again
    window.addEventListener('pageshow', function (e) {
      if (!e.persisted) return;
      sending = false;
      if (button) { button.disabled = false; button.textContent = label; }
    });
  });

  /* ---- Track order: the site's Track Order pop-up (_TrackOrderModal, opened by Bootstrap's data-toggle), filled in ---- */
  each(root.querySelectorAll('[data-track]'), function (link) {
    link.addEventListener('click', function (e) {
      e.preventDefault();   // the link is only there to open the pop-up
      var modal = document.getElementById('trackModal');
      if (!modal) return;
      var order = modal.querySelector('input[name="orderId"]');
      var postcode = modal.querySelector('input[name="postcode"]');
      if (order) order.value = link.getAttribute('data-order') || '';
      if (postcode) postcode.value = link.getAttribute('data-postcode') || '';
    });
  });

  /* ---- Return request: the note about refunds, when a refund is asked for ---- */
  each(root.querySelectorAll('[data-refund-select]'), function (select) {
    var note = select.parentNode.querySelector('[data-refund-note]');
    if (!note) return;
    var show = function () { note.hidden = select.value !== 'Full Refund'; };
    select.addEventListener('change', show);
    show();
  });

  /* ---- Back with errors, or opened for a trade account: go to them ----
     Once the page has loaded, so gm-chrome.js has told the browser how much of the top the header covers on phones */
  function goToFocus() {
    var focus = root.getAttribute('data-focus');
    var target = focus && document.getElementById(focus);
    if (!target) return;
    var covered = parseFloat(getComputedStyle(document.documentElement).scrollPaddingTop) || 0;
    var top = target.getBoundingClientRect().top;
    if (top < covered || top > window.innerHeight * 0.5) target.scrollIntoView({ block: 'start' });   // only when it's out of sight
    target.focus({ preventScroll: true });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', goToFocus);
  else goToFocus();
})();
