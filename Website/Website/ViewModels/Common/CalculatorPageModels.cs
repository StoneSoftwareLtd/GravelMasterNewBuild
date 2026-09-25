using System.Collections.Generic;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new calculator page (Views/Content/_CalculatorPage.cshtml) shows. Content/Calculator.cshtml fills it;
    // see docs/merging.md.
    public class CalculatorPageModel
    {
        public CalculatorPageModel()
        {
            Calculator = new QuantityCalculatorModel(null);
            Products = new List<HomeProduct>();
            EnquiryCategories = new List<string>();
        }

        // The shared quantity calculator. It opens on its first type, Gravel & Chippings, as the old page did.
        public QuantityCalculatorModel Calculator { get; set; }

        // The gravels the old page shows under its calculator, with their "From" prices. One that's no longer on sale
        // is left out.
        public List<HomeProduct> Products { get; set; }

        // Top-level category names in menu order, for the bulk enquiry pop-up the calculator's "Enquire Here" opens.
        public List<string> EnquiryCategories { get; set; }
    }
}
