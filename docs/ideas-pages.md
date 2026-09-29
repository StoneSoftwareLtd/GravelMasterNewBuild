# Ideas & Advice pages

The site's articles, in the new design: the landing page (`/ideas-advice`), the topic pages (`/ideas-advice/how-to-guides` and the others) and the articles (`/ideas-advice/147/how-to-lay-a-gravel-driveway` and so on, 33 of them in the topics). There's no Optima prototype for them, so they're in the information pages' style. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#ideas--advice-pages).

## Files

| File | What it is |
|---|---|
| `Views/Ideas/_IdeasTopics.cshtml` | the Ideas & Advice bar: "Ideas & Advice" and the topics, the page's own marked |
| `Views/Ideas/_IdeasList.cshtml` | the landing page and the topic pages: the articles as cards (on the landing page, the newest large) |
| `Views/Ideas/_IdeasArticle.cshtml` | an article: its title, picture and words, and "Planning a project?" with the phone number and the calculator |
| `ViewModels/Common/IdeasPageModels.cs` | `IdeasCard`, `IdeasListModel` and `IdeasArticleModel`, with the pictures' addresses worked out as the old views do, and the empty paragraphs taken out of an article |
| `css/gm-info.css` | the styles, shared with the other information pages (`.gm-ideas`); the articles share the privacy page's readable column |

No script.

## How the pages are made

`IdeasController` has three actions, each with a view that uses `Views/Shared/_ContentHubLayout.cshtml`, a layout inside `_Layout`:

- `_ContentHubLayout` adds the old banner (a picture with "Ideas & Advice") and a tab for each topic but "Archive", from `IdeasRepository.GetNewsCategories()`. It also loads `css/content-hub.css` and a stylesheet from Wayfair's servers.
- `LatestNews.cshtml` (the landing page) is given the 20 newest articles, but shows three chosen ones typed into the view, and pictures linking to Instagram and Pinterest.
- `DisplayCategory.cshtml` shows a topic's description and its articles as cards (picture, name, summary).
- `DisplayArticle.cshtml` shows the article's picture and its HTML from the admin site.

With the new design on, `_ContentHubLayout` shows the new bar in place of the banner and tabs, with the same topics, and wraps the page in the information pages' `.gm-info` wrapper, without the old stylesheets; each view shows its new partial. As with the other pages, the live views are newer than master's (the live article page has a heading; its pictures are full addresses), so the new code works with both: a picture that's a file name goes in `/img/blog/`, as master's views put it.

## What the old pages show, and where each part went

| Old page | New page |
|---|---|
| A banner picture with "Ideas & Advice", and a tab per topic | The Ideas & Advice bar at the top of every page: "Ideas & Advice" (the landing page) and the topics as buttons, the page's own filled in green. On phones the topics are one row that scrolls sideways |
| The landing page: Instagram and Pinterest pictures, and three chosen articles | The newest article large, then the next 19 as cards, and "Find more ideas on our Instagram and Pinterest" ([open question](open-questions.md#ideas--advice)) |
| A topic page: its description (all empty now) and its articles as cards | The topic's name as the heading, its description if it has one, and its articles as cards, three to a row. With none, "There are no articles here yet" |
| An article: its picture and words in a box with a shadow | The article's title, its picture, and its words in the privacy page's readable column (16px); then "Planning a project?" with "Call 0330 058 5068" and "Gravel calculator" |

The articles' words are the admin site's HTML as it is, except for empty paragraphs (`<p>&nbsp;</p>`, `<p><br></p>`), which the articles use as spacers and which left big gaps: `IdeasArticleModel.WithoutEmptyParagraphs` takes those out, and nothing else.

The landing page's title is "Ideas & Advice | GravelMaster" (was "Gravelmaster Articles"), and a topic with no page title of its own gets its name ("Product Information | GravelMaster" in place of "| GravelMaster").

## The old Articles section

`/articles` is an older list of the same articles (`NewsController.LatestNews`): 4 categories and the 20 newest articles' names, which aren't links. Each category (`/articles/7/winter-product-news` and so on) lists its articles the same way (`DisplayCategory`). The articles themselves (`/article/{id}/{name}`) already redirect to Ideas & Advice.

With the new design on, `/articles` and its category pages go to `/ideas-advice` too ([merging.md](merging.md#old-articles-section)), rather than getting a design of their own. The new header's "Blog" (which went to `/blog`, a permanent redirect to Ideas & Advice) and the new footer's "Articles" and "Blog" now go straight there; the footer has one "Ideas & Advice" link instead of the two. Tested in the preview on 28 September 2026: `/articles` and `/articles/7/winter-product-news` both landed on Ideas & Advice; the redirect code compiles.

## Tested

In the whole-website preview on 28 September 2026: the landing page, "How to Guides", "Collaborations" (no articles), "Product Information" and "How To Lay A Gravel Driveway".

- The three partials compile with MVC 5.2's Razor, and so do `_ContentHubLayout.cshtml`, `LatestNews.cshtml`, `DisplayCategory.cshtml` and `DisplayArticle.cshtml` with their new code ([merging.md](merging.md#ideas--advice-pages)), against stand-ins copied from the repository's classes (the articles, topics and their view models, and `IdeasRepository` with sample topics). Run with sample data through the real `_ContentHubLayout` and a stand-in for `_Layout`, with the new design on: each view built its model (addresses, pictures as full addresses and as file names, no picture, no summary) and showed its partial inside the `.gm-info` wrapper, under the bar with every topic but "Archive"; `gm-info.css` was in the head; there was no old banner and no Wayfair stylesheet; the titles were as above; and only the empty paragraphs were taken out of the article. With the design off, the new code was skipped (the harness can't go further: the old markup's `~/` addresses need the real web server).
- The five pages the preview shows are character for character the ones the compiled partials make with the same data (the preview reads it from the live pages; its links to gravelmaster.co.uk point at itself). This found that the preview missed Product Information's article on the landing page, as the topic's tab is a redirect (`Product-Information` to `product-information`): fixed.
- In headless Edge: screenshots at 1440 and 390px; nothing wider than the screen at 1440, 1100, 860, 560, 390 and 320px; three, two and one cards a row as the page narrows; the bar's topics scroll sideways on phones; the topic's own button marked; the pictures load; the article's words 16px; no script errors.
- Every text colour passes AA, the lowest 5.4:1 ("Guides and inspiration").

The preview's landing page stands in for the 20 newest articles with the topic pages' articles, newest first by their number: the live landing page doesn't show them, and no page shows the dates. On the real site the controller chooses them.

Not tested: the pages on the test website, and the real landing page's articles.
