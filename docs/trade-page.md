# Trade Accounts page

The Optima prototype's trade page (`trade.html` in GravelMasterDesigns), rebuilt for the site's `/trade` page. Built on 24 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#trade-accounts-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_TradePage.cshtml` | the new page, as a partial with no model: the live page has nothing from the database either |
| `css/gm-trade.css` | its styles, scoped to `.gm-trade`, with the same shield against the old CSS as the other new pages. The prototype's `.reviews` classes are renamed `trd-reviews` |
| `img/gm-trade-hero.jpg` | the hero photo: the forklift photo the live trade page already uses |
| `img/gm-trade-why.jpg` | the "Why Choose Gravel Master?" photo |
| `img/gm-trade-pinky.png` | the perks band's background |

There's no script: the FAQs are `<details>`, which open and close by themselves, with the keyboard too.

## Where the words come from

The prototype's perks, "Why Choose Gravel Master?" and FAQ answers were placeholder text (lorem ipsum). The new page uses only things the live site says or does:

- **The live trade page** (`Views/Content/Trade.cshtml`): "We supply thousands of trade customers per year at great prices!", the "leading supplier" paragraph, and its six "Why us?" points, which are pictures with the words built in: Nationwide Delivery, Loose Load Tipper, Trade Discount, Account Manager, Dedicated Bagging and Free Samples.
- **The live trade sign-up form** (the Trade tab of `/account/login?isTradeRegister=true`, which the old page's "Request a Trade Account" button opens): the details it asks for (name, email, phone, company, type of customer, and payment type, credit or cash), its customer types (landscaper or contractor, builder, builders' merchant, garden designer, roofer, other), and its note that requests are reviewed and the outcome emailed.
- **The site's code**: a trade login gets trade prices on the product pages and in the basket (`ProductController` and `BasketController` use `ProductPrice.GetTradePrice` for trade users).
- **The footer**: the phone number, and option 1 for the sales team.

| Prototype | New page |
|---|---|
| Hero, with "Open a trade account" and "Speak to our trade team" | The prototype's words. "Open a trade account" goes to the trade sign-up form, as the old page's button did; "Speak to our trade team" to Contact us |
| Perks: Exclusive Pricing, Priority Support, Free Samples, with placeholder text | The same three, matching the live page's Trade Discount, Account Manager and Free Samples, with a line each from the facts above |
| "Why Choose Gravel Master?": placeholder paragraph and five points | The live page's two paragraphs. The points: the prototype's "High-quality aggregates", "Nationwide delivery", "Trusted by landscapers, builders and contractors" and "Expert advice when you need it", plus the live page's "Loose load tipper deliveries" and "Dedicated bagging". The prototype's "Reliable stock availability" is left out: the site's FAQ says some products can be out of stock for weeks |
| FAQs: five questions, placeholder answers | The same five questions, answered from the facts above |
| "Get trade prices" | Goes to the trade sign-up form |
| Reviews, typed into the page | The homepage's reviews band, with the real Trustpilot widgets |

The live page's six "Why us?" pictures aren't used: the prototype has no place for them, and their words are covered by the perks, the list and the FAQs.

## Changed from the prototype

- **Colours**, measured against what's behind them. White text on the "Why Choose" greens was 3.0 to 3.7:1, so the greens are darkened just enough for 4.5:1 (the lighter blob to `#37843b`, the band to `#2f7a33`). The "Trade Accounts" label was 3.9:1 on the card, now 4.8:1. Buttons with white text use the dark green (`#2f6b34`) rather than the main green (3.0:1). Every text colour on the page now passes WCAG AA.
- **The hero title** scales with the window above 860px wide. At the prototype's fixed sizes, "on." dropped onto a line of its own from 861 to about 1070px wide (at 1024px, for example) and just above 1100px (measured). It's now two lines at every width there, reaching the prototype's 34px at about 1240px.
- **The photo's description** said "Loader filling a tipper truck"; the photo is a forklift carrying a Gravel Master bulk bag.
- **The FAQs** are `<details>`: each opens and closes on its own, with the mouse or keyboard, and the arrow flips. The first starts open, as in the prototype.
- **Photos**: the hero and "Why" photos are 117 KB together instead of 247 KB, at the same sizes.

## Tested

In the whole-website preview (`/trade`), on 24 September 2026:

- the partial compiles with MVC 5.2's own Razor;
- screenshots at 1440, 1024, 768 and 390px, and the hero title measured at 13 widths from 1440 to 390px (two lines wherever the line break applies, nothing wider than the screen);
- every text colour measured against its background (all pass AA);
- the FAQs in headless Edge on a phone: clicking opens and closes each one, Enter opens a focused one, and the arrows flip.

Not tested: the Trustpilot widgets, which load but stay empty in the preview (see [preview/README.md](../preview/README.md#known-limits)).
