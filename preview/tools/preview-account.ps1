# The preview's own accounts, and the forms that would send an email. Dot-sourced by site-preview.ps1, after
# account-pages.ps1 and myaccount-pages.ps1.
#
# No cookies reach the live site, so the preview can never sign in there. It keeps accounts of its own instead, in
# memory while it runs (one signed-in customer for whoever is using the preview), and answers the account addresses
# the way AccountController and MyAccountController do:
#   /account/login               signs in, or sends the page back with "Either your email or password was wrong" or
#                                "You haven't confirmed your email"; then /myaccount/index
#   /account/register            makes an account (or sends the page back with its errors) and shows "Nearly there";
#                                the preview shows the confirmation email's link on that page, as it sends no email
#   /account/confirmemail        that link: confirms the account
#   /account/traderegister       a trade application; the preview shows the approval email's link
#                                (/account/login?tradeEmail=), which opens "You're in!", whose account is a trade one
#   /account/forgotpassword      "Check your email"; the preview shows the email's link (/account/resetpassword?code=)
#   /account/resetpassword       changes the password with that link's code
#   /account/logoff              signs out
#   /myaccount/getuser           the signed-in customer's first name, for the header
#   /product/istrade             whether they have a trade account
#   /myaccount/editaddress       saves their address (the checkout fills it in)
#   /myaccount/requestreturn     a return request for one of their items
# The sample customer (Get-SampleAccount's, with its two sample orders) has the test password below. Accounts made in
# the preview have no orders: payment isn't set up, so no checkout makes one.
#
# Forms that would send an email answer as the site does but send nothing (the preview's window lists what they
# would have sent): the bulk enquiry (/basket/sendlooseenquiry), "Send me my estimate"
# (/email/sendcalculatorcalculation), the price match message (/product/sendpricematchquery) and the newsletter
# (/product/newsletterregister). A return request and a trade application send nothing either.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

# The sample customer's test password (preview only; it isn't anyone's real password)
$script:sampleAccountEmail = 'sample.customer@example.com'
$script:sampleAccountPassword = 'Preview-Sample-1'

$script:previewAccounts = @{}           # email (lower case) -> account
$script:previewSignedIn = $null         # the signed-in account's email (lower case)
$script:previewResetCodes = @{}         # the reset email's code -> email
$script:previewTradeApplications = @{}  # email -> the trade application
$script:previewLastLink = $null         # the link the last "email" would have had, shown once on the next page
$script:previewLastReturn = $null       # the last return request (MyAccountController's TempData), shown once

function Initialize-PreviewAccounts {
  if ($script:previewAccounts.Count) { return }
  $script:previewAccounts[$script:sampleAccountEmail] = [pscustomobject]@{
    Id = [guid]::NewGuid().ToString(); Email = $script:sampleAccountEmail; FirstName = 'Sam'; LastName = 'Sample'
    Password = $script:sampleAccountPassword; Confirmed = $true; ConfirmCode = $null; IsTrade = $false; IsSample = $true
    Address = [pscustomobject]@{ AddressId = 4242; Address1 = '1 Sample Street'; Address2 = ''; City = 'Nottingham'; County = 'Nottinghamshire'; Postcode = 'NG7 2RD' }
  }
}

function Get-PreviewSignedIn {
  Initialize-PreviewAccounts
  if ($script:previewSignedIn) { $script:previewAccounts[$script:previewSignedIn] } else { $null }
}

function New-PreviewCode { [Convert]::ToBase64String([guid]::NewGuid().ToByteArray()).TrimEnd('=').Replace('+', '-').Replace('/', '_') }

# What My Account's pages show for the signed-in account (Format-MyAccountPage's model)
function Get-PreviewAccountPage($account) {
  $orders = if ($account.IsSample) { @((Get-SampleAccount @()).Orders) } else { @() }
  [pscustomobject]@{
    Area = [pscustomobject]@{ FirstName = $account.FirstName; LastName = $account.LastName; Email = $account.Email; IsTrade = $account.IsTrade; ShowReturns = $true; Section = 'Orders' }
    Orders = $orders
    Address = $account.Address
    ReturnOrderNumber = $(if ($script:previewLastReturn) { $script:previewLastReturn.OrderNumber } else { $null })
  }
}

