# GravelMaster new build

Moving the live GravelMaster website ([www.gravelmaster.co.uk](https://www.gravelmaster.co.uk), ASP.NET MVC 5 with Razor and Bootstrap 4) over to the new Optima design, one piece at a time.

Each piece is built to drop into the **GravelMasterSoftware** repository behind the `UseNewChrome` setting, so it can be switched on and off. It can be previewed on real pages from the live site before it goes anywhere near production.

## Where things are up to

| Piece | State | Notes |
|---|---|---|
| Header, footer and mobile menu | Done and tested | Needs redoing on the latest GravelMasterSoftware master before merging |
| Homepage | Built and tested in the preview | Needs wiring into the site |
| Category page | Built and tested in the preview | Needs wiring into the site |
| Product page | Built and tested in the preview | Needs wiring into the site |
| About us page | Built and tested in the preview | Needs wiring into the site |
| Trade Accounts page | Built and tested in the preview | Needs wiring into the site |
| Basket page | Built and tested in the preview with a sample basket | Needs wiring into the site, and testing with real baskets |
| Checkout | Built and tested in the preview with a sample basket | Needs wiring into the site, and testing with real orders and test payments |
| Order confirmation | Built and tested in the preview with a sample order | Needs wiring into the site, and testing after real test payments |
| Account pages: signing in | Built and tested in the preview (no prototype: in the new pages' style) | Needs wiring into the site |
| Account pages: My Account (orders, returns, price match, address) | Built and tested in the preview with a sample customer | Needs wiring into the site, and testing with real accounts |

Every step so far, with dates: **[docs/progress-log.md](docs/progress-log.md)**.

## What's in this repository

| Path | What it is |
|---|---|
| `Website/Website/` | The site files added or changed, at the same paths as in GravelMasterSoftware, so they can be copied straight across |
| `preview/` | Tools for previewing the work on real pages from the live site ([preview/README.md](preview/README.md)) |
| `Start website preview.cmd` | Double-click to open the preview |
| `docs/` | Notes for each piece, the merge checklist and open questions |
| `patches/` | The new-chrome branch's original patch, from before the 17 September fixes |

## See it

Double-click **`Start website preview.cmd`**. Your browser opens http://localhost:8780: the live website with the new header, footer, homepage, category pages, product pages, About us and Trade Accounts pages swapped in, the new basket and checkout with a sample basket in them, the new order confirmation for a sample order, the new sign-in and password pages, and My Account for a sample customer. Keep the black window open while you use it. It's read-only, so nothing is sent to the real site (the only exceptions are Sort by on category pages, which just reorders the products, and the product pages' price lookup, which only reads prices).

Or open this folder in VS Code and use Live Server on `preview/index.html` or `preview/category.html`. See [preview/README.md](preview/README.md) for both.

## Documents

| Document | For |
|---|---|
| [docs/progress-log.md](docs/progress-log.md) | What was done, step by step |
| [docs/header-and-footer.md](docs/header-and-footer.md) | The new header, footer and mobile menu: files, how the switch works, the fixes |
| [docs/homepage.md](docs/homepage.md) | The new homepage: sections, what it keeps from the old one |
| [docs/category-page.md](docs/category-page.md) | The new category page: what it keeps from the old one, choices, what was tested |
| [docs/product-page.md](docs/product-page.md) | The new product page: how it buys exactly as the old one did, choices, what was tested |
| [docs/about-page.md](docs/about-page.md) | The new About us page: where the live page's content went, changes from the prototype, what was tested |
| [docs/trade-page.md](docs/trade-page.md) | The new Trade Accounts page: where its words come from, changes from the prototype, what was tested |
| [docs/basket-page.md](docs/basket-page.md) | The new basket page: how it changes the basket exactly as the old one did, choices, what was tested |
| [docs/checkout-page.md](docs/checkout-page.md) | The new checkout: which checkout is live, how it sends exactly what the old one did, the delivery-date rules, what was tested |
| [docs/confirmation-page.md](docs/confirmation-page.md) | The new order confirmation: why the page isn't a plain page view, where the old page's details went, what was tested |
| [docs/account-pages.md](docs/account-pages.md) | The new account pages: sign in, registering, trade applications, passwords, My Account, and what the old pages did |
| [docs/merging.md](docs/merging.md) | Everything to do in GravelMasterSoftware to put this live |
| [docs/open-questions.md](docs/open-questions.md) | Things found along the way that need a decision |

## Not in this repository

`Web.config`, because the site's copy holds the live database password (`.gitignore` blocks it). The only change it needs is one setting inside `<appSettings>`:

```xml
<add key="UseNewChrome" value="false" />
```

`false` keeps the old header and footer; `true` shows the new ones. While testing, adding `?newchrome=1` or `?newchrome=0` to any page address overrides the setting for that browser.

## Working in this repository

- One change per commit, with the reason in the message.
- Add each step to [docs/progress-log.md](docs/progress-log.md).
- Keep files under `Website/Website` at their GravelMasterSoftware paths.
