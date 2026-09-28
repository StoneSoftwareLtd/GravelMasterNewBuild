# Privacy and terms pages

The privacy policy (`/privacy`) and the terms and conditions (`/term-conditions`) in the new design. Both are linked from every page's footer. There's no Optima prototype for them. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#privacy-and-terms-pages).

## The words stay in the admin site

Both pages are `ContentController.Display` with their own key: `Views/Content/Display.cshtml` shows HTML typed into the admin site. Unlike the delivery page, **their words aren't moved into the code**. They're legal documents that the team keeps up to date (the privacy policy gained a section for the June 2026 data law), so they need to stay editable there.

So the new design is the page around the admin site's words:

- the breadcrumb, with the page's title from the admin site;
- the words in a readable column, 800px at most, in 16px text, with the admin HTML's own heading as the page's title;
- styles for what the admin site's editor makes (headings, paragraphs, lists, bold and links), so any HTML typed there looks right;
- **"On this page"** (`js/gm-legal.js`), once the words have three or more headings: a list of them beside the words on a computer, which stays in view and marks the section being read, and on a phone a list under the title that opens and closes. Without headings, the page is the words alone.

Only these two keys get it. Every other page `Display.cshtml` shows (the old `/about` page, for one) keeps its admin HTML in the old look, as each has its own layout.

## Files

| File | What it is |
|---|---|
| `Views/Content/_LegalPage.cshtml` | the page around the words, as a partial that shows the page's `ContentViewModel` |
| `css/gm-info.css` | the styles, shared with the other information pages; these pages' own are scoped to `.gm-legal` |
| `js/gm-legal.js` | "On this page" |
| `docs/admin-content/privacy.html`, `docs/admin-content/term-conditions.html` | tidied copies of the two pages' words, to paste into the admin site (below) |

## The tidied copies

As they are in the admin site now, the two pages have no real headings or lists. The privacy policy's headings are ordinary lines ending in a colon, its lists are lines starting with "·", and one list is lines split by line breaks; the terms' headings are ordinary lines, each in a box of its own. So both read as one long run of text, with nothing to find your way by, and "On this page" has nothing to list.

[admin-content](admin-content/) has both pages with **the same words, in the same order**, and only the markup changed:

- the privacy policy: 20 headings, 8 subheadings (under "How we use your information") and 18 lists;
- the terms: 17 headings (the numbered sections, "Availability", "Payment" and the rest);
- both: email addresses, phone numbers and ico.org.uk can be tapped; paragraphs that were run together with blank lines are separate paragraphs.

A script checked that the words are the same, word for word and in order (privacy 3,110 words, terms 2,975). The copies keep the old design's two wrapping boxes, so they look right in the old design too (checked: headings and bullet lists, with the same padding as now), and can be pasted in before or after the new design goes live. The preview shows them with `?tidy=1` (`/privacy?tidy=1`).

To use them, someone who looks after the site's legal wording reads them, then pastes each into its page in the admin site, in the editor's HTML (source) view.

## Tested

In the whole-website preview on 28 September 2026, with the admin site's words as they are now and with the tidied copies.

- `_LegalPage.cshtml` compiles with MVC 5.2's Razor. So does `Display.cshtml` with its new code ([merging.md](merging.md#delivery-page)), against stand-ins copied from the repository's `ContentViewModel`. Run with sample data and a stand-in for `_Layout`: with the new design on, `privacy` and `term-conditions` (in any capitals) showed the new page, given the page's model, with `gm-info.css` in the head; `delivery` its own page; `about` and `404-error` their admin HTML as before, with `404-error` still a 404. With the design off, every key showed its admin HTML. The page's title is HTML-encoded and the admin HTML goes in as it is.
- The page the preview shows is character for character the one the compiled partial makes (with the tidied privacy policy).
- In headless Edge: nothing wider than the screen from 1440 to 320px, with the words as they are now and tidied. As they are now, an email address typed as plain text ran 36px off a 390px screen: long words now break.
- "On this page": 20 links for the privacy policy and 17 for the terms, with a unique address each; a link jumps to its heading (just below the header on a phone), which is then marked; on a phone the list starts closed under the title, opens, and closes again after choosing; on a computer it stays in view. No script errors.
- Every text colour passes AA, the lowest 6.4:1.

Not tested: the pages on the test website, and pasting into the admin site's editor (it may tidy the HTML in its own way: check the page after saving).
