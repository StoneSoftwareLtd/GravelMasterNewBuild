using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // Everything the new category page (Views/Shared/_CategoryPage.cshtml) shows. The category view fills it
    // from its own model; see docs/merging.md.
    public class CategoryPageModel
    {
        // The sort choices the category page accepts, posted back to the same address as "sort".
        public static readonly string[] SortOptions = { "Relevance", "Name", "Price (Low to High)", "Price (High to Low)" };

        public CategoryPageModel()
        {
            Breadcrumbs = new List<CategoryLink>();
            Description = CategoryDescription.Parse(null);
            FilterGroups = new List<CategoryFilterGroup>();
            SelectedSort = SortOptions[0];
            Products = new List<CategoryProduct>();
            EnquiryCategories = new List<string>();
        }

        // The page heading, e.g. "Gravels & Chippings", or "Black Gravels & Chippings" on a filtered page.
        public string Title { get; set; }

        // The category's URL name, e.g. "garden-chippings" or "slate-chippings"; it picks the promo product.
        public string CategoryUrl { get; set; }

        // The trail after "Home": a subcategory's parent, then this page. The current page's Url is null.
        public List<CategoryLink> Breadcrumbs { get; set; }

        public CategoryDescription Description { get; set; }

        // e.g. "Order before 12:00PM for next day delivery"
        public string DeliveryMessage { get; set; }

        public List<CategoryFilterGroup> FilterGroups { get; set; }

        // The unfiltered category page, or null when no filter is chosen.
        public string ClearFiltersUrl { get; set; }

        public bool IsFiltered
        {
            get { return ClearFiltersUrl != null; }
        }

        // One of SortOptions.
        public string SelectedSort { get; set; }

        public List<CategoryProduct> Products { get; set; }

        // Top-level category names in menu order, for the bulk enquiry pop-up.
        public List<string> EnquiryCategories { get; set; }
    }

    public class CategoryLink
    {
        public CategoryLink(string name, string url)
        {
            Name = name;
            Url = url;
        }

        public string Name { get; private set; }

        // null for the current page
        public string Url { get; private set; }
    }

    // A filter group such as Colour, Price Range or Size.
    public class CategoryFilterGroup
    {
        public CategoryFilterGroup(string name)
        {
            Name = name;
            Options = new List<CategoryFilterOption>();
        }

        public string Name { get; private set; }

        public List<CategoryFilterOption> Options { get; private set; }

        public bool HasSelection
        {
            get { return Options.Any(o => o.Selected); }
        }
    }

    public class CategoryFilterOption
    {
        public CategoryFilterOption(string name, string url, bool selected)
        {
            Name = name;
            Url = url;
            Selected = selected;
        }

        public string Name { get; private set; }

        // The page with this filter added, or, when Selected, with it taken off.
        public string Url { get; private set; }

        public bool Selected { get; private set; }
    }

    // A product card on the category page: HomeProduct's name, link, photo and "From" prices, plus the short
    // description (the product's synopsis).
    public class CategoryProduct : HomeProduct
    {
        public CategoryProduct(string name, string url, string imageUrlFormat, decimal price, decimal tradePrice, string synopsis)
            : base(name, url, imageUrlFormat, price, tradePrice)
        {
            Synopsis = synopsis ?? "";
        }

        public string Synopsis { get; private set; }
    }

    // A category description from the database, split up for the new page's intro band. The old page shows it
    // as an "Ideal for: ..." heading, an intro, and a longer part in <div id="cat_desc_readmore"> behind a
    // Read More button.
    public class CategoryDescription
    {
        private static readonly Regex IdealForHeading = new Regex(@"<h2[^>]*>\s*Ideal for:?(.*?)</h2>", RegexOptions.IgnoreCase | RegexOptions.Singleline);
        private static readonly Regex DivTag = new Regex(@"<div\b[^>]*>|</div\s*>", RegexOptions.IgnoreCase);

        private CategoryDescription()
        {
            IdealFor = new List<string>();
            IntroHtml = "";
        }

        // e.g. "Driveways", "Pathways", "Borders", "General Garden Use"
        public List<string> IdealFor { get; private set; }

        // The description before the longer part (HTML from the database), or "".
        public string IntroHtml { get; private set; }

        // The longer part shown by "Read more" (HTML from the database), or null.
        public string MoreHtml { get; private set; }

        public static CategoryDescription Parse(string html)
        {
            var result = new CategoryDescription();
            if (string.IsNullOrWhiteSpace(html))
            {
                return result;
            }

            html = html.Trim();

            // A description saved with the old page's <div id="cat_desc"> wrapper
            Match wrapper = Regex.Match(html, @"^<div\b[^>]*\bid=""cat_desc""[^>]*>", RegexOptions.IgnoreCase);
            if (wrapper.Success)
            {
                int end = FindClosingDiv(html, wrapper.Index + wrapper.Length);
                if (end >= 0 && html.Substring(end).Trim().Equals("</div>", StringComparison.OrdinalIgnoreCase))
                {
                    html = html.Substring(wrapper.Length, end - wrapper.Length).Trim();
                }
            }

            Match heading = IdealForHeading.Match(html);
            if (heading.Success)
            {
                string text = Regex.Replace(heading.Groups[1].Value, "<[^>]+>", " ");
                text = WebUtility.HtmlDecode(Regex.Replace(text, @"\s+", " ")).Trim();
                result.IdealFor = SplitIdealFor(text);
                html = html.Remove(heading.Index, heading.Length);
            }

            Match more = Regex.Match(html, @"<div\b[^>]*\bid=""cat_desc_readmore""[^>]*>", RegexOptions.IgnoreCase);
            if (more.Success)
            {
                int start = more.Index + more.Length;
                int end = FindClosingDiv(html, start);
                if (end >= 0)
                {
                    string moreHtml = html.Substring(start, end - start).Trim();
                    result.MoreHtml = moreHtml.Length > 0 ? moreHtml : null;
                    int afterClose = html.IndexOf('>', end) + 1;
                    html = html.Substring(0, more.Index) + html.Substring(afterClose);
                }
            }

            result.IntroHtml = html.Trim();
            return result;
        }

        // "Schools, Nurseries and Home Play Areas" -> "Schools", "Nurseries", "Home Play Areas". A list with no
        // commas stays whole ("Construction and Landscaping Projects"), because its "and" may be part of one use.
        public static List<string> SplitIdealFor(string text)
        {
            var items = (text ?? "").Split(',')
                .Select(s => s.Trim().TrimEnd('.').Trim())
                .Where(s => s.Length > 0)
                .ToList();
            if (items.Count > 1)
            {
                string last = Regex.Replace(items[items.Count - 1], @"^and\s+", "", RegexOptions.IgnoreCase);
                items.RemoveAt(items.Count - 1);
                int and = last.LastIndexOf(" and ", StringComparison.OrdinalIgnoreCase);
                if (and > 0)
                {
                    items.Add(last.Substring(0, and).Trim());
                    items.Add(last.Substring(and + 5).Trim());
                }
                else
                {
                    items.Add(last);
                }
            }
            return items.Where(s => s.Length > 0).ToList();
        }

        // The index of the </div> that closes a div whose content starts at contentStart, or -1.
        private static int FindClosingDiv(string html, int contentStart)
        {
            int depth = 1;
            for (Match tag = DivTag.Match(html, contentStart); tag.Success; tag = tag.NextMatch())
            {
                depth += tag.Value.StartsWith("</") ? -1 : 1;
                if (depth == 0)
                {
                    return tag.Index;
                }
            }
            return -1;
        }
    }
}
