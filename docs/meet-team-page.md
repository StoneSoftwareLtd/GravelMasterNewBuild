# Meet the team page

The site's `/meet-the-team` page in the new design. There's no Optima prototype for it, so it's in the information pages' style. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#meet-the-team-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_MeetTeamPage.cshtml` | the new page, as a partial with no model: the people are written into it (as the old view has them) |
| `css/gm-info.css` | its styles (`.gm-team`), with the other information pages' |
| `js/gm-team.js` | the department buttons |
| `img/gm-team-*.jpg` | the 17 photos, from the live page's, as 450 × 490 JPEGs: 495 KB for all 17, down from about 4 MB (most were 300-400 KB PNGs) |

## What the old page shows, and where each part went

Read from the live page on 28 September 2026.

| Old page | New page |
|---|---|
| A banner with "Meet the team", and the introduction as one paragraph | "Meet the team" under the breadcrumb (Home › About us › Meet the team), and the same words as two paragraphs |
| "Sort by:" with 7 departments in a drop-down. Customer Service and Marketing and Development had nobody in them | Buttons: Everyone, then the 6 departments with people in, in the same order. The two customer service managers (Jessica Shadlock, Kieran Blagden) are now in Customer service as well as Management. Without JavaScript, everyone shows and the buttons stay hidden |
| 17 cards: photo, name and job, in that order | The same 17, in the same order, with the same names and jobs, 4 to a row (3, then 2 on smaller screens) |
| Pop-up biographies for 8 people, opened from their cards. Only 4 could be opened (Mollie, Rhiannon, Lianne and Jessica); two of those gave older jobs than their cards, and the other 4 were for people no longer on the page. They also had staff email addresses | Left out ([open question](open-questions.md#the-last-pages)) |
| Nothing else | "Talk to the team": call us Monday to Friday, 8am - 5pm, and Contact us |

## Tested

In the whole-website preview (`/meet-the-team`) on 28 September 2026.

- The partial compiles with MVC 5.2's Razor, and so does `MeetTeam.cshtml` with its new branch, which ran with sample data: with the design on it shows the new page, with `gm-info.css` in the head. (Its old branch can't run outside IIS in the harness, because of its `~/img` addresses.)
- The preview's page is the same markup as the compiled partial.
- The words: the 17 names and jobs are the live page's, in the same order, and both halves of the introduction are there word for word.
- In headless Edge:
  - each button showed the right people (Everyone 17, Management 10, Sales 2, Customer service 2, Transport 1, Production 8, Accounts 2), was marked as pressed, and said how many to screen readers;
  - all 17 photos loaded;
  - nothing wider than the screen at 8 widths from 1440 to 320px;
  - no script errors.
- Colours: the jobs 7:1, the buttons 13.3:1 (6.4:1 when pressed).

Not tested: the page on the test website.
