# The new checkout (Views/Checkout/_CheckoutPage.cshtml) for the previews. Dot-sourced by site-preview.ps1
# (localhost:8780/checkout/processorder), after basket-page.ps1, whose sample basket it uses.
#
#   Get-SampleCheckout   a sample checkout: the preview sends no cookies, so the live site has no basket to check out
#                        and would send the page back to /basket. The sample basket's lines, and sample delivery dates
#                        run through the real date rules (CheckoutDates.Build, compiled from CheckoutPageModels.cs)
#   Format-CheckoutPage  renders _CheckoutPage.cshtml with it
#
# The markup comes from the .cshtml as it is: each Razor block is found in the file and filled in, and the render
# fails if any Razor is left over. The address finders (Postcode Anywhere) aren't loaded in the preview: each is
# replaced by a copy of the search box it draws, so its restyling can be seen.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

if (-not ('Agilis.ECommerce.Mvc.Web.ViewModels.Common.CheckoutDates' -as [type])) {
  Add-Type -Path (Join-Path $PSScriptRoot '..\..\Website\Website\ViewModels\Common\CheckoutPageModels.cs') -ReferencedAssemblies System.Core
}

# $flags: 'samples' (Royal Mail), 'preorder' (only pre-order sizes), 'mixed' (a pre-order size with others),
# 'simple' (a cart the old page skipped the dates for), 'notimes' (no morning slot); $area: the basket's postcode area
function Get-SampleCheckout([string[]]$flags, [string]$area) {
  $basket = Get-SampleBasket @()
  $preOrder = (Get-Date).Date.AddDays(28 - [int](Get-Date).DayOfWeek + 1)   # the Monday about four weeks away
  $lines = @($basket.Lines | ForEach-Object {
    [pscustomobject]@{ NameHtml = $_.NameHtml; SizeHtml = $_.SizeHtml; ImageUrl = $_.ImageUrl; Quantity = $_.Quantity; LinePrice = [decimal]$_.LinePrice; PreOrderDate = $null }
  })
  if ($flags -contains 'preorder') { foreach ($l in $lines) { $l.PreOrderDate = $preOrder } }
  if ($flags -contains 'mixed') { $lines[0].PreOrderDate = $preOrder }
  $total = [decimal]0
  foreach ($l in $lines) { $total += $l.LinePrice }

  $delivery = if ($flags -contains 'samples') { 'RoyalMail' } elseif ($flags -contains 'preorder') { 'PreOrder' } elseif ($flags -contains 'simple') { 'NoChoice' } else { 'ChooseDate' }

  # Sample delivery days in the shape CheckoutController.BuildDeliveryDays makes them (55 days, no Sundays,
  # Saturdays 50, the next day 15); the real ones and their prices come from the site's settings
  $now = Get-Date
  $offset = if ($now.Hour -ge 11) { 2 } else { 1 }
  $days = New-Object 'System.Collections.Generic.List[System.Collections.Generic.KeyValuePair[datetime,decimal]]'
  while ($days.Count -lt 55) {
    $d = $now.AddDays($offset)
    if ($d.DayOfWeek -ne 'Sunday') {
      $cost = if ($d.DayOfWeek -eq 'Saturday') { [decimal]50 } elseif ($offset -eq 1 -or ($offset -eq 2 -and $now.Hour -ge 11)) { [decimal]15 } else { [decimal]0 }
      $days.Add((New-Object 'System.Collections.Generic.KeyValuePair[datetime,decimal]' $d, $cost))
    }
    $offset++
  }
  $specialAreas = 'GY', 'IM', 'JE', 'KW', 'SL', 'ZE', 'HS', 'PA', 'PH', 'PO', 'IV'   # OrderViewModel.SpecialAreas
  $rules = New-Object Agilis.ECommerce.Mvc.Web.ViewModels.Common.CheckoutDateRules
  $rules.PostalArea = $area
  $rules.IsBulk = $delivery -eq 'ChooseDate'    # the sample basket is bulk bags
  $rules.NextDayCost = 15
  $rules.EcoDayOfMonth = $now.AddDays(7).Day
  $rules.WeekendAllowed = $specialAreas -notcontains $area.ToUpperInvariant()
  $dates = [Agilis.ECommerce.Mvc.Web.ViewModels.Common.CheckoutDates]::Build($days, $rules, $now)
  $default = @($dates | Where-Object { $_.IsDefault })[0]
  $posted = if ($default -and $delivery -ne 'RoyalMail') { $default } else { $null }

  [pscustomobject]@{
    Lines = $lines; Total = $total
    Address = [pscustomobject]@{ Address1 = $null; Address2 = $null; City = $null; County = $null; Postcode = $null }
    IsLoggedIn = $false; PostalArea = $area; StrictPostalArea = $flags -notcontains 'simple'
    Delivery = $delivery
    Dates = $(if ($delivery -eq 'ChooseDate') { @($dates) } else { @() })
    PostedDay = $(if ($posted) { $posted.Value } else { $days[0].Key.ToString('dd-MM-yy', [Globalization.CultureInfo]::InvariantCulture) })
    PostedDate = $(if ($posted) { $posted.Day } else { $days[0].Key })
    ShowTimes = $flags -notcontains 'notimes'; MorningCost = [decimal]15
    IsMixedPreOrder = $flags -contains 'mixed'
    PreOrderDate = $(if ($flags -contains 'preorder' -or $flags -contains 'mixed') { $preOrder } else { $null })
    ShowTradeLink = $true
  }
}

