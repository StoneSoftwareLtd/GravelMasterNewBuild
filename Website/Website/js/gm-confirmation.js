/* ===== GravelMaster order confirmation (Optima design) =====
   Views/Checkout/_ConfirmationPage.cshtml.
   - "Track your order" opens the site's Track Order pop-up (_TrackOrderModal, through Bootstrap's data-toggle) and
     fills in its order number and postcode.
   - "Add to basket" on a suggestion calls /basket/addtobasket as the basket page's suggestions do, then goes to the
     basket. It never reloads this page: loading /checkout/orderresult isn't only a page view, it marks the order as paid.
   - A photo that doesn't load leaves its pale box.
   Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var root = document.querySelector('.gm-confirm');
  if (!root) return;

  function each(list, fn) { Array.prototype.forEach.call(list, fn); }
  var ellipsis = String.fromCharCode(8230);
  var apostrophe = String.fromCharCode(8217);

  each(root.querySelectorAll('.cnf-rec__img'), function (img) {
    var blank = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    function missing() { if (img.src !== blank) img.src = blank; }
    if (img.complete && img.naturalWidth === 0) missing();
    else img.addEventListener('error', missing);
  });

  /* ---- Track your order ---- */
  var track = root.querySelector('[data-track]');
  if (track) {
    track.addEventListener('click', function (e) {
      e.preventDefault();   // the link is only there to open the pop-up
      var modal = document.getElementById('trackModal');
      if (!modal) return;
      var order = modal.querySelector('input[name="orderId"]');
      var postcode = modal.querySelector('input[name="postcode"]');
      if (order && !order.value) order.value = track.getAttribute('data-order') || '';
      if (postcode && !postcode.value) postcode.value = track.getAttribute('data-postcode') || '';
    });
  }

  /* ---- Add a suggestion, then go to the basket ---- */
  var area = root.getAttribute('data-postal-area') || '';
  var status = root.querySelector('[data-status]');
  var buttons = root.querySelectorAll('[data-add]');
  each(buttons, function (btn) {
    btn.addEventListener('click', function () {
      each(buttons, function (b) { b.disabled = true; });
      if (status) status.textContent = 'Adding to your basket' + ellipsis;
      var url = '/basket/addtobasket?id=' + encodeURIComponent(btn.getAttribute('data-add')) + '&qty=1' +
        '&postcodeData=' + encodeURIComponent(area) +
        '&selectedVariantCode=' + encodeURIComponent(btn.getAttribute('data-variant')) + '&basketView=1';
      fetch(url, { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } })
        .then(function (res) {
          if (!res.ok) throw new Error(res.status);
          location.href = '/basket';
        })
        .catch(function () {
          each(buttons, function (b) { b.disabled = false; });
          if (status) status.textContent = 'Sorry, that couldn' + apostrophe + 't be added. Please try again, or call us on 0330 058 5068.';
        });
    });
  });
})();
