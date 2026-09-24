namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // The shared quantity calculator (Views/Shared/_QuantityCalculator.cshtml) on the new homepage and product page.
    public class QuantityCalculatorModel
    {
        public QuantityCalculatorModel(string type)
        {
            Type = type;
        }

        // The product type chosen when the page opens: "gravel", "mulch", "topsoil" or "sand" (the calculator's
        // options), or null for the first.
        public string Type { get; private set; }

        // The calculator type for a product's calculator setting (ProductViewModel.Calc), or null when the product
        // has none. Gravel and slate share the gravel formula, as on the old product page.
        public static string ForProduct(string calc)
        {
            switch ((calc ?? "").Trim().ToLowerInvariant())
            {
                case "gravel":
                case "slate":
                    return "gravel";
                case "bark":
                    return "mulch";
                case "soil":
                    return "topsoil";
                case "sand":
                    return "sand";
                default:
                    return null;
            }
        }
    }
}
