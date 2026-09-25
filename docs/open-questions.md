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
| **"Speak to our trade team"** (done 25 September 2026) | Goes to Contact us. There's no separate trade team contact on the site. | Decided: it now says "Speak to our team", still to Contact us |
| **The "Why" photo** | A landscaper planting a border, which looks like a stock photo. It's 570px wide for a space about 720px wide on a desktop, so it's a little soft. | Check it's licensed, or use a GravelMaster photo at least 1000px wide |
| **The live "Why us?" pictures** | Six photos with their words built in (Nationwide Delivery, Loose Load Tipper, Trade Discount, Account Manager, Dedicated Bagging, Free Samples). Not used: their words are in the new perks, list and FAQs. | Keep them out, or say where they should go |
| **The phone number on the bulk bag** | The hero photo's bag shows 0800 907 85 90; the site's number is 0330 058 5068. The live page has the same photo. | Check the old number still reaches GravelMaster, or choose a photo without it |
| **The green band's colour** | Darkened from the prototype's bright greens so its white text passes AA (they were 3.0 to 3.7:1). | Keep, or choose other greens that pass |

## Basket page

| Found | Detail | Suggestion |
|---|---|---|
| **Empty Waste Bags has no photos** (live now) | Its product page shows a broken image: none of its photo files (`EMPTYGM-600.jpg` and the others) exist on the image server. The new basket uses the old basket's own 140px bag picture for it, which looks soft in the larger card. | Upload photos for the product in the admin site |
| **Which add-ons to offer** | The new basket offers the old one's four "weekly special offers" (Empty Waste Bag, two weed membranes, plastic pegs), under the prototype's "You might also like". They're fixed in the view, and show customer prices to trade customers too, as before. | Keep these four, choose others, or pick them per basket (e.g. membrane and pegs with gravel) |
| **Stock on each line** (done 25 September 2026) | The prototype shows "In stock" with a tick on every line, and a purple dot for pre-orders. | Decided: a coloured dot on every line: green "In stock", purple "Pre-order", red "Out of stock", read fresh from each size's own stock ([basket-page.md](basket-page.md#stock-on-each-line)) |
| **Sold-out sizes can still be ordered** (live now) | A size can sell out while it's in someone's basket. Adding it is refused once its stock is 0, but nothing at the checkout checks, so the order goes through and the stock goes below 0. The new basket now says "Out of stock" on that line, with the phone number, but still lets the customer check out. | Stop the checkout while a line is sold out (in `CheckoutController`, with the same test), or keep taking the order and contact the customer |
| **"In stock" for sizes whose stock isn't counted** | Only sizes with a `StockLevel` are counted. The others have no stock figure at all, and the site sells them as always available, so the basket says "In stock" for them. How many sizes are counted couldn't be checked from here. | Confirm "In stock" is right for those, or say what they should show |
| **Pre-order sizes added by their code lose their date** (live now) | `BasketController.AddProduct` only reads a size's pre-order date when it's added from its product page. Added by its code (the old basket's add-ons, the "added to your basket" pop-up's add-ons, the new basket's and order confirmation's suggestions), it arrives in the basket as if it weren't a pre-order, so the checkout offers normal delivery dates. The new basket reads the date from the size itself, so it still says "Pre-order", but the checkout doesn't. | Read `PreOrderDate` in the by-code path too (the size's `Product.GetProduct(pcode).PreOrderDate`), or offer no pre-order sizes as add-ons |
| **The Trustpilot carousel** | The old basket ends with a Trustpilot carousel; the prototype has none, so it's left out. | Keep it out, or add the reviews band the other new pages have |
| **The "added to your basket" pop-up** (done 24 September 2026) | It now matches the new basket (see Product page above). | |

## Checkout

| Found | Detail | Suggestion |
|---|---|---|
| **The delivery charge comes from the browser** (live now) | `CheckoutController.CreateOrder` takes the order's delivery charge from the form's `deliveryExtraData`, which the page's script adds up. Someone who edits the page before sending could order a Saturday or morning delivery and pay no charge for it. The new page sends it exactly as the old one did. | Work the charge out on the server from `selectedDelDay` and `selectedTime`, with the same prices `BuildDeliveryDays` uses |
| **Which checkout is live** | The live page's script matches none of the branches, but it uses a variable only `master`'s view sets, so the new page follows `master` ([checkout-page.md](checkout-page.md#which-checkout-is-live)). | Check once the live code is on a branch |
| **Royal Mail wait** | The old page says "10-12 Days" on its delivery step and "3-5 Days" on its contact step. The new page says 10&ndash;12 days. | Confirm which is right |
| **Terms for every order** | The old page only asked for the terms on its delivery step, which "simple" and pre-order-only baskets skip. The new page asks every customer. | Keep it |
| **"Simple" products' delivery day** | For baskets of products marked "simple", the old page skipped the date step but still sent the first free weekday as the delivery day. The new page does the same and shows that day in the summary. | Confirm that day is right for them, or say what these products' delivery is |
| **Log in from the checkout** | "Already have an account? Log in" (from the prototype) goes to the login page, but after logging in the site always goes to My Account (`AccountController.SuccessLogin` ignores the return address), so the customer has to go back to the basket. | Send customers back to where they came from after logging in, or leave the link out |
| **Eco dates** | The old page put an "eco friendly" truck picture on dates whose day of the month equals the "data-numberdays-truck" setting (e.g. every 1st). The new page shows the prototype's "Eco" tag on the same dates. What an eco date means isn't said anywhere. | Say what it means next to the dates, or drop the tag |
| **Postcode outside the basket's area** | The new message: "Your basket was priced for delivery to NG postcodes, and this postcode isn't one. Please check it." The old pop-up only said the address "does not match". Neither says what to do next. | Agree the words, and what a customer should do (e.g. go back and add the products again with the new postcode) |
| **Words from the prototype** | "A more sustainable choice" and "Sustainable materials" are left out: they're environmental claims the live site doesn't make. "Next day delivery: on most products", "Price match promise", "UK nationwide delivery: to home or site" and "Secure payment: card details go to our payment provider, not to us" are in. | Read them, and say if the sustainable wording should go in |
| **Text updates** | The old tick box said "Please untick this box if you wish to not receive SMS updates about your delivery"; the new one says "Send me text updates about my delivery" (ticked, as before) and "You can stop them at any time by replying STOP." | Agree the words |

## Order confirmation

| Found | Detail | Suggestion |
|---|---|---|
| **Which products to suggest** | "You might also like" has the prototype's picks that are on the site: the FeatherSnap Bird Feeder (£149.99), the Large Galvanised Stainless Steel Planter (£62.99), the Trowel (£9.00) and the Gardening Gloves (£9.99). The prototype's wheelbarrow isn't sold on the site. The planter's only size is a pre-order, dated 25 May 2027 (its product page, 24 September 2026). Worse, it's added by its code, which loses the pre-order date (see [Basket page](#basket-page)), so the checkout would treat it as an ordinary delivery, not a pre-order. | Swap the planter for something in stock (or fix the pre-order date first), or choose products that go with what was just bought |
| **The confirmation page marks the order as paid** (live now) | `CheckoutController.OrderResult` calls `SetSuccessfullTransaction` every time `/checkout/orderresult?transId=…` is loaded, after Opayo has already reported the payment. The emails are guarded (`EmailSent`), but the payment status isn't. | Check `SetSuccessfullTransaction` does nothing harmful when it's repeated, or only call it from `OrderNotify` |
| **The customer's name** | The old page said "Thanks *name*, your order has been confirmed!"; the new one says the prototype's "Thank you for your order!" | Keep it, or add the name back |

## Account pages

| Found | Detail | Suggestion |
|---|---|---|
| **Trade applications dropped without a word** (live now) | `AccountController.TradeRegister` quietly drops an application whose phone number has a "+" or doesn't start with 0, or whose payment type wasn't chosen, and still shows "Trade Account requested". A blank phone number gives an error page. The new form stops genuine applicants hitting this, but the server still does it. | Show the applicant what's wrong instead of dropping it, and accept +44 numbers |
| **"Remember me" never worked** (live now) | The sign-in page's "Remember me" tick box has no name, so it's never sent and every sign-in lasts only until the browser closes. The new page leaves it out. | Leave it out, or add it back and send `RememberMe` |
| **Broken privacy link** (live now) | The live registration form links to `gravemaster.co.uk/privacy` (misspelt). The new page links to `/privacy`. | Fixed in the new page |
| **A second try at resetting a password always fails** (live now) | When a reset fails (e.g. the passwords don't meet the rules), `AccountController.ResetPassword` shows the form again without the link's code, so every retry fails with "Invalid token." until the customer uses the email link again. | Return the form with its code (`return View(model)`) |
| **No limit on password guesses** (live now) | Sign-in doesn't lock an account after wrong passwords (`shouldLockout: false`), so a password can be guessed at without limit. | Turn lockout on (and fix the "Locked out" page, whose view expects a different model) |
| **Signing in always ends on My Account** (live now) | After signing in, the site always goes to My Account, even from the checkout or a page that needs signing in (`SuccessLogin` ignores the return address). | Send customers back to where they were |
| **Trade terms now required** | The old trade form's "I agree to the terms and privacy policy" tick box was optional and sent nothing. The new one must be ticked (it still sends nothing). | Keep it, or make it optional again |
| **Return requests go to a developer's inbox** (on `master`) | `MyAccountController.RequestReturn` emails every return request to stephen@stonesoftware.co.uk, using the general message template (its own comment says a Return Request email should be set up). If sending fails, the error is swallowed and the customer is still told it was received. | Send them to the team that handles returns, and tell the customer (or log it) if sending fails |
| **A page of raw payment details** (in the code) | `/myaccount/view` shows a signed-in customer's orders with every stored field, including the payment provider's `SecurityKey`, `VPSTxID` and `TxAuthNo`, and the order's tracking code, with Edit, Details and Delete links to pages that don't exist. Nothing links to it. Not carried over. | Remove the `View` action and `View.cshtml` |
| **A page of made-up quotes** (in the code) | `/myaccount/quotes` shows sample quotes typed into the view, not the customer's. Nothing links to it. Not carried over. | Remove it, or build it properly if quotes are wanted |
| **Price match messages cut short** (in the code) | The old page put the message into the address as it was, so everything from a "&amp;" or "#" was lost ("B&amp;Q" arrived as "B"). The new page encodes it. | Fixed in the new page |
| **Most order photos missing** (in the code) | The old orders page asks for each product's 300px photo, which most products don't have (the plastic pegs and turf, for example). The new page uses the 330px photo every product has. | Fixed in the new page |
| **An old return link gives an error page** (on `master`) | `MyAccountController.RequestReturn` reads the item's order before checking the item exists, so a wrong or old `orderItemId` gives an error page rather than going back to the orders. | Check the item first |
| **Saving the address says nothing** (in the code) | After Save, the site goes to the orders page with no word that the address was saved. | Go back to the address page with "Your address has been saved" |
| **"Billing" or delivery address** | The old page said "Edit Billing Address", but the checkout fills this address in as the delivery address. The new page says "Your address: we fill this address in for you at the checkout." | Keep it |
| **The refund note** | The old return form showed "if you're wanting a refund, please check our Returns Policy" after any reason was chosen. The new one shows it when "Full refund" is chosen. | Keep it |

## Calculator page

| Found | Detail | Suggestion |
|---|---|---|
| **"Your post-code helps us calculate a cost estimate"** (live now) | The page's "How do you calculate" text says the calculator uses a postcode to estimate the cost, but it doesn't ask for one or give a price. The new page keeps the live words. | Take out the postcode sentences, or add a price to the calculator |
| **The old pictures' claims** | The four picture links had "Fast FREE nationwide delivery" and "The UK's No.1 Aggregates Supplier" drawn on them. The new link cards say "Delivery information: Tail-lift delivery to the kerbside, on wooden pallets" and so on, without those claims. | Add them back if they're claims the business stands behind |
| **Every menu opens the gravel calculator** | "Use our calculator" in the Topsoil and Mulches, Play Area and other menus opens the page on Gravel & Chippings. The page could open on the matching type (e.g. `/calculator?type=topsoil`), which needs the header's links changing too. | Leave it, or open the matching type |
| **The new words** | "Popular gravels", "Before you order" and its four cards' lines, and "Can't find your answer? Call us 8am - 5pm on 0330 058 5068". | Read them |

## Delivery page

| Found | Detail | Suggestion |
|---|---|---|
| **The words now live in the view** | The live page's words are HTML typed into the admin site (its `delivery` content), so they can be changed there. The new page has them written in, as the About and Trade pages do, so a change needs a developer. The title and description still come from the admin site. | Keep it, or keep the words in the admin site and only restyle them (less control over the design) |
| **"The aforementioned address"** (live now) | The Returns section says customers may return goods "to the aforementioned address", but no address is given on the page. | Give the returns address, or point to where it is (the Terms and Conditions?) |
| **Which vehicles** (live now) | The page says "an 18 or 26 tonne vehicle" at the top and "7.5, 18 or 26 tonne vehicle" under Delivery vehicle (the same as the product page's [delivery panel question](#product-page)). | Say which is right |
| **The old phone number on the bulk bags** | The hero photo is the live page's own, and its bags show 0800 907 85 90, as on the trade page's photo ([Trade Accounts page](#trade-accounts-page)). | Check the old number still reaches GravelMaster, or choose another photo |
| **Pictures** | The live page's "Delivery Truck Size" photo is back, beside "Delivery vehicle", with those words still drawn on it (they cover part of the lorry, so they can't be cropped off). The lorry with the logo at the bottom is still left out (it looks like a mock-up). | Keep them as they are, or supply a clean photo of the delivery lorry |
| **New words to read** | To break up the delivery terms and returns, the new page adds headings ("The driver has the final say", "Safe access for the lorry", "Solid, level ground", "Cost, pallets and bulk bags", "If you're not at home", "If a delivery can't be made"; "Cancelling an order", "Sending goods back", "If we can't deliver", "Refunds"), renames "Returns" to "Cancellations and returns", and shows four figures taken from the returns paragraphs: "2 hours to cancel by email after you order", "14 working days to send goods back yourself, from the day after delivery", "From £80 per pallet if we collect your goods, or a load is cancelled on route" and "14 days for your refund to be processed after you cancel". The paragraphs themselves are unchanged. | Check they're right, especially the four figures, since customers will read those first |

## Search results page

| Found | Detail | Suggestion |
|---|---|---|
| **The customer price isn't hidden for trade customers** (live now, on every page with prices) | `_Layout`'s `/product/istrade` script hides the customer prices with `style.display = "none !important"`. Browsers ignore that value (checked in Edge), so for a trade customer the customer price stays in its place, invisible, and leaves a gap before the trade price, on the old pages and the new ones. Not seen with a real trade login: the preview is never signed in. | Change it to `style.display = "none"` when `_Layout` is redone on the latest master ([merging.md](merging.md#first-start-from-the-latest-master)) |
| **Search service keys in the code** (in the repository) | `Controllers/BrandController.cs` and `Controllers/CategoryController.cs` each have an Azure Search admin key written into them (`adminApiKey`, for services called gm-search and geeksearch). The search doesn't use them any more. An admin key can change or delete the search index, and anyone who can read the repository can read it. | Regenerate both keys in Azure if the services still exist, and remove the unused code |
| **Searching "turf" doesn't find the turf** (live now) | The old tiles (`DisplayProductsComponentLarge.cshtml`) leave out any product whose name contains "Top Tee" or "Pro Turf", so "turf" only finds ProBlend Turfing Soil. The new page shows exactly what the old one did, so it does the same. It may be deliberate. | Say whether the turf should show in searches |
| **Search only looks at names, and at the whole phrase** | "slate chippings" finds the slate chippings, but "chippings slate", "driveway gravel" or "path" find nothing: the search looks for exactly what was typed inside product names, not descriptions or uses. The new "nothing found" help says so and suggests a single word. | Keep it, or match each word separately and look in descriptions too |
| **At most 100 results** | The search shows one page of 100 with no next page: "e" matches 132 products and shows 100 (99 without the turf). The new page says "Showing the first 99 products" and suggests narrowing the search. Only very short searches reach 100. | Keep it, or add a next page |
| **`/search` with nothing after it gives an error page** (live now) | `CategoryController.Search` calls `ToLower()` on a search that isn't there. Customers don't reach it from the site, but someone typing the address or a web crawler does. | Treat it as an empty search, or send it to the homepage |
| **Should search results be hidden from Google?** | Nothing asks search engines not to list `/search` pages, and the live ones have an empty title. Google advises keeping a site's own search results out of its index. The new page gives them a title and description. | Add `<meta name="robots" content="noindex, follow">` in the page's `Head` section ([merging.md](merging.md#search-results-page)), or leave them as they are |
| **The new words** | The title ("Search results for slate \| GravelMaster"), the description, "No products found", the "nothing found" help (with gravel, slate and bark as example searches) and "Looking for something else?". | Read them |
