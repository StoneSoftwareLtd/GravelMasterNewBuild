using System.Collections.Generic;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new special offers page (Views/Product/_OffersPage.cshtml) shows. Product/SpecialOffers.cshtml, the
    // page's view, fills it from its CategoryProductsViewModel; see docs/merging.md.
    public class OffersPageModel
    {
        public OffersPageModel()
        {
            Products = new List<CategoryProduct>();
            Categories = new List<CategoryLink>();
        }

        // The products on the page, in the old page's order, as the category page's cards.
        public List<CategoryProduct> Products { get; set; }

        // The top-level categories in menu order, each linking to its category page: offered when there are no products.
        public List<CategoryLink> Categories { get; set; }
    }
}
