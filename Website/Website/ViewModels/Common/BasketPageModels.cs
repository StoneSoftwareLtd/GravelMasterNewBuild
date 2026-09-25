using System;
using System.Collections.Generic;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new basket page (Views/Basket/_BasketPage.cshtml) shows. Basket/Index.cshtml fills it from the cart
    // (BasketViewModel.Cart), exactly as the old view shows it; see docs/merging.md.
    public class BasketPageModel
    {
        public BasketPageModel()
        {
            Lines = new List<BasketLine>();
            Suggestions = new List<BasketSuggestion>();
        }

        // The cart's lines, in the cart's order: the basket form posts one quantity per line in this order.
        public List<BasketLine> Lines { get; set; }

        // Cart.NumItems: the quantities added up.
        public int ItemCount { get; set; }

        // Cart.SubTotalExclDiscount: before any voucher discount.
        public decimal SubTotal { get; set; }

        // Cart.Total: after the discount, including delivery and VAT.
        public decimal Total { get; set; }

        // The voucher discount, when a voucher takes something off.
        public decimal Discount
        {
            get { return Math.Max(0, SubTotal - Total); }
        }

        // Whether the voucher box shows (the "data-coupon-display" content setting, BasketViewModel.ShowCoupon).
        public bool ShowVoucher { get; set; }

        // Cart.CouponMessage after a voucher attempt: the voucher's description, or why it didn't apply.
        public string VoucherMessage { get; set; }

        // The postcode area the prices are for (BasketViewModel.PostalArea), or null. Adding a suggestion sends it.
        public string PostalArea { get; set; }

        // "Add to your order": products offered below the basket, as the old page's "weekly special offers".
        public List<BasketSuggestion> Suggestions { get; set; }
    }

    // One line of the basket.
    public class BasketLine
    {
        // OrderItem.ItemGuid: what Remove sends.
        public Guid Id { get; set; }

        // The product's name as the old view shows it (Html.Raw: some names hold entities such as &amp;).
        public string NameHtml { get; set; }

        public string Url { get; set; }

        // The 330px photo.
        public string ImageUrl { get; set; }

        // The size, as the old view shows it (Product.VariantsNameWithoutImage, Html.Raw).
        public string SizeHtml { get; set; }

        // Product.Price: one of these, for the delivery area.
        public decimal UnitPrice { get; set; }

        public int Quantity { get; set; }

        // False for turf (codes starting TT2 or TT3), whose quantity is set on its product page: the old view
        // shows no + and - for it.
        public bool CanChangeQuantity { get; set; }

        // OrderItem.LineDiscountView: the voucher discount on this line.
        public decimal Discount { get; set; }

        // OrderItem.LinePrice: the line's total.
        public decimal LinePrice { get; set; }

        // Product.PreOrderDate: the week a pre-order size is expected, or null.
        public DateTime? PreOrderDate { get; set; }

        // The size has sold out: its own product's StockLevel is set and 0 or less, the test BasketController.AddToBasket
        // makes before adding it. A size whose StockLevel is empty isn't counted, and is in stock.
        public bool IsOutOfStock { get; set; }
    }

    // A product offered below the basket, added with one click.
    public class BasketSuggestion
    {
        public BasketSuggestion(string name, string url, string imageUrl, decimal price, string priceUnit, string productCode, string variantCode)
        {
            Name = name;
            Url = url;
            ImageUrl = imageUrl;
            Price = price;
            PriceUnit = priceUnit;
            ProductCode = productCode;
            VariantCode = variantCode;
        }

        public string Name { get; private set; }

        public string Url { get; private set; }

        // The 330px photo.
        public string ImageUrl { get; private set; }

        public decimal Price { get; private set; }

        // "per roll", "per set", or null.
        public string PriceUnit { get; private set; }

        // What /basket/addtobasket takes: the product code (id) and the size's code (selectedVariantCode).
        public string ProductCode { get; private set; }

        public string VariantCode { get; private set; }
    }
}
