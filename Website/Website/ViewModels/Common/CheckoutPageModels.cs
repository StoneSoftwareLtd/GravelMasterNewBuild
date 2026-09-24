using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new checkout (Views/Checkout/_CheckoutPage.cshtml) shows. Checkout/ProcessOrder.cshtml fills it from its
    // OrderViewModel; see docs/merging.md. The page posts the same fields the old one did.
    public class CheckoutPageModel
    {
        public CheckoutPageModel()
        {
            Lines = new List<CheckoutLine>();
            Dates = new List<CheckoutDate>();
            Address = new CheckoutAddress();
        }

        // The cart's lines, in the cart's order.
        public List<CheckoutLine> Lines { get; set; }

        // Cart.Total: after any voucher, before the delivery choices below.
        public decimal Total { get; set; }

        // OrderViewModel.DefaultAddress: the account's saved address when logged in, else empty.
        public CheckoutAddress Address { get; set; }

        // Shows "Already have an account? Log in" when false.
        public bool IsLoggedIn { get; set; }

        // Session["PA"]: the postcode area the basket was priced for (e.g. "NG"), or null.
        public string PostalArea { get; set; }

        // True when the server checks the delivery postcode against PostalArea (a cart that isn't IsSimple): its
        // letters must be the area exactly. Otherwise the page checks as the old page's script did: the postcode
        // only has to contain the area.
        public bool StrictPostalArea { get; set; }

        public CheckoutDelivery Delivery { get; set; }

        // CheckoutDelivery.ChooseDate: the dates offered, from CheckoutDates.Build.
        public List<CheckoutDate> Dates { get; set; }

        // Every other kind: the "selectedDelDay" the old page posted without asking ("dd-MM-yy").
        public string PostedDay { get; set; }

        // The date PostedDay stands for, for the order summary (CheckoutDelivery.NoChoice).
        public DateTime? PostedDate { get; set; }

        // Prices.DeliveryTimeVisible and Prices.DeliveryTimeCost: the morning slot.
        public bool ShowTimes { get; set; }

        public decimal MorningCost { get; set; }

        // Cart.IsMixedPreOrder: a pre-order size with in-stock ones.
        public bool IsMixedPreOrder { get; set; }

        // The first pre-order size's date (the server uses it as the delivery day for a pre-order-only cart).
        public DateTime? PreOrderDate { get; set; }

        // Shows "Trade customer? Get trade prices" when the customer isn't a trade account.
        public bool ShowTradeLink { get; set; }
    }

    // How the delivery day is decided, as the old page decided it.
    public enum CheckoutDelivery
    {
        // The customer picks a date (and a time, when the morning slot is on).
        ChooseDate,

        // Samples and bird feeders (Cart.IsSamples or IsBirdFeeder): Royal Mail, no date to pick.
        RoyalMail,

        // Only pre-order sizes (Cart.IsOnlyPreOrder): delivered from their pre-order date.
        PreOrder,

        // Cart.IsSimple: the old page skipped the delivery step and posted the first free date.
        NoChoice
    }

    public class CheckoutAddress
    {
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string City { get; set; }
        public string County { get; set; }
        public string Postcode { get; set; }
    }

    // One line of the order summary.
    public class CheckoutLine
    {
        // The product's name as the old view shows it (Html.Raw: some names hold entities such as &amp;).
        public string NameHtml { get; set; }

        // The size (Product.VariantsNameWithoutImage, Html.Raw).
        public string SizeHtml { get; set; }

        // The 330px photo.
        public string ImageUrl { get; set; }

        public int Quantity { get; set; }

        // OrderItem.OrderLinePrice: the line's total after any voucher, as the old summary shows it.
        public decimal LinePrice { get; set; }

        public DateTime? PreOrderDate { get; set; }
    }

    // A delivery date the customer can pick.
    public class CheckoutDate
    {
        public DateTime Day { get; set; }

        // The delivery charge for this date (the old page's data-price).
        public decimal Cost { get; set; }

        public bool IsWeekend
        {
            get { return Day.DayOfWeek == DayOfWeek.Saturday || Day.DayOfWeek == DayOfWeek.Sunday; }
        }

        // False for weekend dates when weekend delivery isn't offered: the old page showed them greyed out.
        public bool Available { get; set; }

        // The old page's eco-friendly truck picture.
        public bool IsEco { get; set; }

        // Picked when the page opens: the first free weekday.
        public bool IsDefault { get; set; }

        // What "selectedDelDay" posts.
        public string Value
        {
            get { return Day.ToString("dd-MM-yy", CultureInfo.InvariantCulture); }
        }
    }

    // What decides which dates the old page showed, and at what price.
    public class CheckoutDateRules
    {
        // Session["PA"], or null.
        public string PostalArea { get; set; }

        // Cart.IsRubber, Cart.IsBulk, Cart.IsTurf.
        public bool IsRubber { get; set; }
        public bool IsBulk { get; set; }
        public bool IsTurf { get; set; }

        // Prices.NextDayCost: charged on a bulk order's first weekday.
        public decimal NextDayCost { get; set; }

        // OrderViewModel.NumDaysTruck: dates on this day of the month get the eco-friendly mark.
        public int EcoDayOfMonth { get; set; }

        // !OrderViewModel.SpecialAreas.Contains(area) && Prices.SaturdayVisible.
        public bool WeekendAllowed { get; set; }
    }

    public static class CheckoutDates
    {
        // The old view's postcode areas whose first date is skipped, and the islands whose first nine are.
        static readonly string[] QuickAreas = { "PL", "TA", "TQ", "TR", "EX", "KT" };
        static readonly string[] ChannelAreas = { "GY", "JE", "IM" };

        // The dates Checkout/ProcessOrder.cshtml showed, from OrderViewModel.DeliveryDays (date and cost), with the
        // same rules in the same order. "now" is DateTime.Now; it's a parameter so the rules can be tested.
        public static List<CheckoutDate> Build(IEnumerable<KeyValuePair<DateTime, decimal>> days, CheckoutDateRules rules, DateTime now)
        {
            string area = rules.PostalArea == null ? null : rules.PostalArea.ToUpperInvariant();
            bool isQuick = area != null && QuickAreas.Contains(area);
            bool isChannel = area != null && ChannelAreas.Contains(area);
            int skipped = 1;            // the old view's "indexer2"
            bool defaultFound = false;
            bool turfFirst = false;
            bool firstDay = true;
            var dates = new List<CheckoutDate>();

            foreach (var pair in days)
            {
                DateTime day = pair.Key;
                decimal cost = pair.Value;

                if ((isQuick && skipped < 2) || (isChannel && skipped < 10))
                {
                    skipped++;
                    continue;
                }
                bool christmas = (day.Day > 23 && day.Month == 12) || (day.Day < 4 && day.Month == 1);
                if ((rules.IsRubber && skipped == 1) || christmas)
                {
                    skipped++;
                    continue;
                }
                bool weekend = day.DayOfWeek == DayOfWeek.Saturday || day.DayOfWeek == DayOfWeek.Sunday;
                if (firstDay && rules.IsBulk && !weekend)
                {
                    cost = rules.NextDayCost;
                    firstDay = false;
                }
                if (rules.IsTurf && !turfFirst && (day.Date - now).TotalDays < 2.55)
                {
                    turfFirst = true;
                    continue;
                }
                if (rules.IsTurf && day.Day == 24 && day.Month == 4)
                {
                    continue;
                }

                var date = new CheckoutDate
                {
                    Day = day,
                    Cost = cost,
                    Available = !weekend || rules.WeekendAllowed,
                    IsEco = day.Day == rules.EcoDayOfMonth
                };
                if (!weekend && cost == 0 && !defaultFound)
                {
                    date.IsDefault = true;
                    defaultFound = true;
                }
                dates.Add(date);
            }
            return dates;
        }
    }
}
