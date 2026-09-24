/* ===== GravelMaster About us page (Optima design) =====
   Views/Content/_AboutPage.cshtml: "Meet the team" scrolls sideways where the cards don't all fit (phones).
   The arrows move it one card at a time and the bar shows how far along it is; where every card fits, the arrows
   and bar stay hidden, as they'd do nothing. Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var root = document.querySelector('.gm-about');
  if (!root) return;

  var track = root.querySelector('[data-team]');
  var nav = root.querySelector('[data-team-nav]');
  if (!track || !nav) return;
  var bar = nav.querySelector('[data-team-progress]');
  var prev = nav.querySelector('[data-team-prev]');
  var next = nav.querySelector('[data-team-next]');

  function step() {
    var cards = track.querySelectorAll('.abt-member');
    if (cards.length > 1) return cards[1].getBoundingClientRect().left - cards[0].getBoundingClientRect().left;
    return track.clientWidth;
  }

  function update() {
    var max = track.scrollWidth - track.clientWidth;
    nav.hidden = max <= 1;
    if (nav.hidden) return;
    bar.style.width = (track.clientWidth / track.scrollWidth * 100) + '%';
    bar.style.left = (track.scrollLeft / track.scrollWidth * 100) + '%';
    prev.disabled = track.scrollLeft <= 1;
    next.disabled = track.scrollLeft >= max - 1;
  }

  prev.addEventListener('click', function () { track.scrollBy({ left: -step(), behavior: 'smooth' }); });
  next.addEventListener('click', function () { track.scrollBy({ left: step(), behavior: 'smooth' }); });
  track.addEventListener('scroll', update, { passive: true });
  // the row's own size, so a rotated phone or a resized window shows or hides the arrows
  if (window.ResizeObserver) new ResizeObserver(update).observe(track);
  else window.addEventListener('resize', update);
  update();
})();
