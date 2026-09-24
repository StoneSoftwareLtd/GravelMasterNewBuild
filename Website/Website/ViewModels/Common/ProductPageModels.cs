using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // Everything the new product page (Views/Shared/_ProductPage.cshtml) shows. Views/Product/Detail.cshtml fills
    // it from its ProductViewModel; see docs/merging.md.
    public class ProductPageModel
    {
        // The postcode areas in the old page's Step 1 drop-down: the areas the site prices delivery for.
        public static readonly string[] PostcodeAreas =
        {
            "AB", "AL", "B", "BA", "BB", "BD", "BH", "BL", "BN", "BR", "BS", "CA", "CB", "CF", "CH", "CM", "CO", "CR",
            "CT", "CV", "CW", "DA", "DD", "DE", "DG", "DH", "DL", "DN", "DT", "DY", "E", "EC", "EH", "EN", "EX", "FK",
            "FY", "G", "GL", "GU", "HA", "HD", "HG", "HP", "HR", "HU", "HX", "IG", "IP", "IV", "KA", "KT", "KW", "KY",
            "L", "LA", "LD", "LE", "LL", "LN", "LS", "LU", "M", "ME", "MK", "ML", "N", "NE", "NG", "NN", "NP", "NR",
            "NW", "OL", "OX", "PA", "PE", "PH", "PL", "PO", "PR", "RG", "RH", "RM", "S", "SA", "SE", "SG", "SK", "SL",
            "SM", "SN", "SO", "SP", "SR", "SS", "ST", "SW", "SY", "TA", "TD", "TF", "TN", "TQ", "TR", "TS", "TW", "UB",
            "W", "WA", "WC", "WD", "WF", "WN", "WR", "WS", "WV", "YO"
        };

        // A full postcode ("NG5 6AB"), an outward code ("NG5") or an area ("NG"), in any case and spacing
        private static readonly Regex PostcodeStart = new Regex(@"^([A-Z]{1,2})(?:[0-9][0-9A-Z]?(?:\s*[0-9][A-Z]{2})?)?$", RegexOptions.IgnoreCase);

        public ProductPageModel()
        {
            Breadcrumbs = new List<CategoryLink>();
            Photos = new List<ProductPhoto>();
            Options = new List<ProductOption>();
            MinQuantity = 1;
            Description = ProductDescription.Parse(null);
            Related = new List<HomeProduct>();
            EnquiryCategories = new List<string>();
        }

        public string Name { get; set; }

        // e.g. "20BLSL"
        public string Code { get; set; }

        // The product's category name, e.g. "Slate Chippings": item_category in the Google Analytics events.
        public string CategoryName { get; set; }

        // What /product/calculateprices takes as productId.
        public int ProductId { get; set; }

        // Where Add to cart posts, as the old page's form: /basket/addtobasket?id=<code>
        public string AddToBasketUrl { get; set; }

        // The trail after "Home": the parent category (if there is one), the category, then this product
        // (its Url is null).
        public List<CategoryLink> Breadcrumbs { get; set; }

        // The first is the main photo.
        public List<ProductPhoto> Photos { get; set; }

        // An embeddable video player's address (the old page's Wistia video), or null.
        public string VideoUrl { get; set; }

        // The 360-degree viewer's address (Spinzam), or null.
        public string ThreeSixtyUrl { get; set; }

        // The "From" customer and trade prices, including VAT, as the old page's heading shows them.
        public decimal Price { get; set; }

        public decimal TradePrice { get; set; }

        // Priced without a postcode, so there's no Step 1 (the old page's IsSimple: glue, bulbs and so on).
        public bool IsSimple { get; set; }

        // 1, or 10 for turf.
        public int MinQuantity { get; set; }

        // False shows "Out of stock" in place of Add to cart (the old page's IsVisible).
        public bool IsInStock { get; set; }

        // The sizes to choose from, in order, without the sample.
        public List<ProductOption> Options { get; set; }

        // The size chosen when the page opens (the old page's GetDefaultVariantItemId).
        public int SelectedOptionId { get; set; }

        // The sample (the old page's SampleWithHalf, or its "Sample" size), or null.
        public ProductOption SampleOption { get; set; }

        // "Next available delivery day", shown when set (the old page shows it on products with a calculator).
        public DateTime? NextDeliveryDate { get; set; }

        public ProductDescription Description { get; set; }

        // The quantity calculator's type ("gravel", "mulch", "topsoil" or "sand"), or null for no calculator, as on
        // the old page: QuantityCalculatorModel.ForProduct(ProductViewModel.Calc).
        public string CalculatorType { get; set; }

        // "You might also like"
        public List<HomeProduct> Related { get; set; }

        // Top-level category names in menu order, for the bulk enquiry pop-up.
        public List<string> EnquiryCategories { get; set; }

        // The size chosen when the page opens: SelectedOptionId, or the first size if that isn't one of Options.
        public ProductOption SelectedOption
        {
            get { return Options.FirstOrDefault(o => o.Id == SelectedOptionId) ?? Options.FirstOrDefault(); }
        }

        // "NG5 6AB", "ng5" or "NG" -> "NG"; null when it isn't a postcode, or not in an area the site delivers to.
        public static string GetPostcodeArea(string postcode)
        {
            Match m = PostcodeStart.Match((postcode ?? "").Trim());
            if (!m.Success)
            {
                return null;
            }
            string area = m.Groups[1].Value.ToUpperInvariant();
            return PostcodeAreas.Contains(area) ? area : null;
        }
    }

    public class ProductPhoto
    {
        public ProductPhoto(string url, string zoomUrl, string thumbUrl)
        {
            Url = url;
            ZoomUrl = zoomUrl ?? url;
            ThumbUrl = thumbUrl ?? url;
        }

        // 600px, as the old page's main photo
        public string Url { get; private set; }

        // 1000px, for "Click to zoom"
        public string ZoomUrl { get; private set; }

        // 300px, for the thumbnails
        public string ThumbUrl { get; private set; }
    }

    // A size to choose, e.g. "Approx 850Kg Bulk Bag" (a variant item on the old page).
    public class ProductOption
    {
        public ProductOption(int id, string name, string code, decimal price, DateTime? preOrderDate)
        {
            Id = id;
            Name = name ?? "";
            Code = code ?? "";
            Price = price;
            PreOrderDate = preOrderDate;
        }

        // The variant item id: what the basket takes as selectedVariantItem, and calculateprices as variantitem.
        public int Id { get; private set; }

        public string Name { get; private set; }

        // The size's own product code and base price (the old page's GetVariantCode and GetVariantPrice), for
        // the Google Analytics view_item and add_to_cart events.
        public string Code { get; private set; }

        public decimal Price { get; private set; }

        // Set for a size that can only be pre-ordered.
        public DateTime? PreOrderDate { get; private set; }
    }

    // A product description from the database, split up for the new page. Most follow the same pattern: intro
    // paragraphs, then an <h3> (usually the product name) over lines such as "<b>Colour:</b> Blue<br>", then
    // more <h3> sections such as "Colour and Shape" and "Availability".
    public class ProductDescription
    {
        private static readonly Regex Heading = new Regex(@"<h3\b[^>]*>(.*?)</h3\s*>", RegexOptions.IgnoreCase | RegexOptions.Singleline);
        private static readonly Regex SpecLine = new Regex(@"<(b|strong)\b[^>]*>(?<label>[^<]*)</\1\s*>(?<value>.*?)(?=<br\b[^>]*>|</?p\b[^>]*>|</?div\b[^>]*>|<(?:b|strong)\b|$)", RegexOptions.IgnoreCase | RegexOptions.Singleline);
        private static readonly Regex UsesLabel = new Regex(@"^(product\s+)?uses?$", RegexOptions.IgnoreCase);
        private static readonly Regex Tag = new Regex(@"<!--.*?-->|<(/?)([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>", RegexOptions.Singleline);
        private static readonly HashSet<string> VoidElements = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"
        };
        // Browsers close these themselves, and turn a stray </p> into an empty paragraph, so they're never added
        private static readonly HashSet<string> OptionalEndElements = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "p", "li", "dt", "dd", "option", "tr", "td", "th"
        };

        private ProductDescription()
        {
            IntroHtml = "";
            Specs = new List<ProductSpec>();
            Uses = new List<string>();
            Sections = new List<ProductDescriptionSection>();
        }

        // The paragraphs before the first heading (HTML from the database), or "".
        public string IntroHtml { get; private set; }

        // The "Label: value" lines, e.g. "Bag sizes" / "Approx 850kg, 1000kg Bulk Bags and 20kg Sealed Bags",
        // without the uses.
        public List<ProductSpec> Specs { get; private set; }

        // The "Uses" line split up, e.g. "Driveways", "Water Features", "Rockeries".
        public List<string> Uses { get; private set; }

        // The other sections, e.g. "Colour and Shape", "Availability".
        public List<ProductDescriptionSection> Sections { get; private set; }

        public static ProductDescription Parse(string html)
        {
            var result = new ProductDescription();
            if (string.IsNullOrWhiteSpace(html))
            {
                return result;
            }

            html = html.Trim();
            MatchCollection headings = Heading.Matches(html);
            result.IntroHtml = (headings.Count > 0 ? html.Substring(0, headings[0].Index) : html).Trim();
            for (int i = 0; i < headings.Count; i++)
            {
                int start = headings[i].Index + headings[i].Length;
                int end = i + 1 < headings.Count ? headings[i + 1].Index : html.Length;
                result.Sections.Add(new ProductDescriptionSection(ToText(headings[i].Groups[1].Value), html.Substring(start, end - start).Trim()));
            }

            // Some start with a "Description" heading instead of intro paragraphs
            if (ToText(result.IntroHtml).Length == 0 && result.Sections.Count > 0 && result.Sections[0].Heading.Equals("Description", StringComparison.OrdinalIgnoreCase))
            {
                result.IntroHtml = result.Sections[0].Html;
                result.Sections.RemoveAt(0);
            }

            // The first section made only of "Label: value" lines becomes the specification table. Its heading
            // (usually the product name again) isn't needed under "Product Specification".
            for (int i = 0; i < result.Sections.Count; i++)
            {
                List<ProductSpec> specs = ParseSpecs(result.Sections[i].Html);
                if (specs != null)
                {
                    result.Specs = specs.Where(s => !UsesLabel.IsMatch(s.Label)).ToList();
                    ProductSpec uses = specs.FirstOrDefault(s => UsesLabel.IsMatch(s.Label));
                    if (uses != null)
                    {
                        result.Uses = CategoryDescription.SplitIdealFor(uses.Value)
                            .Select(u => u.Substring(0, 1).ToUpperInvariant() + u.Substring(1))
                            .ToList();
                    }
                    result.Sections.RemoveAt(i);
                    break;
                }
            }

            // Cutting at the headings can split an element, e.g. "<div><h3>Loose Load Deliveries</h3>...</div>",
            // and a stray </div> would close the page's own layout, so each piece is made whole
            result.IntroHtml = Balance(result.IntroHtml);
            result.Sections = result.Sections.Select(s => new ProductDescriptionSection(s.Heading, Balance(s.Html))).ToList();
            return result;
        }

        // The HTML with a closing tag dropped when nothing in it opened that element, and elements left open
        // closed at the end.
        public static string Balance(string html)
        {
            var result = new System.Text.StringBuilder();
            var open = new List<string>();
            int last = 0;
            foreach (Match tag in Tag.Matches(html ?? ""))
            {
                result.Append(html, last, tag.Index - last);
                last = tag.Index + tag.Length;
                string name = tag.Groups[2].Value.ToLowerInvariant();
                if (name.Length == 0 || VoidElements.Contains(name) || tag.Value.EndsWith("/>"))
                {
                    result.Append(tag.Value);   // a comment, or an element with no closing tag
                }
                else if (tag.Groups[1].Value.Length == 0)
                {
                    open.Add(name);
                    result.Append(tag.Value);
                }
                else
                {
                    int at = open.LastIndexOf(name);
                    if (at < 0)
                    {
                        continue;   // nothing here to close: drop it
                    }
                    for (int i = open.Count - 1; i > at; i--)
                    {
                        if (!OptionalEndElements.Contains(open[i]))
                        {
                            result.Append("</" + open[i] + ">");
                        }
                    }
                    open.RemoveRange(at, open.Count - at);
                    result.Append(tag.Value);
                }
            }
            if (html != null)
            {
                result.Append(html, last, html.Length - last);
            }
            for (int i = open.Count - 1; i >= 0; i--)
            {
                if (!OptionalEndElements.Contains(open[i]))
                {
                    result.Append("</" + open[i] + ">");
                }
            }
            return result.ToString().Trim();
        }

        // The lines of a section that has two or more "<b>Label:</b> value" lines and nothing else, or null.
        private static List<ProductSpec> ParseSpecs(string html)
        {
            var specs = new List<ProductSpec>();
            foreach (Match line in SpecLine.Matches(html))
            {
                string label = ToText(line.Groups["label"].Value);
                string value = ToText(line.Groups["value"].Value);
                // The colon is inside the bold ("<b>Colour:</b> Blue") or just after it ("<b>Colour</b>: Blue")
                if (label.EndsWith(":"))
                {
                    label = label.TrimEnd(':').Trim();
                }
                else if (value.StartsWith(":"))
                {
                    value = value.TrimStart(':').Trim();
                }
                else
                {
                    return null;
                }
                if (label.Length == 0 || value.Length == 0)
                {
                    return null;
                }
                specs.Add(new ProductSpec(label, value));
            }
            if (specs.Count < 2 || ToText(SpecLine.Replace(html, "")).Length > 0)
            {
                return null;
            }
            return specs;
        }

        // Plain text: tags removed, entities decoded, spaces (including non-breaking ones) collapsed.
        private static string ToText(string html)
        {
            string text = WebUtility.HtmlDecode(Regex.Replace(html ?? "", "<[^>]+>", " "));
            return Regex.Replace(text.Replace(' ', ' '), @"\s+", " ").Trim();
        }
    }

    public class ProductSpec
    {
        public ProductSpec(string label, string value)
        {
            Label = label;
            Value = value;
        }

        public string Label { get; private set; }

        public string Value { get; private set; }
    }

    public class ProductDescriptionSection
    {
        public ProductDescriptionSection(string heading, string html)
        {
            Heading = heading;
            Html = html;
        }

        // Plain text, e.g. "Availability on Cotswold Chippings"
        public string Heading { get; private set; }

        // HTML from the database
        public string Html { get; private set; }
    }
}
