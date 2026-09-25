using System.Collections.Generic;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    // What the new sign-in page (Views/Account/_SignInPage.cshtml) shows. Account/Login.cshtml fills it from its
    // LoginViewModel and ModelState; see docs/merging.md.
    public class SignInPageModel
    {
        public SignInPageModel()
        {
            Errors = new List<string>();
        }

        // LoginViewModel.Email, FirstName and LastName: typed in again after a failed sign-in or registration, and an
        // approved trade customer's details (IsTradeConfirm).
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }

        // LoginViewModel.IsTradeConfirm: an approved trade customer creating their login (from the approval email).
        public bool IsTradeConfirm { get; set; }

        // LoginViewModel.IsRegistration: shown again after a failed registration, so the errors are the register form's.
        public bool IsRegistration { get; set; }

        // LoginViewModel.IsTradeRegistration: opened as /account/login?isTradeRegister=true, with the trade form showing.
        public bool IsTradeRegistration { get; set; }

        // The page's ModelState errors (Html.ValidationSummary on the old page).
        public List<string> Errors { get; set; }
    }

    // The forgotten-password and reset-password forms (Views/Account/_ForgotPasswordPage.cshtml, _ResetPasswordPage.cshtml).
    public class AccountFormModel
    {
        public AccountFormModel()
        {
            Errors = new List<string>();
        }

        public string Email { get; set; }

        // ResetPasswordViewModel.Code: the reset link's code, sent back with the new password.
        public string Code { get; set; }

        public List<string> Errors { get; set; }
    }

    // The account pages that only say something (Views/Account/_AccountMessagePage.cshtml). Their words are in the partial.
    public enum AccountMessage
    {
        // ForgotPasswordConfirmation.cshtml
        PasswordResetEmailSent,

        // ResetPasswordConfirmation.cshtml
        PasswordReset,

        // ConfirmEmail.cshtml
        EmailConfirmed,

        // SuccessRegister.cshtml
        Registered,

        // TradeRegisterDone.cshtml
        TradeApplicationSent
    }
}