# The sign-in page's model (Get-SampleSignIn's shape)
function New-SignInModel([string]$email, [string]$first, [string]$last, [bool]$registration, [bool]$tradeConfirm, [string[]]$errors) {
  [pscustomobject]@{ Email = $email; FirstName = $first; LastName = $last; IsTradeConfirm = $tradeConfirm; IsRegistration = $registration; IsTradeRegistration = $false; Errors = @($errors | Where-Object { $_ }) }
}

# /account/login?tradeEmail=: the approval email's link. AccountController.Login looks the application up and opens
# "You're in!" with its names and email; in the preview, following the link is the approval
function Get-PreviewTradeConfirm([string]$email) {
  $application = $script:previewTradeApplications[([string]$email).ToLowerInvariant()]
  if (-not $application) { return $null }
  $application.Approved = $true
  New-SignInModel $application.Email $application.First $application.Last $false $true @()
}

# A preview notice, for the page after a form that would have sent an email
function Format-PreviewEmailNotice([string]$text) {
  '<p style="margin:0;padding:8px 18px;background:#fff4d6;color:#4a3b00;font:600 14px/1.5 Quicksand,Arial,sans-serif;text-align:center">Preview: ' + $text + '</p>'
}

# Answers one of the account or email addresses. $query and $form: the request's NameValueCollections. Returns
# Location (a redirect), or Body and ContentType, or Render: 'signin' with Model, 'message' with Message, or 'reset'
# with Model, for site-preview.ps1 to show in the page's frame; and Notice, a preview notice to go above it, and Note
# for the preview's window.
function Invoke-PreviewAccount([string]$method, [string]$path, $query, $form) {
  Initialize-PreviewAccounts
  $p = $path.TrimEnd('/').ToLowerInvariant()
  $result = { param($h) [pscustomobject]@{ Location = $h.Location; Body = $h.Body; ContentType = $h.ContentType; Render = $h.Render; Model = $h.Model; Message = $h.Message; Notice = $h.Notice; Note = $h.Note } }
  $json = { param($value, $note) & $result @{ Body = ($value | ConvertTo-Json -Compress); ContentType = 'application/json; charset=utf-8'; Note = $note } }
  $field = { param($name) ([string]$form[$name]).Trim() }

  switch -regex ($p) {
    '^/account/login$' {
      $email = (& $field 'Email').ToLowerInvariant()
      $account = $script:previewAccounts[$email]
      if (-not $account -or $account.Password -ne [string]$form['Password']) {
        return & $result @{ Render = 'signin'; Model = (New-SignInModel (& $field 'Email') $null $null $false $false @('Either your email or password was wrong')); Note = 'account: wrong email or password' }
      }
      if (-not $account.Confirmed) {
        return & $result @{ Render = 'signin'; Model = (New-SignInModel (& $field 'Email') $null $null $false $false @("You haven't confirmed your email")); Note = 'account: not confirmed yet' }
      }
      $script:previewSignedIn = $email
      return & $result @{ Location = '/myaccount/index'; Note = "account: signed in as $email" }
    }
    '^/account/register$' {
      $email = & $field 'Email'
      $first = & $field 'FirstName'; $last = & $field 'LastName'
      $password = [string]$form['Password']
      # an approved trade applicant's "You're in!" form, or the ordinary one
      $trade = $script:previewTradeApplications[$email.ToLowerInvariant()]
      $tradeConfirm = [bool]($trade -and $trade.Approved)
      $errors = @()
      if (-not $email -or $email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { $errors += 'The Email field is not a valid e-mail address.' }
      if ($password.Length -lt 6) { $errors += 'The Password must be at least 6 characters long.' }
      if ($password -ne [string]$form['ConfirmPassword']) { $errors += 'The password and confirmation password do not match.' }
      if (-not $errors -and $script:previewAccounts.ContainsKey($email.ToLowerInvariant())) { $errors += "Name $email is already taken." }
      if ($errors) {
        return & $result @{ Render = 'signin'; Model = (New-SignInModel $email $first $last $true $tradeConfirm $errors); Note = 'account: registration sent back' }
      }
      $account = [pscustomobject]@{
        Id = [guid]::NewGuid().ToString(); Email = $email; FirstName = $first; LastName = $last; Password = $password; Confirmed = $false
        ConfirmCode = (New-PreviewCode); IsTrade = $tradeConfirm; IsSample = $false
        Address = [pscustomobject]@{ AddressId = 0; Address1 = ''; Address2 = ''; City = ''; County = ''; Postcode = '' }
      }
      $script:previewAccounts[$email.ToLowerInvariant()] = $account
      $link = '/account/confirmemail?userId=' + $account.Id + '&amp;code=' + $account.ConfirmCode
      return & $result @{ Render = 'message'; Message = 'Registered'; Note = "account: registered $email" + $(if ($tradeConfirm) { ' (trade)' } else { '' })
        Notice = (Format-PreviewEmailNotice ('the preview sends no email. The confirmation email''s link is <a href="' + $link + '">Confirm your account</a>.')) }
    }
    '^/account/confirmemail$' {
      $account = @($script:previewAccounts.Values | Where-Object { $_.Id -eq $query['userId'] -and $_.ConfirmCode -and $_.ConfirmCode -eq $query['code'] })[0]
      if (-not $account) { return $null }   # not one of the preview's links: the sample message
      $account.Confirmed = $true; $account.ConfirmCode = $null
      return & $result @{ Render = 'message'; Message = 'EmailConfirmed'; Note = "account: confirmed $($account.Email)" }
    }
    '^/account/traderegister$' {
      $email = & $field 'email'
      # TradeRegister quietly drops a phone number with a + or not starting with 0, and an unchosen payment type
      $dropped = (& $field 'phone') -match '\+' -or -not (& $field 'phone').StartsWith('0') -or (& $field 'paymentType') -eq 'Payment Type*'
      $notice = $null
      if (-not $dropped -and $email) {
        $script:previewTradeApplications[$email.ToLowerInvariant()] = [pscustomobject]@{ Email = $email; First = (& $field 'first'); Last = (& $field 'last'); Company = (& $field 'companyName'); Approved = $false }
        $notice = Format-PreviewEmailNotice ('nothing is sent. On the real site the team looks at the application and, once it''s approved, emails a link to set up the account. The preview''s approval email link: <a href="/account/login?tradeEmail=' + [Uri]::EscapeDataString($email) + '">approve and set up the trade account</a>.')
      }
      return & $result @{ Render = 'message'; Message = 'TradeApplicationSent'; Notice = $notice; Note = "account: trade application from $email" + $(if ($dropped) { ' (dropped, as the site drops it)' } else { '' }) }
    }
    '^/account/forgotpassword$' {
      $email = & $field 'Email'
      $account = $script:previewAccounts[$email.ToLowerInvariant()]
      if ($account -and $account.Confirmed) {
        $code = New-PreviewCode
        $script:previewResetCodes[$code] = $email.ToLowerInvariant()
        $script:previewLastLink = Format-PreviewEmailNotice ('the preview sends no email. The reset email''s link is <a href="/account/resetpassword?code=' + $code + '">choose a new password</a>.')
      } else {
        $script:previewLastLink = Format-PreviewEmailNotice 'there''s no confirmed account for that email in the preview, so the real site would send nothing, and says the same as for one that exists.'
      }
      return & $result @{ Location = '/account/forgotpasswordconfirmation'; Note = "account: password reset asked for $email" }
    }
    '^/account/resetpassword$' {
      $email = (& $field 'Email').ToLowerInvariant()
      $account = $script:previewAccounts[$email]
      if (-not $account) { return & $result @{ Location = '/account/resetpasswordconfirmation'; Note = 'account: reset for an unknown email (the site says it worked)' } }
      $errors = @()
      $password = [string]$form['Password']
      if ($password.Length -lt 6) { $errors += 'The Password must be at least 6 characters long.' }
      if ($password -ne [string]$form['ConfirmPassword']) { $errors += 'The password and confirmation password do not match.' }
      if (-not $errors -and $script:previewResetCodes[[string]$form['Code']] -ne $email) { $errors += 'Invalid token.' }
      if ($errors) { return & $result @{ Render = 'reset'; Model = [pscustomobject]@{ Email = $null; Code = [string]$form['Code']; Errors = $errors }; Note = 'account: reset sent back' } }
      $account.Password = $password
      $script:previewResetCodes.Remove([string]$form['Code'])
      return & $result @{ Location = '/account/resetpasswordconfirmation'; Note = "account: password changed for $email" }
    }
    '^/account/(logoff|logout)$' {
      $script:previewSignedIn = $null
      return & $result @{ Location = '/account/login'; Note = 'account: signed out' }
    }
    '^/myaccount/getuser$' {
      $account = Get-PreviewSignedIn
      $name = if ($account) { [string]$account.FirstName } else { '' }
      if ($name.Length -gt 8) { $name = $name.Substring(0, 7) + '...' }
      return & $json $name 'account: name for the header'
    }
    '^/product/istrade$' {
      $account = Get-PreviewSignedIn
      return & $json ([bool]($account -and $account.IsTrade)) 'account: trade?'
    }
    '^/myaccount/editaddress$' {
      $account = Get-PreviewSignedIn
      if (-not $account) { return & $result @{ Location = '/account/login?ReturnUrl=%2fmyaccount%2feditaddress'; Note = 'account: not signed in' } }
      $a = $account.Address
      foreach ($n in 'Address1', 'Address2', 'City', 'County', 'Postcode') { $a.$n = & $field "Address.$n" }
      if (-not $a.AddressId) { $a.AddressId = Get-Random -Minimum 5000 -Maximum 9999 }
      return & $result @{ Location = '/myaccount/Index'; Note = "account: address saved for $($account.Email)" }
    }
    '^/myaccount/requestreturn$' {
      $account = Get-PreviewSignedIn
      if (-not $account) { return & $result @{ Location = '/account/login?ReturnUrl=%2fmyaccount%2frequestreturn'; Note = 'account: not signed in' } }
      $page = Get-PreviewAccountPage $account
      $order = @($page.Orders | Where-Object { @($_.Lines | Where-Object { [string]$_.ItemId -eq [string]$form['OrderItemId'] }).Count })[0]
      if (-not $order) { return & $result @{ Location = '/myaccount/orders'; Note = 'account: not their item' } }
      $script:previewLastReturn = [pscustomobject]@{ OrderNumber = $order.Number; ItemId = $form['OrderItemId']; Reason = $form['Reason']; Resolution = $form['Resolution'] }
      return & $result @{ Location = '/myaccount/returnconfirmation'; Note = "account: return request for order $($order.Number) (would have been emailed)" }
    }
    '^/product/sendpricematchquery$' {
      return & $json '' ('email: price match message (not sent): ' + [string]$query['query'])
    }
    '^/product/newsletterregister$' {
      return & $json ([string]$query['email']) ('email: newsletter sign-up (not sent): ' + [string]$query['email'])
    }
    '^/basket/sendlooseenquiry$' {
      return & $result @{ Body = 'OK'; ContentType = 'text/html; charset=utf-8'; Note = 'email: bulk delivery enquiry (not sent) from ' + [string]$form['email-request'] }
    }
    '^/email/sendcalculatorcalculation$' {
      return & $result @{ Body = '[]'; ContentType = 'application/json; charset=utf-8'; Note = 'email: calculator estimate (not sent) to ' + [string]$form['email'] }
    }
  }
  $null
}