function Format-CheckoutPage([string]$templatePath, $model) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $uk = [Globalization.CultureInfo]::GetCultureInfo('en-GB')
  $inv = [Globalization.CultureInfo]::InvariantCulture
  function Enc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
  function Money([decimal]$d) { Format-GbpPrice $d $true }
  function Sub([string]$text, [object[]]$pairs) {
    foreach ($pair in $pairs) {
      if (-not $text.Contains($pair[0])) { throw "Couldn't find $($pair[0]) in _CheckoutPage.cshtml" }
      $text = $text.Replace($pair[0], $pair[1])
    }
    $text
  }
  $ifShown = { param($shown, $b) if ($shown) { $b.Inner } elseif ($b.ElseInner -ne $null) { $b.ElseInner } else { '' } }

  # the same working-out as the partial's code block
  $chooseDate = $model.Delivery -eq 'ChooseDate'
  $firstDate = @($model.Dates | Where-Object { $_.IsDefault })[0]
  $preOrderWeek = if ($model.PreOrderDate) { ([datetime]$model.PreOrderDate).ToString('d MMMM', $uk) } else { '' }
  $kindOf = { param($d) if ($d.IsWeekend) { $d.Day.ToString('dddd', $uk) + ' delivery' } else { 'Weekday delivery' } }

  $start = $src.IndexOf('<div class="gm-checkout"')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-checkout""> in _CheckoutPage.cshtml" }
  $h = $src.Substring($start)

  $h = Set-RazorBlock $h '@if \(!Model\.IsLoggedIn\)\s*\{' { param($b) & $ifShown (-not $model.IsLoggedIn) $b }

  # the form's delivery part
  $h = Set-RazorBlock $h '@if \(chooseDate\)\s*\{' { param($b)
    if ($chooseDate) {
      $f = Set-RazorBlock $b.Inner '@if \(Model\.IsMixedPreOrder\)\s*\{' { param($ib) & $ifShown $model.IsMixedPreOrder $ib }
      $f = Set-RazorBlock $f '@foreach \(var date in Model\.Dates\)\s*\{' { param($lb)
        ($model.Dates | ForEach-Object {
          $d = $_
          $o = Set-RazorBlock $lb.Inner '@if \(date\.IsEco\)\s*\{' { param($ib) & $ifShown $d.IsEco $ib }
          Sub $o @(
            @('@(date.Available ? "" : " hidden")', $(if ($d.Available) { '' } else { ' hidden' })),
            @('@date.Value', $d.Value), @('@date.Cost.ToString("0.00", inv)', $d.Cost.ToString('0.00', $inv)),
            @('@(date.IsWeekend ? date.Day.ToString("dddd", uk) + " delivery" : "Weekday delivery")', (& $kindOf $d)),
            @('@date.Day.ToString("dddd d MMMM", uk)', $d.Day.ToString('dddd d MMMM', $uk)),
            @('@(date.IsDefault ? " checked" : "")', $(if ($d.IsDefault) { ' checked' } else { '' })),
            @('@(!date.Available ? " disabled data-unavailable" : date.Cost > 0 ? " disabled data-paid" : "")', $(if (-not $d.Available) { ' disabled data-unavailable' } elseif ($d.Cost -gt 0) { ' disabled data-paid' } else { '' })),
            @('@date.Day.ToString("ddd", uk)', $d.Day.ToString('ddd', $uk)), @('@date.Day.ToString("d MMM", uk)', $d.Day.ToString('d MMM', $uk)),
            @('@(date.Cost > 0 ? " chk-date__price--paid" : "")', $(if ($d.Cost -gt 0) { ' chk-date__price--paid' } else { '' })),
            @('@(date.Cost > 0 ? HomeProduct.FormatPrice(date.Cost, true) : "Free")', $(if ($d.Cost -gt 0) { Money $d.Cost } else { 'Free' })))
        }) -join ''
      }
      $f = Set-RazorBlock $f '@if \(Model\.ShowTimes\)\s*\{' { param($ib)
        if (-not $model.ShowTimes) { return $ib.ElseInner }
        $paid = $model.MorningCost -gt 0
        Sub $ib.Inner @(
          @('@Model.MorningCost.ToString("0.00", inv)', $model.MorningCost.ToString('0.00', $inv)),
          @('@(Model.MorningCost > 0 ? " disabled data-paid" : "")', $(if ($paid) { ' disabled data-paid' } else { '' })),
          @('@(Model.MorningCost > 0 ? " chk-time__price--paid" : "")', $(if ($paid) { ' chk-time__price--paid' } else { '' })),
          @('@(Model.MorningCost > 0 ? HomeProduct.FormatPrice(Model.MorningCost, true) : "Free")', $(if ($paid) { Money $model.MorningCost } else { 'Free' })))
      }
      Sub $f @(, @('@(Model.ShowTimes ? "Choose your delivery date and time" : "Choose your delivery date")', $(if ($model.ShowTimes) { 'Choose your delivery date and time' } else { 'Choose your delivery date' })))
    } else {
      $f = Set-RazorBlock $b.ElseInner 'if \(Model\.Delivery == CheckoutDelivery\.RoyalMail \|\| Model\.Delivery == CheckoutDelivery\.PreOrder\)\s*\{' { param($ib)
        if ($model.Delivery -ne 'RoyalMail' -and $model.Delivery -ne 'PreOrder') { return '' }
        Set-RazorBlock $ib.Inner '@if \(Model\.Delivery == CheckoutDelivery\.RoyalMail\)\s*\{' { param($rb)
          if ($model.Delivery -eq 'RoyalMail') { $rb.Inner } else { Sub $rb.ElseInner @(, @('@preOrderWeek', $preOrderWeek)) }
        }
      }
      Sub $f @(, @('@Model.PostedDay', (Enc $model.PostedDay)))
    }
  }

  # the order summary's lines
  $h = Set-RazorBlock $h '@foreach \(var line in Model\.Lines\)\s*\{' { param($lb)
    ($model.Lines | ForEach-Object {
      $line = $_
      $o = Set-RazorBlock $lb.Inner '@if \(line\.PreOrderDate\.HasValue\)\s*\{' { param($ib)
        if ($line.PreOrderDate) { Sub $ib.Inner @(, @('@line.PreOrderDate.Value.ToString("d MMM", uk)', ([datetime]$line.PreOrderDate).ToString('d MMM', $uk))) } else { '' }
      }
      Sub $o @(
        @('@line.ImageUrl', (Enc $line.ImageUrl)), @('@Html.Raw(line.NameHtml)', $line.NameHtml), @('@Html.Raw(line.SizeHtml)', $line.SizeHtml),
        @('@line.Quantity', [string]$line.Quantity), @('@HomeProduct.FormatPrice(line.LinePrice, true)', (Money $line.LinePrice)))
    }) -join ''
  }

  # the order summary's delivery lines
  $h = Set-RazorBlock $h '@if \(chooseDate\)\s*\{' { param($b)
    if ($chooseDate) {
      $f = Set-RazorBlock $b.Inner 'if \(Model\.ShowTimes\)\s*\{' { param($ib) & $ifShown $model.ShowTimes $ib }
      Sub $f @(
        @('@(firstDate != null && firstDate.IsWeekend ? firstDate.Day.ToString("dddd", uk) + " delivery" : "Weekday delivery")', $(if ($firstDate) { & $kindOf $firstDate } else { 'Weekday delivery' })),
        @('@(firstDate != null ? "Delivery on " + firstDate.Day.ToString("dddd d MMMM", uk) : "Choose a delivery date")', $(if ($firstDate) { 'Delivery on ' + $firstDate.Day.ToString('dddd d MMMM', $uk) } else { 'Choose a delivery date' })),
        @('@HomeProduct.FormatPrice(firstDate != null ? firstDate.Cost : 0m, true)', (Money $(if ($firstDate) { $firstDate.Cost } else { 0 }))))
    } else {
      # @if (RoyalMail) { } else if (PreOrder) { } else { }
      $f = $b.ElseInner
      $royal = Find-RazorBlock $f '@if \(Model\.Delivery == CheckoutDelivery\.RoyalMail\)\s*\{'
      $pre = Find-RazorBlock $f 'else if \(Model\.Delivery == CheckoutDelivery\.PreOrder\)\s*\{'
      if ($f.Substring($royal.End, $pre.Start - $royal.End).Trim()) { throw 'Unexpected text between the summary''s if and else if' }
      $chosen = if ($model.Delivery -eq 'RoyalMail') { $royal.Inner } elseif ($model.Delivery -eq 'PreOrder') { Sub $pre.Inner @(, @('@preOrderWeek', $preOrderWeek)) } else {
        Set-RazorBlock $pre.ElseInner 'if \(Model\.PostedDate\.HasValue\)\s*\{' { param($ib)
          if ($model.PostedDate) { Sub $ib.Inner @(, @('@Model.PostedDate.Value.ToString("dddd d MMMM", uk)', ([datetime]$model.PostedDate).ToString('dddd d MMMM', $uk))) } else { '' }
        }
      }
      $f.Substring(0, $royal.Start) + $chosen + $f.Substring($pre.End)
    }
  }

  $h = Set-RazorBlock $h '@if \(Model\.ShowTradeLink\)\s*\{' { param($b) & $ifShown $model.ShowTradeLink $b }

  $h = $h.Replace('@HomeProduct.FormatPrice(0m, true)', (Money 0))
  $h = Sub $h @(
    @('@Model.Total.ToString("0.00", inv)', ([decimal]$model.Total).ToString('0.00', $inv)),
    @('@Model.PostalArea', (Enc $model.PostalArea)),
    @('@(Model.StrictPostalArea ? "true" : "false")', $(if ($model.StrictPostalArea) { 'true' } else { 'false' })),
    @('@HomeProduct.FormatPrice(Model.Total, true)', (Money $model.Total)),
    @('@Model.Address.Address1', (Enc $model.Address.Address1)), @('@Model.Address.Address2', (Enc $model.Address.Address2)),
    @('@Model.Address.City', (Enc $model.Address.City)), @('@Model.Address.County', (Enc $model.Address.County)),
    @('@Model.Address.Postcode', (Enc $model.Address.Postcode)))
  $h = $h.Replace('@@', '@')
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$|if\b))')
  if ($m.Success) { throw "_CheckoutPage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }

  # The address finders aren't loaded in the preview (typing would use the site's Postcode Anywhere account): each
  # becomes a copy of the search box the finder draws (captureplus-1.30.js), with a note
  $h = [regex]::Replace($h, '<script type="text/javascript" src="https://services\.postcodeanywhere\.co\.uk/[^"]*"></script>', '')
  foreach ($uid in 'hm12dh93hc52bz763659', 'bg99nd82ge98kr993695') {
    $mock = '<div id="' + $uid + '"><div class="pcaAutoComplete"><div class="inputArea"><div class="suggestion" style="margin: 0px; padding: 0px;"><span class="invisible" style="margin: 0px; padding: 0px;"></span><span style="max-width: 95%; margin: 0px; padding: 0px; color: #BCBCBC;"></span></div>' +
      '<input id="pcainput_' + $uid + '" type="text" class="search" autocomplete="off" autocorrect="off" style="margin: 0px; padding: 0px;" /></div></div></div>' +
      '<p style="margin:6px 0 0;font-size:13px;color:#6a4b00">Preview: the address finder only works on the real site. Type the address into the boxes below.</p>'
    $h = Sub $h @(, @(('<div id="' + $uid + '"></div>'), $mock))
  }
  $h
}
