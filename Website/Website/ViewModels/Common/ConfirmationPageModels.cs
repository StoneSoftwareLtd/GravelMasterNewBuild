using System.Collections.Generic;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new order confirmation (Views/Checkout/_ConfirmationPage.cshtml) shows. Checkout/OrderResult.cshtml
    // fills it from its OrderResultViewModel; see docs/merging.md.
    public class ConfirmationPageModel
    {
        public ConfirmationPageModel()
        {
            Suggestions = new List<BasketSuggestion>();
        }

        // Order.OrderID: the number customers quote, and what Track Order asks for.
        public string OrderNumber { get; set; }

        // Order.Amount: what was paid, delivery included.
        public decimal AmountPaid { get; set; }

        // Order.Email: where the confirmation email goes.
        public string Email { get; set; }

        // Order.DeliveryAddress.ToString(", "), as the old page shows it.
        public string DeliveryAddress { get; set; }

        // Order.DeliveryAddress.Postcode: filled in for Track Order, which asks for the order number and a postcode.
        public string DeliveryPostcode { get; set; }

        // Session["PA"]: the postcode area the prices are for, or null. Adding a suggestion sends it, as on the basket.
        public string PostalArea { get; set; }

        // "You might also like": products added with one click, then the customer is taken to the basket.
        public List<BasketSuggestion> Suggestions { get; set; }
    }
}
