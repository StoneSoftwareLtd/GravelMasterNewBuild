# The new order confirmation (Views/Checkout/_ConfirmationPage.cshtml) for the previews. Dot-sourced by site-preview.ps1
# (localhost:8780/checkout/orderresult), after basket-page.ps1, whose Get-LiveProductModel it uses.
#
#   Get-SampleConfirmation   a sample order: the real page only exists after a payment, and loading it on the live site
#                            isn't only a page view (it marks the order as paid), so the preview never asks for it.
#                            The suggestions are the real products at their live prices, read from their product pages
#   Format-ConfirmationPage  renders _ConfirmationPage.cshtml with it
#
# The markup comes from the .cshtml as it is: each Razor block is found in the file and filled in, and the render
# fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

$script:confirmationPicks = $null

function Get-SampleConfirmation {
  if (-not $script:confirmationPicks) {
    # the same four products, names and sizes as the merge code in docs/merging.md
    $script:confirmationPicks = @(
      @('/products/accessories/p/bird-feeder', 'FeatherSnap Bird Feeder', 'Feathsnap'),
      @('/products/accessories/p/large-galvanised', 'Large Galvanised Stainless Steel Planter', 'RSDBED'),
      @('/products/accessories/p/trowel', 'Trowel', 'TROWEL1'),
      @('/products/accessories/p/gardening-gloves', 'Gardening Gloves', 'GDNGLOVE')
    ) | ForEach-Object {
      $pick = $_
      $model = Get-LiveProductModel $pick[0]
      $option = @($model.Options | Where-Object { $_.Code -eq $pick[2] })[0]
      if ($option) {
        [pscustomobject]@{ Name = $pick[1]; Url = $pick[0]; ImageUrl = $model.Photos[0].ThumbUrl; Price = [decimal]$option.Price; PriceUnit = $null; ProductCode = $model.Code; VariantCode = $option.Code }
      }
    }
  }
  [pscustomobject]@{
    OrderNumber = '123456'; AmountPaid = [decimal]260.50; Email = 'sample.customer@example.com'
    DeliveryAddress = '1 Sample Street, Nottingham, NG7 2RD'; DeliveryPostcode = 'NG7 2RD'; PostalArea = 'NG'
    Suggestions = @($script:confirmationPicks)
  }
}

function Format-ConfirmationPage([string]$templatePath, $model) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  function Enc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
  function Money([decimal]$d) { Format-GbpPrice $d $true }
  function Sub([string]$text, [object[]]$pairs) {
    foreach ($pair in $pairs) {
      if (-not $text.Contains($pair[0])) { throw "Couldn't find $($pair[0]) in _ConfirmationPage.cshtml" }
      $text = $text.Replace($pair[0], $pair[1])
    }
    $text
  }
  $suggestions = @($model.Suggestions)

  $start = $src.IndexOf('<div class="gm-confirm"')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-confirm""> in _ConfirmationPage.cshtml" }
  $h = $src.Substring($start)

  $h = Set-RazorBlock $h '@if \(!string\.IsNullOrWhiteSpace\(Model\.DeliveryAddress\)\)\s*\{' { param($b)
    if ($model.DeliveryAddress) { Sub $b.Inner @(, @('@Model.DeliveryAddress', (Enc $model.DeliveryAddress))) } else { '' }
  }
  $h = Set-RazorBlock $h '@if \(!string\.IsNullOrWhiteSpace\(Model\.Email\)\)\s*\{' { param($b)
    if ($model.Email) { Sub $b.Inner @(, @('@Html.Raw(Html.Encode(Model.Email).Replace("@", "@<wbr>"))', (Enc $model.Email).Replace('@', '@<wbr>'))) } else { '' }
  }
  $h = Set-RazorBlock $h '@if \(Model\.Suggestions\.Count > 0\)\s*\{' { param($b)
    if ($suggestions.Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@foreach \(var product in Model\.Suggestions\)\s*\{' { param($lb)
      ($suggestions | ForEach-Object {
        Sub $lb.Inner @(
          @('@HomeProduct.FormatPrice(product.Price, true)@(product.PriceUnit != null ? " " + product.PriceUnit : "")', ((Money $_.Price) + $(if ($_.PriceUnit) { ' ' + (Enc $_.PriceUnit) } else { '' }))),
          @('@product.ImageUrl', (Enc $_.ImageUrl)), @('@product.Url', (Enc $_.Url)), @('@product.Name', (Enc $_.Name)),
          @('@product.ProductCode', (Enc $_.ProductCode)), @('@product.VariantCode', (Enc $_.VariantCode)))
      }) -join ''
    }
  }
  $h = $h.Replace('@Model.OrderNumber', (Enc $model.OrderNumber))
  $h = Sub $h @(
    @('@Model.PostalArea', (Enc $model.PostalArea)),
    @('@HomeProduct.FormatPrice(Model.AmountPaid, true)', (Money $model.AmountPaid)),
    @('@Model.DeliveryPostcode', (Enc $model.DeliveryPostcode)))
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$|if\b))')
  if ($m.Success) { throw "_ConfirmationPage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  $h
}
