# Contact page

The site's contact page, `/contact-us`, in the new design. The footer's "Our sales team" link opens it. There's no Optima prototype for it, so it's in the style of the other information pages (the [delivery](delivery-page.md), [calculator](calculator-page.md) and [FAQ](faq-page.md) pages), with the live page's own words. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#contact-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_ContactPage.cshtml` | the new page, as a partial with no model: plain markup, with the words written in |
| `css/gm-info.css` | the styles, shared with the other information pages; the contact page's own are scoped to `.gm-contact` |

No script: "Track your order" opens the site's own Track Order pop-up, as the header's link does.

## Where the page comes from

`/contact-us` is `ContentController.Display` with the `contact-us` key, which renders `Views/Content/Contact.cshtml`. That view has the words typed into it; the page's title ("Contact Details") and description come from the admin site.

As with the FAQs, the live page is **newer than `Contact.cshtml` on master**: it gives the head office as Meteor House, Finningley, DN9 3GA (master: Unit 10, Hayfield Business Park, DN9 3FL), says the office is closed at weekends and on bank holidays (master: open 8am - 5pm every day and on bank holidays, with customer services closed at weekends), and adds the customer services email. The new page has the live page's words, read on 28 September 2026.

## What the old page shows, and where each part went

| Old page | New page |
|---|---|
| A banner with "Contact us" | The intro band: "Contact us", "Here to help" and the old "Here to help" paragraph |
| "Here to help", "Telephone on 0330 058 5068." and the phone options ("Sales Team - Option 1", "Customer Services - Option 2") | A "Call us" card: the number in large type (tap to call), the two options, and the hours |
| "Or Email sales@gravelmaster.co.uk" and "Customer Services: customerservices@gravelmaster.co.uk" | An "Email us" card with both addresses, labelled (tap to email) |
| Nothing (the old page has the Track Order form commented out) | A "Track your order" card that opens the Track Order pop-up |
| "Large Loads" and "Make the right choice" | Two cards with icons, with the same words, then "Telephone on 0330 058 5068." and "We look forward to hearing from you. Or email sales@gravelmaster.co.uk" |
| "Opening Hours" | The same, as a list: Monday - Friday 8:00am - 5:00pm, Saturday - Sunday closed, bank holidays closed |
| "Head Office": Meteor House, Finningley, DN9 3GA | The same, with "Open in Google Maps" (in a new tab, which screen readers are told) |
| "Map": a Google map of the Doncaster area, centred on the **old** office's postcode (Auckley, DN9 3FL) | A Google map found from the new address, with a pin on Meteor House. It loads only when it's scrolled near, so it doesn't slow the page |
| A photo of an office building (`/images/about-img/office.jpg`) | Left out: it looks like the old Hayfield Business Park office, and it's small and dated |

## Changes to the words

Every heading and paragraph of the live page was checked against the new page by script, ignoring capitals and punctuation: all but two are there word for word. The two:

- "please contact us via our contact form below, or telephone us on: 0330 058 5068" is now "please telephone us on 0330 058 5068": there's no contact form on the page, old or new ([open question](open-questions.md#contact-page));
- the hours say "Monday - Friday 8:00am - 5:00pm" where the live page has "Monday - Wednesday" and "Thursday - Friday" on two lines with the same hours.

New words: "Call us", "Email us", "Sales", "Customer services", "Monday to Friday, 8am - 5pm", "Track your order" with "Already ordered? Check its status with your order ID and postcode.", and "Open in Google Maps".

## Tested

In the whole-website preview (`/contact-us`) on 28 September 2026.

- The partial compiles with MVC 5.2's Razor. So does `Contact.cshtml` with its new branch ([merging.md](merging.md#contact-page)), against stand-ins copied from the repository's `ContentViewModel`. Run with sample data and a stand-in for `_Layout`: with the new design on, it showed the new page with `gm-info.css` in the head, and not the old page; off, the old page. The `404-error` key still sets the 404 status. The first compile found a real fault: an `@` straight before `<wbr>` (to let the long email address break after the @) is Razor code, so it's written `&#64;`.
- The page the preview shows is character for character the one the compiled partial makes.
- The words (above).
- In headless Edge: screenshots at 1440, 800, 390 and 375px; nothing wider than the screen at 12 widths from 1440 to 320px; the customer services address breaks after the @ when it has to (768, 700, 375 and 320px), not inside a word.
- The map loaded with the pin on Meteor House. "Track your order" opened the Track Order pop-up without changing the address. The links are the phone number, the two email addresses and Google Maps; no script errors.
- Every text colour passes AA, the lowest 4.8:1 (the "Contact us" label).

Not tested: the page on the test website, and the map with the site's cookie banner (the old page's map loads the same way).
