# The new account pages (Views/Account/_SignInPage, _ForgotPasswordPage, _ResetPasswordPage and _AccountMessagePage)
# for the previews. Dot-sourced by site-preview.ps1, after category-page.ps1, whose Razor helpers it uses.
#
#   Get-SampleSignIn         what Account/Login.cshtml would pass the sign-in page, for a few sample states
#   Format-SignInPage        renders _SignInPage.cshtml
#   Format-AccountFormPage   renders _ForgotPasswordPage.cshtml or _ResetPasswordPage.cshtml
#   Format-AccountMessage    renders _AccountMessagePage.cshtml for one of its messages
#
# The markup comes from the .cshtml files as they are: each Razor block is found and filled in, and the render fails
# if any Razor is left over. @Html.AntiForgeryToken() becomes a stand-in hidden field (the preview blocks every post).
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

$script:antiForgeryStandIn = '<input name="__RequestVerificationToken" type="hidden" value="preview-stand-in" />'

# $flags: 'trade' (opened for a trade account), 'signinerror', 'registererror', 'tradeconfirm' (an approved trade customer)
function Get-SampleSignIn([string[]]$flags) {
  $m = [pscustomobject]@{ Email = $null; FirstName = $null; LastName = $null; IsTradeConfirm = $false; IsRegistration = $false; IsTradeRegistration = $false; Errors = @() }
  if ($flags -contains 'trade') { $m.IsTradeRegistration = $true }
  if ($flags -contains 'signinerror') { $m.Email = 'sample.customer@example.com'; $m.Errors = @('Either your email or password was wrong') }
  if ($flags -contains 'registererror') {
    # AccountController.Register sends the page back with IsRegistration and the names and email typed
    $m.IsRegistration = $true; $m.FirstName = 'Sam'; $m.LastName = 'Sample'; $m.Email = 'sample.customer@example.com'
    $m.Errors = @('Name sample.customer@example.com is already taken.')
  }
  if ($flags -contains 'tradeconfirm') { $m.IsTradeConfirm = $true; $m.FirstName = 'Sam'; $m.LastName = 'Sample'; $m.Email = 'sam@sample-landscapes.example.com' }
  $m
}

function Get-AccountPartial([string]$templatePath) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $start = $src.IndexOf('<div class="gm-account"')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-account""> in $templatePath" }
  $src.Substring($start)
}

function Test-NoRazorLeft([string]$h, [string]$name) {
  $h = $h.Replace('@@', '@')
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while|switch)\s*\(|else\s*(?:\{|$|if\b)|case\s+\w|default:|break;)')
  if ($m.Success) { throw "$name still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  $h
}

function Enc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }

# An "@if (<list>.Count > 0) { ... @foreach (var error in <list>) { <li>@error</li> } ... }" block
function Set-ErrorsBlock([string]$text, [string]$listName, [string[]]$errors) {
  Set-RazorBlock $text ('@if \(' + [regex]::Escape($listName) + '\.Count > 0\)\s*\{') { param($b)
    if (-not $errors -or $errors.Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner ('@foreach \(var error in ' + [regex]::Escape($listName) + '\)\s*\{') { param($lb)
      ($errors | ForEach-Object { $lb.Inner.Replace('@error', (Enc $_)) }) -join ''
    }
  }
}

function Format-SignInPage([string]$templatePath, $model) {
  $h = Get-AccountPartial $templatePath
  $trade = [bool]$model.IsTradeRegistration
  $errors = @($model.Errors)
  $signInErrors = if ($model.IsRegistration) { @() } else { $errors }
  $registerErrors = if ($model.IsRegistration) { $errors } else { @() }
  $signInEmail = if ($model.IsRegistration) { '' } else { $model.Email }
  $registerEmail = if ($model.IsRegistration) { $model.Email } else { '' }
  $focus = if ($registerErrors.Count -gt 0) { 'register-errors' } elseif ($signInErrors.Count -gt 0) { 'signin-errors' } elseif ($trade) { 'register' } else { '' }

  $h = Set-RazorBlock $h '@if \(Model\.IsTradeConfirm\)\s*\{' { param($b)
    if ($model.IsTradeConfirm) { Set-ErrorsBlock $b.Inner 'registerErrors' $registerErrors }
    else {
      $f = Set-ErrorsBlock $b.ElseInner 'signInErrors' $signInErrors
      Set-ErrorsBlock $f 'registerErrors' $registerErrors
    }
  }
  $h = $h.Replace('@Html.AntiForgeryToken()', $script:antiForgeryStandIn)
  $pairs = @(
    @('@focus', $focus), @('@Model.FirstName', (Enc $model.FirstName)), @('@Model.LastName', (Enc $model.LastName)),
    @('@Model.Email', (Enc $model.Email)), @('@signInEmail', (Enc $signInEmail)), @('@registerEmail', (Enc $registerEmail)),
    @('@(trade ? "" : "checked")', $(if ($trade) { '' } else { 'checked' })), @('@(trade ? "checked" : "")', $(if ($trade) { 'checked' } else { '' })),
    @('@(trade ? "hidden" : "")', $(if ($trade) { 'hidden' } else { '' })), @('@(trade ? "" : "hidden")', $(if ($trade) { '' } else { 'hidden' })))
  foreach ($p in $pairs) { $h = $h.Replace($p[0], $p[1]) }
  Test-NoRazorLeft $h '_SignInPage'
}

# $model: Email, Code, Errors
function Format-AccountFormPage([string]$templatePath, $model) {
  $h = Get-AccountPartial $templatePath
  $errors = @($model.Errors)
  $h = Set-ErrorsBlock $h 'Model.Errors' $errors
  $h = $h.Replace('@Html.AntiForgeryToken()', $script:antiForgeryStandIn)
  $h = $h.Replace('@(Model.Errors.Count > 0 ? "form-errors" : "")', $(if ($errors.Count -gt 0) { 'form-errors' } else { '' }))
  $h = $h.Replace('@Model.Email', (Enc $model.Email)).Replace('@Model.Code', (Enc $model.Code))
  Test-NoRazorLeft $h ([IO.Path]::GetFileName($templatePath))
}

# $message: one of AccountMessage's names (PasswordResetEmailSent, PasswordReset, EmailConfirmed, Registered, TradeApplicationSent)
function Format-AccountMessage([string]$templatePath, [string]$message) {
  $h = Get-AccountPartial $templatePath
  $email = $message -eq 'PasswordResetEmailSent' -or $message -eq 'Registered'
  $crumb = if ($message -eq 'TradeApplicationSent') { 'Trade account' } else { 'My account' }
  $h = $h.Replace('@crumb', $crumb)
  $h = Set-RazorBlock $h '@if \(email\)\s*\{' { param($b) if ($email) { $b.Inner } else { $b.ElseInner } }
  $h = Set-RazorBlock $h '@switch \(Model\)\s*\{' { param($b)
    # "case AccountMessage.X:" ... "break;" pieces, and "default:" ... "break;"
    $cases = [regex]::Matches($b.Inner, '(?s)(?:case AccountMessage\.(\w+)|(default)):(.*?)\bbreak;')
    if ($cases.Count -eq 0) { throw "Couldn't read the switch in _AccountMessagePage.cshtml" }
    $chosen = $null
    foreach ($c in $cases) { if ($c.Groups[1].Value -eq $message) { $chosen = $c.Groups[3].Value } }
    if ($chosen -eq $null) { foreach ($c in $cases) { if ($c.Groups[2].Value -eq 'default') { $chosen = $c.Groups[3].Value } } }
    $chosen
  }
  Test-NoRazorLeft $h '_AccountMessagePage'
}
