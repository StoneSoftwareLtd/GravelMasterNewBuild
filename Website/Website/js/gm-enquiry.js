/* ===== "Request a bulk delivery" pop-up (Optima design) =====
   Views/Shared/_BulkEnquiryModal.cshtml, shared by the new homepage and category page. Any element with
   data-bulk-open opens it. The form posts the same fields as the product page's quick enquiry (#miniForm)
   to /basket/sendlooseenquiry.
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var modal = document.getElementById('bulkModal');
  if (!modal || !modal.classList.contains('gm-enquiry')) return;
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

  document.addEventListener('click', function (e) {
    var trigger = e.target.closest ? e.target.closest('[data-bulk-open]') : null;
    if (trigger) open(e);
  });
  modal.querySelectorAll('[data-bulk-close]').forEach(function (el) {
    el.addEventListener('click', close);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !modal.hidden) close();
  });

  // The Product list shows the chosen category in its colour
  var select = modal.querySelector('select[data-colour-select]');
  if (select) {
    var colour = function () {
      var opt = select.options[select.selectedIndex];
      select.style.color = (opt && opt.getAttribute('data-color')) || '';
    };
    select.addEventListener('change', colour);
    colour();
  }

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
      if (select) select.style.color = '';
    }).catch(function () {
      status.textContent = 'Sorry, that didn’t send. Please try again or call 0330 058 5068.';
    }).then(function () {
      button.disabled = false;
    });
  });
})();
