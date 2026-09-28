namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new payment error page (Views/Checkout/_PaymentErrorPage.cshtml) shows. Checkout/Error.cshtml makes it
    // from the address's "loc", which CheckoutController.ProcessOrder adds when the delivery postcode isn't in the
    // postcode area the basket was priced for; without it, the page is for any other problem with the payment.
    public class PaymentErrorModel
    {
        public PaymentErrorModel(string loc)
        {
            Area = AreaOf(loc);
        }

        // The basket's postcode area in capitals ("NG"), or null. Only its letters are kept: the old page wrote "loc"
        // into the page as it came.
        public string Area { get; private set; }

        // "ng" -> "NG"; "CM77 8BE" -> "CM"; "" or no letters -> null
        public static string AreaOf(string loc)
        {
            if (string.IsNullOrWhiteSpace(loc)) return null;
            string text = loc.Trim();
            int n = 0;
            while (n < text.Length && n < 2 && char.IsLetter(text[n]) && text[n] < 128) n++;
            return n == 0 ? null : text.Substring(0, n).ToUpperInvariant();
        }
    }
}
