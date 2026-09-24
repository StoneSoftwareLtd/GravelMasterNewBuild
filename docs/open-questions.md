# Open questions

Things found along the way that need someone to decide. Nothing here has been changed on the live site.

## Putting it live

| Found | Detail | Suggestion |
|---|---|---|
| **Which code is live?** | No branch in GravelMasterSoftware matches the live site: the layout matches `stripe`, the product page is partly `master`, and neither has everything (details in [merging.md](merging.md#before-anything-which-code-is-live)). | Whoever publishes the site pushes the exact deployed code to a branch; the integration starts from that |
| **Where the test website runs** | Undecided. This PC can't build or run the site (no Visual Studio, MSBuild, IIS or SQL Server). | A staging copy on the server, or Visual Studio Community on this PC |
| **Test database** | Decided 24 September 2026: a copy of the live database, so baskets, trade logins and test orders are safe. | Whoever manages the database makes the copy |
| **`Web.config` is in the repository** | It holds the live database password and is tracked in GravelMasterSoftware. The new pages need `UseNewChrome` in it; without the setting the site shows the old pages, so it only has to be added on the test server. | Keep it out of commits for this work; consider moving the password out of the repository |

## Data and pricing

Decided 23 September 2026: the prices and the quantity calculator stay exactly as the live site has them. The notes below are for the business to check, not code changes.

| Found | Detail | Suggestion |
|---|---|---|
| **Sand calculator looks too light** | The live calculator works out sand as m³ ÷ 0.0015 kg, about 667kg per m³. Sand is usually 1,500 to 1,700kg per m³. For 4m x 3m at 2cm deep it says 160kg; at typical sand weights it would be about 400kg. The new homepage copies the live formula. | Confirm the right figure, then fix both calculators |
| **Gravel bulk bag count** | The calculator labels bulk bags "850kg" but counts them at 800kg each (copied from the live calculator). Possibly a deliberate margin. | Confirm it's intended |
| **Trade prices above retail** | Some products' trade "From" price is higher than the customer price, e.g. Cotswold Chippings 20mm: £91 customer, £92 trade. | Check the trade price list |

## Images

| Found | Detail | Suggestion |
|---|---|---|
| **Homepage banners are heavy** (copies ready) | The admin site's banners are PNGs of about 1MB each: 5.6MB for the six on the homepage. | Optimised JPEGs, same 1400x467, 911KB for all six, are in `D:\Users\user\Documents\GravelMaster\Optimised homepage banners`. Upload them in the admin site to replace the PNGs |
| **Gallery photo 8 is small** | `gm-home-insp-8.jpg` is only 225px wide, so it looks soft on large screens. | Find a bigger original |

## Design

| Found | Detail | Suggestion |
|---|---|---|
| **Low-contrast colours** (done 23 September 2026) | Fifteen text and icon colours were below WCAG AA across the homepage, category page, header, footer and mobile menu. The worst was the mobile menu's yellow category name on white, at 1.9:1. | Fixed: on orange the text is now near-black, keeping the brand colour; elsewhere the colour itself was darkened just enough to pass |
| **White on the header's main green** | White text on the main bar (`#5ca458`) is 3.04:1, below the 4.5:1 AA needs. It was left alone because it is the site's dominant colour and the header is already signed off. | Darken it to about `#4a8346` (4.5:1), or keep the green as it is |
| **"NOW FROM" on offer roundels** | Changed to "FROM", because the prices are normal product prices, not a reduction. | Confirm |
| **Delivering to: postcode** | In the prototype's header; not ported. | Keep out, or plan how it would work |
| **LinkedIn icon** | In the prototype's footer; not ported. | Add if GravelMaster has a LinkedIn page |
| **Contact link** | The old header has one; the new header (like the prototype) doesn't. The footer has the contact details. | Decide if the header needs it |

## Category page

| Found | Detail | Suggestion |
|---|---|---|
| **"Ideal for" icons** | The prototype has four icons (mulch, aquatics, landscaping, pond and water features). The live categories' uses are wider (driveways, pathways, borders, schools, planting, gritting...), so most get a tick instead. | Design icons for the common uses, or keep the ticks |
| **Promo card products** | Gravels & Chippings shows Flamenco Gravel (as the prototype). Slate Chippings, Topsoil and Mulches, and Cobbles (and Scottish) show the homepage offers' picks. Other categories have no promo card. | Choose a product per category, or none |
| **The old left-column images** | The live category pages show six promo images down the left (delivery, a turf article, Instagram, play sand, ITV, the blog). The prototype has the trade card there instead, so they're left out. | Keep them out, or find them a place |
| **Delivery countdown** | The prototype counts down to a cut-off ("Order in the next 2h 50m for delivery on..."). The live site shows a fixed "Order before 12:00PM for next day delivery", so that's what the new page shows. | Decide whether a real countdown is wanted (needs the cut-off time, working days and bank holidays) |
| **Klarna** | In the prototype's payment badges, but not on the live category pages. Left out. | Add only if the site offers Klarna |

## Product page

| Found | Detail | Suggestion |
|---|---|---|
| **"N purchases during last 24 hours"** | The live page pops this up on six products (codes 20COTS, 20DERB, 20POLAR, 20BBAS, 20YORCR and 20MOON). The number is random, between 10 and 29, each time the page loads. It's left out of the new page. | Keep it out, or show a real count from the orders |
| **Star rating and review count** | The prototype shows "4.8 (124 reviews)" and "Write a review" under the product name. The site has product reviews, but the controller has them switched off. Left out. | Switch product reviews back on, show the Trustpilot rating instead, or leave it out |
| **"A popular choice" badge and the three selling points** | Written for Blue Slate ("Stylish blue-grey finish" and so on); there's nothing per product behind them. Left out. | Write them per product (a new field in the admin site), or leave them out |
| **"Product Use" icons** (panels done) | "Product Use", "Colour and Shape" and "Availability" now come from each product's own description. The uses get the category page's four icons where a word matches (pond, water, aquatic, mulch, landscap, garden), and a tick otherwise, so most uses (Driveways, Rockeries, Borders...) get a tick. | Design icons for the common uses, or keep the ticks (the same question as the category page's "Ideal for") |
| **"Add to your order" add-ons** | The prototype suggests pegs, glue and membrane. The live page offers no add-ons, although the controller works out a list of linked products. Left out. | Decide which products to offer with which, then it can be built on the existing list |
| **Dashes vanish from descriptions** (live now) | `StringProcessing.RemoveNonASCII` deletes every non-ASCII character from product and category descriptions and product synopses before they're shown. So "30&ndash;50cm" shows as "3050cm" (the Begonia's Mature Height and Spread, on the live site today), and curly quotes or &pound; signs typed as characters go the same way. | Swap the dashes and quotes for plain ones instead of removing them, or check why non-ASCII is removed at all |
| **Wrong phone number in 7 slate descriptions** (live now) | Blue, Green and Grey Slate 20mm and 40mm, and Plum Slate 40mm: the "Loose Load Deliveries" text shows 0330 058 5068, but the link dials `tel:03300880138`, so tapping it on a phone calls a different number. Found by checking every product page. | Fix the link in those seven descriptions in the admin site |
| **Delivery panel wording** | The panel is the prototype's text. It matches the live delivery page on the vehicles, 3m access, flat ground and kerbside. Two lines couldn't be checked: next day delivery "often available on orders placed before 12pm (additional charges may apply)", and "available across most mainland UK postcodes". The live delivery page itself says "18 or 26 tonne vehicle" in one place and "7.5, 18 or 26 tonne" in another. | Confirm the two lines, and which vehicles are right |
| **The basket pop-up's inside** (done 24 September 2026) | After Add to cart, the new pop-up showed the basket's own summary in the old site's styling. | Done without changing `AddToCartComponent.cshtml`: the new product page reads the summary and shows it in the new basket's style ([product-page.md](product-page.md#choices)). Its three add-ons are fixed in that file (FeatherSnap and two membranes; glue and a membrane for gravel): say if they should change |
| **Blue Slate 20mm's extra photos** | They're the files named after Grey Slate (`20GYSL`, `20GYSL1` to `20GYSL4`). They look much the same, so this may be deliberate. | Check they're the right photos |

## About us page

| Found | Detail | Suggestion |
|---|---|---|
| **How long in business?** (live now) | The live page says "31-years of experience in the aggregate industry" and "founded in 1988"; 1988 plus 31 is 2019, so the 31 is out of date (it'd be 38 now). The prototype adds "Over 15 years experience", "15+ years" and "Since 2008", which may be Gravel Master itself rather than the group. The new page shows all of these as written. | Confirm the figures and wording; "31-years" could become "over 35 years" so it doesn't date again |
| **The hero photo** | The prototype's photo (a woman in a hard hat checking concrete blocks) looks like a stock photo rather than GravelMaster's yard, and it's only 505px wide for a space about 830px wide on a desktop, so it's a little soft. | Check it's licensed, or use one of the live page's own photos (despatch, office, forklift, staff) or a new one at least 1000px wide |
| **Harvey Finlayson** | In the prototype's six ("Customer Experience"), but not on the live Meet the team page, which lists 17 people. The other five are, with the same jobs. | Confirm Harvey should be shown, and add him to the Meet the team page if so |
| **Live content left out** | The live page's product photo carousel, the four photos of the site and staff, its four written-in customer reviews, the "Professional service with an unbeatable price" section (Experienced since 1988, Our Promise, Commitment, Queries and Advice) and the delivery photo at the bottom. The prototype has no place for them; its own "What Makes Us Different?" text (placeholder in the prototype) now holds the live page's other paragraphs. | Keep them out, or say which should come back and where |
| **"What Makes Us Different?" list** | The five points ("Carefully selected products", "Wide range of colours and sizes"...) are the prototype's. | Check they're what the business wants to say |
| **The blue band's colour** | Darkened from the prototype's `#08a5de` to `#007db5` so its white text passes AA (it was 2.8:1). It's a deeper blue than the design. | Keep, or choose another colour that passes |

## Trade Accounts page

| Found | Detail | Suggestion |
|---|---|---|
| **No page title** (live now) | The live `/trade` page has an empty `<title>` and an empty meta description, so search results and browser tabs show no name for it. They come from the page's content settings, not the view. | Set a title and description for the `trade` page in the admin site |
| **The words written for the new page** | The prototype's perks, "Why Choose" text and FAQ answers were placeholders. They're now written from what the live page, the trade sign-up form and the site's code say (listed in [trade-page.md](trade-page.md#where-the-words-come-from)), but nobody from the business has read them. In particular: "Priority Support" is described as an account manager plus the sales line, and the answer to "How long does it take?" gives no time, because the site doesn't say. | Read the perks and FAQ answers, and add a typical approval time if there is one |
| **"Speak to our trade team"** | Goes to Contact us. There's no separate trade team contact on the site. | Keep, or give it a trade phone number or email |
| **The "Why" photo** | A landscaper planting a border, which looks like a stock photo. It's 570px wide for a space about 720px wide on a desktop, so it's a little soft. | Check it's licensed, or use a GravelMaster photo at least 1000px wide |
| **The live "Why us?" pictures** | Six photos with their words built in (Nationwide Delivery, Loose Load Tipper, Trade Discount, Account Manager, Dedicated Bagging, Free Samples). Not used: their words are in the new perks, list and FAQs. | Keep them out, or say where they should go |
| **The phone number on the bulk bag** | The hero photo's bag shows 0800 907 85 90; the site's number is 0330 058 5068. The live page has the same photo. | Check the old number still reaches GravelMaster, or choose a photo without it |
| **The green band's colour** | Darkened from the prototype's bright greens so its white text passes AA (they were 3.0 to 3.7:1). | Keep, or choose other greens that pass |

## Basket page

| Found | Detail | Suggestion |
|---|---|---|
| **Empty Waste Bags has no photos** (live now) | Its product page shows a broken image: none of its photo files (`EMPTYGM-600.jpg` and the others) exist on the image server. The new basket uses the old basket's own 140px bag picture for it, which looks soft in the larger card. | Upload photos for the product in the admin site |
| **Which add-ons to offer** | The new basket offers the old one's four "weekly special offers" (Empty Waste Bag, two weed membranes, plastic pegs), under the prototype's "You might also like". They're fixed in the view, and show customer prices to trade customers too, as before. | Keep these four, choose others, or pick them per basket (e.g. membrane and pegs with gravel) |
| **"In stock" on each line** | The prototype shows "In stock" with a tick on every line. The basket doesn't know stock, and the old page never said it, so it's left out; pre-order lines still say so. | Keep it out, or add a stock check to the basket |
| **The Trustpilot carousel** | The old basket ends with a Trustpilot carousel; the prototype has none, so it's left out. | Keep it out, or add the reviews band the other new pages have |
| **The "added to your basket" pop-up** (done 24 September 2026) | It now matches the new basket (see Product page above). | |
