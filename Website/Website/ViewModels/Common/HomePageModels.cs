using System;
using System.Globalization;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // A hero slide on the new homepage (Views/Home/_HomePage.cshtml): one of the banners managed in the admin site.
    public class HomeBanner
    {
        public HomeBanner(string link, string imageUrl, string alt)
        {
            Link = link;
            ImageUrl = imageUrl;
            Alt = alt ?? "";
        }

        public string Link { get; private set; }

        public string ImageUrl { get; private set; }

        public string Alt { get; private set; }
    }

    // What the new homepage's offer and bestseller cards show about a product.
    public class HomeProduct
    {
        private static readonly CultureInfo UkCulture = CultureInfo.GetCultureInfo("en-GB");
        private readonly string imageUrlFormat;

        // imageUrlFormat has {0} where the image width goes, e.g. "https://cdn.gravelmaster.co.uk/optimised/20COTS-{0}.jpg"
        public HomeProduct(string name, string url, string imageUrlFormat, decimal price, decimal tradePrice)
        {
            Name = name;
            Url = url;
            this.imageUrlFormat = imageUrlFormat;
            Price = price;
            TradePrice = tradePrice;
        }

        public string Name { get; private set; }

        public string Url { get; private set; }

        // Lowest ("From") customer price, including VAT and delivery.
        public decimal Price { get; private set; }

        // Lowest ("From") trade price, including VAT and delivery.
        public decimal TradePrice { get; private set; }

        // The product photo at one of the CDN's widths (95, 330, 600 or 1000).
        public string ImageUrl(int width)
        {
            return string.Format(CultureInfo.InvariantCulture, imageUrlFormat, width);
        }

        // "£91.00" with pence, or "£91" without (pence are still shown when there are any, e.g. "£4.99").
        public static string FormatPrice(decimal price, bool withPence)
        {
            if (withPence || price != Math.Floor(price))
            {
                return "£" + price.ToString("#,0.00", UkCulture);
            }
            return "£" + price.ToString("#,0", UkCulture);
        }
    }
}
