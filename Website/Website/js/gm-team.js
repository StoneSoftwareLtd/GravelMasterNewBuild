/* ===== GravelMaster Meet the team page (Optima design) =====
   Views/Content/_MeetTeamPage.cshtml: the department buttons show one department's people at a time (each card's
   data-departments), and say how many for screen readers. Without this script every card shows and the buttons stay
   hidden. Plain JavaScript: the site's jQuery arrives later through RequireJS. */
(function () {
  var root = document.querySelector('.gm-team');
  if (!root) return;
  var filter = root.querySelector('[data-team-filter]');
  var status = root.querySelector('[data-team-status]');
  var cards = root.querySelectorAll('.team-card');
  if (!filter || !cards.length) return;
  var buttons = filter.querySelectorAll('[data-department]');

  function show(department, button) {
    var count = 0;
    Array.prototype.forEach.call(cards, function (card) {
      var inIt = !department || (' ' + card.getAttribute('data-departments') + ' ').indexOf(' ' + department + ' ') >= 0;
      card.hidden = !inIt;
      if (inIt) count++;
    });
    Array.prototype.forEach.call(buttons, function (b) { b.setAttribute('aria-pressed', b === button ? 'true' : 'false'); });
    if (status) status.textContent = department ? 'Showing ' + count + (count === 1 ? ' person' : ' people') + ' in ' + button.textContent : 'Showing everyone';
  }

  Array.prototype.forEach.call(buttons, function (b) {
    b.addEventListener('click', function () { show(b.getAttribute('data-department'), b); });
  });
  filter.hidden = false;
})();
