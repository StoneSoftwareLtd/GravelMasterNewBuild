using System;
using System.Collections.Generic;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new Ideas & Advice pages show (Views/Ideas/_IdeasList.cshtml and _IdeasArticle.cshtml). The Ideas views
    // fill them from their own models; see docs/merging.md.

    // An article as a card on the landing page or a topic's page.
    public class IdeasCard
    {
        public IdeasCard(string name, string url, string imageUrl, string summary)
        {
            Name = name;
            Url = url;
            ImageUrl = imageUrl;
            Summary = summary;
        }

        public string Name { get; private set; }
        public string Url { get; private set; }

        // Null when the article has no picture.
        public string ImageUrl { get; private set; }

        // Plain text, or null.
        public string Summary { get; private set; }

        // An article's address, as the old pages link to it.
        public static string ArticleAddress(int id, string url)
        {
            return "/ideas-advice/" + id + "/" + url;
        }

        // An article's picture: the admin site stores either a full address (its uploads) or, for the oldest
        // articles, a file name in /img/blog/, which the old views add the folder to.
        public static string ImageAddress(string image)
        {
            if (string.IsNullOrWhiteSpace(image))
            {
                return null;
            }
            image = image.Trim();
            if (image.StartsWith("http://", StringComparison.OrdinalIgnoreCase) || image.StartsWith("https://", StringComparison.OrdinalIgnoreCase) || image.StartsWith("/"))
            {
                return image;
            }
            return "/img/blog/" + image;
        }
    }

    // The landing page (the latest articles) or a topic's page (its articles).
    public class IdeasListModel
    {
        public IdeasListModel()
        {
            Articles = new List<IdeasCard>();
        }

        // The page's heading: "Ideas & Advice", or the topic's name.
        public string Title { get; set; }

        // The topic's description from the admin site (plain text), or null.
        public string Description { get; set; }

        // The landing page: the first article is shown large, and the list is headed "Latest articles".
        public bool IsLanding { get; set; }

        public List<IdeasCard> Articles { get; set; }
    }

    // An article's page.
    public class IdeasArticleModel
    {
        public string Title { get; set; }

        // Null when the article has no picture.
        public string ImageUrl { get; set; }

        // The article's HTML, as typed into the admin site.
        public string Contents { get; set; }

        // The articles use empty paragraphs ("<p>&nbsp;</p>", "<p><br></p>") as spacers, which leave big gaps in the new
        // design's spacing: this takes them out, and nothing else.
        public static string WithoutEmptyParagraphs(string html)
        {
            if (string.IsNullOrEmpty(html))
            {
                return html;
            }
            return System.Text.RegularExpressions.Regex.Replace(html, @"<p(?:\s[^>]*)?>(?:\s|&nbsp;|&#160;|<br\s*/?>)*</p>", "", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        }
    }
}
