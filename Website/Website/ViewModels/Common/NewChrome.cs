using System.Configuration;
using System.Web;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // The new Optima design's switch, in one place for _Layout and every view that shows a new page. A view runs before
    // its layout, so it can't read _Layout's own variable; it asks this instead and gets the same answer.
    public static class NewChrome
    {
        public const string CookieName = "gm-newchrome";

        // On when appSettings UseNewChrome is "true". ?newchrome=1 or ?newchrome=0 overrides it, and _Layout keeps that
        // choice in a cookie for the rest of the visit (sign-off on a test site).
        public static bool IsOn(HttpRequestBase request)
        {
            string choice = Override(request);
            if (choice == null && request.Cookies[CookieName] != null)
            {
                choice = request.Cookies[CookieName].Value;
            }
            return choice == "1" || choice == "0"
                ? choice == "1"
                : ConfigurationManager.AppSettings["UseNewChrome"] == "true";
        }

        // "1" or "0" when this request's address sets the switch, otherwise null.
        public static string Override(HttpRequestBase request)
        {
            string choice = request.QueryString["newchrome"];
            return choice == "1" || choice == "0" ? choice : null;
        }
    }
}
