using System;
using System.Collections.Generic;
using System.Net;
using System.Text.RegularExpressions;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // The pages behind the sign-in (Views/MyAccount/_*Page.cshtml). Each old view fills its model from its own
    // MyAccountViewModel (or ReturnRequestViewModel); see docs/merging.md.

    // The parts of My Account, for the tabs.
    public enum AccountSection
    {
        Orders,
        Returns,
        PriceMatch,
        Address
    }

    // The greeting and tabs at the top of every My Account page (Views/MyAccount/_AccountAreaHead.cshtml).
    public class AccountAreaModel
    {
        public AccountAreaModel()
        {
            ShowReturns = true;
        }

        // Customer.FirstName and LastName, and the email address signed in with (MyAccountViewModel.Email).
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }

        // TradeRegister.IsTrade: the old side column said "Trade Portal" rather than "Customer Portal".
        public bool IsTrade { get; set; }

        // The Returns tab and the orders' "Request a return": on master, which has the returns pages.
        public bool ShowReturns { get; set; }

        public AccountSection Section { get; set; }
    }

    // /myaccount/orders: the order history, one card per order.
    public class AccountOrdersModel
    {
        public AccountOrdersModel()
        {
            Area = new AccountAreaModel { Section = AccountSection.Orders };
            Orders = new List<AccountOrder>();
        }

        public AccountAreaModel Area { get; set; }
        public List<AccountOrder> Orders { get; set; }
    }

    public class AccountOrder
    {
        public AccountOrder()
        {
            Lines = new List<AccountOrderLine>();
        }

        // Order.OrderID.
        public string Number { get; set; }

        // Order.DateCreated.
        public DateTime Date { get; set; }

        // The delivery address's lines, without blank ones; and its postcode, which Track Order asks for.
        public string DeliveryAddress { get; set; }
        public string DeliveryPostcode { get; set; }

        public List<AccountOrderLine> Lines { get; set; }
    }

    public class AccountOrderLine
    {
        // OrderItem.OrderItemID: what "Request a return" sends.
        public int ItemId { get; set; }

        // The product's name, page and 330px photo, when the product is still on the site (null when it isn't). The old
        // page asked for the 300px size, which most products don't have.
        public string ProductName { get; set; }
        public string Url { get; set; }
        public string ImageUrl { get; set; }

        // What was ordered, from OrderItem.ProductName (see Describe).
        public string Description { get; set; }

        // OrderItem.Quantity, as the old page shows it.
        public string Quantity { get; set; }

        // OrderItem.ProductName is saved as Product.NameWithVariants: the product's name, then each size or option,
        // each followed by "<br/>" ("Name<br/>Size<br/>"). The old page removed the HTML, which ran them together; this
        // lists them with commas, leaving out the product's name (shown above it as a link). Empty when there's only
        // the name.
        public static string Describe(string savedName, string productName)
        {
            if (string.IsNullOrWhiteSpace(savedName))
            {
                return "";
            }
            var parts = new List<string>();
            foreach (string piece in Regex.Split(savedName, @"<br\s*/?>", RegexOptions.IgnoreCase))
            {
                string text = WebUtility.HtmlDecode(Regex.Replace(piece, "<[^>]*>", " "));
                text = Regex.Replace(text, @"\s+", " ").Trim().TrimEnd(',', ' ');
                if (text.Length > 0)
                {
                    parts.Add(text);
                }
            }
            string name = string.IsNullOrWhiteSpace(productName) ? "" : Regex.Replace(productName, @"\s+", " ").Trim();
            if (name.Length > 0 && parts.Count > 0)
            {
                string first = parts[0];
                if (string.Equals(first, name, StringComparison.OrdinalIgnoreCase))
                {
                    parts.RemoveAt(0);
                }
                else if (first.Length > name.Length && first.StartsWith(name, StringComparison.OrdinalIgnoreCase) && !char.IsLetterOrDigit(first[name.Length]))
                {
                    // the name and size saved without the <br/> between them
                    parts[0] = first.Substring(name.Length).TrimStart(' ', ',', '-', ':');
                }
            }
            return string.Join(", ", parts);
        }
    }

    // /myaccount/requestreturn: the item and the return form.
    public class AccountReturnModel
    {
        public AccountReturnModel()
        {
            Area = new AccountAreaModel { Section = AccountSection.Returns };
        }

        public AccountAreaModel Area { get; set; }

        // The order, with only the item being returned.
        public AccountOrder Order { get; set; }

        // ReturnRequestViewModel.OrderItemId: sent back with the form.
        public int OrderItemId { get; set; }
    }

    // /myaccount/returnconfirmation: TempData["ReturnOrderId"], when there is one.
    public class AccountReturnDoneModel
    {
        public AccountReturnDoneModel()
        {
            Area = new AccountAreaModel { Section = AccountSection.Returns };
        }

        public AccountAreaModel Area { get; set; }
        public string OrderNumber { get; set; }
    }

    // /myaccount/editaddress: the saved address the checkout fills in (CustomerRepository.RetrieveAddress).
    public class AccountAddressModel
    {
        public AccountAddressModel()
        {
            Area = new AccountAreaModel { Section = AccountSection.Address };
        }

        public AccountAreaModel Area { get; set; }
        public int AddressId { get; set; }
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string City { get; set; }
        public string County { get; set; }
        public string Postcode { get; set; }
    }
}
