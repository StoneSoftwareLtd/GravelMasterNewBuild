# Page not found

What the site shows for an address that doesn't exist, in the new design. There's no Optima prototype for it, so it's in the information pages' style. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#page-not-found).

## The two old pages

- **`Error404.html`**: IIS answers any address that doesn't exist with this static file (`Web.config`'s `httpErrors`). It's a saved copy of an old page, with its own old header and footer, which is why it could never follow the new design: "Sorry, that page doesn't exist! The page you were looking for could not be found. Or you can return to our home page, or contact us if you can't find what you are looking for."
- **`Views/Shared/NotFound.cshtml`**: `ProductController` and `CategoryController` show it for a product or category that doesn't exist. A black page with no header or footer: "404", "There's nothing here.", "It may have moved shelf.", "Trying to place an order and something went wrong? call us: 0330 058 5068", "Back to the site". (IIS probably replaces it with `Error404.html` anyway, as it's set to replace every 404.)

## The new page

`Views/Shared/_NotFoundPage.cshtml`, shown by `NotFound.cshtml` when the new design is on, inside `_Layout`, so with the new header and footer, and still answering 404. To have IIS's 404s show it too, `Web.config` sends them to `ErrorController.NotFound`, which shows `NotFound.cshtml` ([merging.md](merging.md#page-not-found)).

It has:
- "Page not found", "Sorry, that page doesn't exist", "The page you were looking for could not be found. It may have moved shelf." (both old pages' words);
- a search box (the site's own search);
- "Or browse our products": the header's categories, in the header's order;
- "Trying to place an order and something went wrong? Call us on 0330 058 5068, Monday to Friday, 8am - 5pm, or contact us.";
- "Back to our home page".

The controllers pass `NotFound.cshtml` no model, and `_Layout` needs one, so the new branch gives it a `NotFoundViewModel` (the site's own, empty class), whose menu gives the categories.

## Tested

On 28 September 2026.

- The partial compiles with MVC 5.2's Razor, and so does `NotFound.cshtml` with its new branch. Run through a stand-in for `_Layout` that needs a `BaseViewModel`, as the real one does:
  - with no model, as the controllers call it: the layout got a `NotFoundViewModel`, status 404, title "Page not found | GravelMaster";
  - with a model with three categories: the links in the header's order;
  - with the design off: the old page.
- The preview's page is the same markup as the compiled partial (with and without categories).
- In the preview, an address that doesn't exist gets the new page, answering 404, with the header's 8 categories.
- Nothing wider than the screen at 8 widths from 1440 to 320px; screenshots at 1440 and 390px; no script errors.

Not tested: the `Web.config` change and the route to `ErrorController`, which need the test website.
