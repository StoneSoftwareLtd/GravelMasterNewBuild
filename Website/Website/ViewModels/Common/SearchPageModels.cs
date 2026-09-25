using System.Collections.Generic;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new search results page (Views/Category/_SearchPage.cshtml) shows. Category/DisplayProducts.cshtml, the
    // search's view, fills it from its CategoryProductsViewModel; see docs/merging.md.
    public class SearchPageModel
    {
        public SearchPageModel()
        {
            Products = new List<CategoryProduct>();
            Categories = new List<CategoryLink>();
        }

        // What was searched for, as sent by the header's search box ("searchphrase"). Blank when nothing was typed: the
        // site then lists every product.
        public string Phrase { get; set; }

        // Phrase without the spaces around it, for showing; "" when nothing was typed.
        public string ShownPhrase
        {
            get { return (Phrase ?? "").Trim(); }
        }

        // The products found, in the old page's order, as the category page's cards.
        public List<CategoryProduct> Products { get; set; }

        // More products matched than the site shows on one page (100), so some aren't listed.
        public bool HasMore { get; set; }

        // The top-level categories in menu order, each linking to its category page: offered when nothing is found,
        // or not everything is shown.
        public List<CategoryLink> Categories { get; set; }
    }
}
