# About us page

The Optima prototype's About page (`about.html` in GravelMasterDesigns), rebuilt for the site's `/about-us` page. Built on 24 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#about-us-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_AboutPage.cshtml` | the new page, as a partial with no model: the live page has no data from the database either, only text written into its view |
| `css/gm-about.css` | its styles, scoped to `.gm-about`, with the same shield against the old CSS as the other new pages. The prototype's `abt2-hero`, `.ins` and `.reviews` classes are renamed `abt-hero`, `abt-ins` and `abt-reviews` so the old site's classes can't reach them |
| `js/gm-about.js` | the "Meet the team" arrows and progress bar |
| `img/gm-about-intro.jpg` | the hero photo |
| `img/gm-about-team-*.jpg` | the six team photos |

The inspiration photos are the homepage's (`img/gm-home-insp-*`): they're the same files as the prototype's. The handwritten lines use the Caveat font from Google Fonts, which `AboutUs.cshtml` loads with the stylesheet.

## What the live page has, and where each part went

Read from `Views/Content/AboutUs.cshtml` (routed by `ContentController` for the `about-us` key) and the live page on 24 September 2026. The live page's reviews differ from the repository's copy, another sign that the repository isn't what's deployed ([merging.md](merging.md#before-anything-which-code-is-live)).

| Live page | New page |
|---|---|
| "About Us" and two paragraphs (leading supplier; "31-years of experience") | The prototype's hero: "Over 15 years experience", its subheading, then the live page's two paragraphs, word for word. The prototype had shortened the second one |
| Links down the left: The Team, Delivery, FAQ, Contact us, About | Left out, as in the prototype. The header and footer link to Delivery and the FAQs, and the footer has the contact details; "View all team members" goes to the team page |
| A carousel of four product photos, and four photos of the despatch area, office, forklift and a member of staff | Left out: the prototype has one hero photo. See [open-questions.md](open-questions.md#about-us-page) |
| "The group of companies was founded in 1988...", "Whatever the product, wherever the place..." and "As a family business..." | "What Makes Us Different?", in place of the prototype's placeholder (lorem ipsum) text, with the prototype's five-point list |
| Four customer reviews with photos, written into the page | The homepage's reviews band, with the real Trustpilot widgets (latest 4 and 5 star reviews) |
| "Professional service with an unbeatable price", with Experienced since 1988, Our Promise, Commitment, and Queries and Advice | Left out: the prototype has no place for it, and "What Makes Us Different?" covers the same ground. See open questions |
| A delivery photo at the bottom | Left out |
| Not on the live page | The prototype's trust row, figures band ("15+ years", "Thousands" of customers...), "Meet the team" (its six people, with the jobs the live team page gives them) and "Find your inspiration" (linking to Ideas & Advice) |

"Shop our range" goes to Gravels & Chippings, the first category in the menu.

## Changed from the prototype

- **Colours**, measured against what's behind them, as on the other pages. White text on the "What Makes Us Different?" blue was 2.8:1. The blue is darkened just enough for 4.5:1 (`#08a5de` to `#007db5`, and its diagonal shape to match). The "Since 2008" badge was 60% see-through, so bright parts of the photo showed through behind its white text; it's now a deeper green, 88% solid (4.9:1). Buttons with white text use the dark green (`#2f6b34`) rather than the main green (3.0:1). Every text colour on the page now passes WCAG AA.
- **Two CSS mistakes in the prototype.** On phones and tablets the trust row was meant to come after the photo, but a stronger rule put it above. And the "About Gravelmaster" label was meant to be small green capitals, but the hero's paragraph rule turned it into grey body text. Both now look as their rules intended.
- **Team arrows.** In the prototype they show on every screen but only do anything on phones, where the cards scroll sideways. Now they show only when there's something to scroll. They're disabled at either end, and they appear or hide when the window is resized or a phone is turned.
- **Photos.** The hero photo and team photos were 2.1 MB together (a PNG and six large JPEGs). They're 208 KB now, at the same sizes. Photos below the first screen load as they're scrolled to.

## Tested

In the whole-website preview (`/about-us`), on 24 September 2026:

- the partial compiles with MVC 5.2's own Razor;
- screenshots at 1440, 1024, 768 and 390px wide, with nothing wider than the screen;
- every text colour measured against its background (all pass AA);
- "Meet the team" on a phone: each Next click moves one card, the bar follows, Previous is disabled at the start and Next at the end; resizing to desktop hides the arrows and back to phone shows them.

Not tested: the Trustpilot widgets load but show nothing in the preview, probably because Trustpilot only fills them on the real site's address. They're the homepage's widgets, unchanged.
