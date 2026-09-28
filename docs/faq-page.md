# FAQ page

The site's FAQ page, `/faq`, in the new design. The footer's "FAQs" link opens it. There's no Optima prototype for it, so it's in the style of the other information pages (the [delivery](delivery-page.md) and [calculator](calculator-page.md) pages), with the live page's own questions and answers. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#faq-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_FaqPage.cshtml` | the new page, as a partial with no model: its questions and answers are written into its C# block, one line each, under their topics |
| `css/gm-info.css` | the styles, shared with the delivery and calculator pages; the FAQ page's own are scoped to `.gm-faqpage` |
| `js/gm-faq.js` | the search box |

## Where the page comes from

`/faq` is `ContentController.Display` with the `faq` key, which renders `Views/Content/FAQ.cshtml`. That view has the questions and answers typed into it; the only thing it takes from the admin site is the "FAQ" banner at the top (the content's HTML) and the page's title and description.

The live page's words are **newer than the view on GravelMasterSoftware's `master`**: the live page names Palletforce as the haulier (master: Mitchells), charges £80 a pallet for returns (master: £50), takes 14 working days for refunds (master: 3-5), has a £25 cancelling fee, and has one more question ("Are your products washed?"). So the code that's live isn't on master, as found before ([merging.md](merging.md#before-anything-which-code-is-live)). The new page has the live page's words, read on 28 September 2026.

## What the old page shows, and where each part went

| Old page | New page |
|---|---|
| A banner with "FAQ" (from the admin site) | The intro band: "Help and support", "Frequently asked questions" and the page's description ("A list of questions we get asked that may help you resolve any issues quicker."), with a search box |
| A list of the five topics down the side, which stays in view | The same five topics, which stay in view beside the questions, each with how many questions it has. On phones they're a row of buttons above the questions |
| Five headed sections ("1. Questions about Orders" and so on) of 47 questions that open and close, all closed | The same five sections, headed without the numbers, and the same 47 questions, all closed. The sections keep their addresses (`#q1` to `#q5`), so links to `/faq#q2` still land on delivery |
| Nothing | "Can't find your answer?": the phone number, "Email us" and "Track your order" (the header's Track Order pop-up). Beside the topics, or under the questions on phones |

## The search

A box at the top: as you type, only the questions whose question or answer has every word you've typed stay. Topics with nothing left disappear, with their link at the side; the counts beside the topics show how many are left; a line under the box says how many match (and screen readers read it out). With no match, the page says so and gives the phone number. Clearing the box shows everything again.

The box is hidden until the script runs: without it, every question shows, as on the old page.

## Changes to the words

Every question and answer was checked against the live page by script, in order, ignoring capitals and punctuation: 38 of the 47 are word for word, and the other nine differ only by these spelling fixes:

- "unfortunatley" to "unfortunately", "restrictons" to "restrictions", "cant" to "can't";
- "pay pal" to "PayPal" (twice), "trust pilot" to "Trustpilot";
- "the are you wish to cover" to "the area you wish to cover", "aim to delivery your products" to "aim to deliver your products", "the deliver postcode" to "the delivery postcode";
- the quote marks taken off "‘ accounts@gravelmaster.co.uk’".

Also: question marks on the questions that had none, and headings and questions in sentence case, not capitals. Phone numbers and email addresses can be tapped, "gravel calculator" links to the calculator, "Customer Services" to its email address, and Trustpilot to the reviews (in a new tab, which screen readers are told).

The answers still disagree with other pages in places: see [open-questions.md](open-questions.md#faq-page).

## Tested

In the whole-website preview (`/faq`) on 28 September 2026.

- The partial compiles with MVC 5.2's Razor. So does `FAQ.cshtml` with its new branch ([merging.md](merging.md#faq-page)), against stand-ins copied from the repository's `ContentViewModel`. Run with sample data and a stand-in for `_Layout`: with the new design on, it showed the new page with `gm-info.css` in the head, and not the old page or its banner; off, the old page. The `404-error` key still sets the 404 status. The title and description still come from the admin site.
- The page the preview shows is character for character the one the compiled partial makes.
- The words: all 47 questions and answers (above).
- In headless Edge: screenshots at 1440, 1000 and 390px; nothing wider than the screen at 12 widths from 1440 to 320px; the search box's example text fits at every width.
- The search: "cancel" left 2 questions in 2 topics, "next day" 3 in Delivery, "PALLETFORCE" 1 (capitals don't matter), "xyzzy" none, with the message and no topic links; clearing it brought back all 47 and the counts 10, 21, 5, 6 and 5. The same at 390px.
- The topic links: each heading landed 20px from the top of the screen on a computer, and 32px below the header on a phone (the header stays at the top there).
- A question opened and closed; "Track your order" opened the Track Order pop-up; no script errors.
- Every text colour passes AA, the lowest 4.8:1 (the "Help and support" label); the search box's border 3.2:1.

The answers' text is now 16px in all the information pages' questions, so the calculator page's six FAQs changed too: checked there at 1440 and 320px.

Not tested: the page on the test website.
