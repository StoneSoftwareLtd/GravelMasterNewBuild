# Calculator page

The site's gravel calculator page, `/calculator`, in the new design. The header's "Quantity calculator" and the "Use our calculator" button in five of the category menus open it. There's no Optima prototype for it, so it's in the Trade Accounts page's style around the new pages' shared quantity calculator, with the live page's own words. Built on 25 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#calculator-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_CalculatorPage.cshtml` | the new page, as a partial that shows a `CalculatorPageModel` |
| `ViewModels/Common/CalculatorPageModels.cs` | `CalculatorPageModel`: the calculator, the three gravels and the bulk enquiry pop-up's categories |
| `css/gm-info.css` | the styles, shared with the [delivery page](delivery-page.md) |
| `Views/Shared/_QuantityCalculator.cshtml`, `css/gm-calc.css`, `js/gm-calc.js` | the shared calculator, as on the homepage and product pages |
| `Views/Shared/_BulkEnquiryModal.cshtml` | the shared bulk enquiry pop-up that the calculator's "Enquire Here" opens |

## The calculator

The live page's calculator is four tabs (Gravel & Chippings, Barks & Mulches, Topsoil, Sand), each with its own formula, and an Email Results box that posts to `/email/sendcalculatorcalculation`. The shared calculator built for the homepage already has exactly these: its four types use the live page's formulas and it posts the same fields. On 25 September 2026 the live page's four formulas and its email function were checked to be the same as the repository's. So the new page uses the shared calculator as it is, opening on Gravel & Chippings as the old page did.

Checked on the new page: 5m by 5m at 4cm of gravel gives 1,700kg, 2 one-tonne pallets or 3 bulk bags, which matches the formula and the page's own FAQ ("approximately three bulk bags"). Topsoil gives 1.5 tonnes, 2 pallets or 2 bulk bags.

The calculator sits inside the page's `.gm-info` wrapper, as it sits inside the homepage's: its stylesheet relies on the page's shield. On its own, the old site's heading colour made its title pale green on its green background.

## What the old page shows, and where each part went

Read from `Views/Content/Calculator.cshtml` (the same on `master` and the live page).

| Old page | New page |
|---|---|
| "Gravel Calculator", "Calculate how much gravel you need" and the paragraph under it | The intro band, with the same words |
| The four-tab calculator, a black line drawing of an area, and Email Results | The shared calculator (above). The drawing is replaced by a new one of an area with its length, width and depth marked, beside the "How do you calculate" text |
| Three gravels with their photos: Cotswold Chippings 20mm, Panda Gravel 20mm, Black Basalt 20mm | "Popular gravels": the same three, as cards with their "From" prices (customer or trade, by `_Layout`'s check) and "Shop now". One that's no longer on sale is left out |
| Four pictures with their words drawn in, linking to the delivery page, special offers, Trustpilot and gravels | "Before you order": four cards with the same links, and words as text. The pictures' "Fast FREE nationwide delivery" and "The UK's No.1 Aggregates Supplier" are left out ([open question](open-questions.md#calculator-page)) |
| "How do you calculate how much gravel is needed?" and its two paragraphs | The same, beside the new drawing. The "slate" link goes to the Slate Chippings page's own address (`/garden-chippings/slate-chippings/products/`; the old `/slate-chippings/products/` shows the same page) |
| "Gravel & Slate Calculator FAQs": six questions and answers | The same six, as questions that open and close (the first open), with "Can't find your answer? Call us 8am - 5pm on 0330 058 5068" |

Every heading and paragraph of the live page's text was checked against the new page in the preview, ignoring capitals and punctuation: all 21 are there word for word.

## Tested

In the whole-website preview (`/calculator`) on 25 September 2026. The three gravels come from the preview's copy of the live site's products (`data.json`).

- The partial compiles with MVC 5.2's Razor. So does `Calculator.cshtml` with its new branch ([merging.md](merging.md#calculator-page)), against stand-ins copied from the repository's `ContentViewModel`, `MasterLayoutViewModel` (with the homepage's `GetHomeProduct`) and `CategoryViewModel`. Run with sample data: with the new design on it built the model (a product `GetHomeProduct` doesn't find left out, the categories in menu order) and showed the new page; off, the old page.
- The words: all of the live page's text is on the new page (above).
- In headless Edge: screenshots at 1440 and 390px; nothing wider than the screen at 12 widths from 1440 to 320px. At 320px the shared calculator's type list ran 29px off the screen, as it did on the homepage and product pages: fixed for all three in its own commit.
- Every text colour passes AA, the lowest 4.5:1 (the product names, large text needing 3:1); the drawing's words 13.3:1.
- The calculator's results (above); "Enquire Here" opened the bulk enquiry pop-up with focus inside it, and Escape closed it; the FAQs opened and closed; the product photos loaded; no script errors.

Not tested: "Send me my estimate" and the bulk enquiry for real (blocked in the preview, as on the homepage), and trade prices with a trade login. These need the test website.
