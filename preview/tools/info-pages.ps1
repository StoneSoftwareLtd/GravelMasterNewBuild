# The new delivery and calculator pages (Views/Content/_DeliveryPage.cshtml and _CalculatorPage.cshtml) for the
# previews. Dot-sourced by site-preview.ps1 (localhost:8780/delivery and /calculator), after category-page.ps1 and
# calculator.ps1, whose Razor helpers, prices and calculator it uses.
#
#   Format-DeliveryPage       renders the delivery page (it has no data from the site: its checklist is in the
#                             partial's own C# block, which this reads)
#   Get-SampleCalculatorPage  the calculator page's model: the three gravels from the live site's data (data.json)
#   Format-CalculatorPage     renders the calculator page, with the shared calculator and bulk enquiry pop-up
#
# The markup comes from the .cshtml as it is, and the render fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

function Assert-NoRazorLeft([string]$name, [string]$h) {
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$|if\b)|(?:var|string|int) \w+ = )')
  if ($m.Success) { throw "$name still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
}

function Format-DeliveryPage([string]$templatePath) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $list = [regex]::Match($src, 'var checklist = new\[\]\s*\{([\s\S]*?)\};')
  $checklist = @([regex]::Matches($list.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
  if ($checklist.Count -eq 0) { throw "Couldn't read the checklist from _DeliveryPage.cshtml" }

  $start = $src.IndexOf('<div class="gm-info gm-delivery">')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-info gm-delivery""> in _DeliveryPage.cshtml" }
  $h = $src.Substring($start)
  $h = Set-RazorBlock $h '@foreach \(var item in checklist\)\s*\{' { param($b)
    ($checklist | ForEach-Object {
      if (-not $b.Inner.Contains('@item')) { throw "Couldn't find @item in _DeliveryPage.cshtml" }
      $b.Inner.Replace('@item', [Net.WebUtility]::HtmlEncode($_))
    }) -join ''
  }
  Assert-NoRazorLeft '_DeliveryPage' $h
  $h
}

$script:calculatorPageProducts = @('cotswold-chippings-20mm', 'panda-20mm', 'black-basalt-20mm')

function Get-SampleCalculatorPage {
  $data = Get-Content -Raw (Join-Path $PSScriptRoot 'data.json') -Encoding UTF8 | ConvertFrom-Json
  $products = @(foreach ($url in $script:calculatorPageProducts) {
    $tile = @($data.tiles | Where-Object { $_.url -eq $url })[0]
    if (-not $tile) { continue }   # as GetHomeProduct gives null for a product that's not on sale
    [pscustomobject]@{
      Name = $tile.name; Url = "/products/$($tile.category.ToLower())/p/$($tile.url.ToLower())"
      ImageFormat = [regex]::Replace($tile.image, '-\d+(\.\w+)$', '-{0}$1')
      Price = [decimal]$tile.price; TradePrice = [decimal]$tile.tradePrice
    }
  })
  [pscustomobject]@{ Products = $products }
}

# $enquiryHtml: the shared bulk enquiry pop-up, as build.ps1 renders it
function Format-CalculatorPage([string]$templatePath, $model, [string]$enquiryHtml) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $faqs = @([regex]::Matches($src, 'new \{ Question = "([^"]+)", Answer = "([^"]+)" \}') | ForEach-Object { [pscustomobject]@{ Question = $_.Groups[1].Value; Answer = $_.Groups[2].Value } })
  if ($faqs.Count -eq 0) { throw "Couldn't read the FAQs from _CalculatorPage.cshtml" }
  $products = @($model.Products)

  # Values go in as placeholders until the Razor check is done, so a partial's own text can't look like Razor
  $values = New-Object Collections.ArrayList
  function Put([string]$html) { [void]$values.Add($html); [string][char]2 + ($values.Count - 1) + [char]3 }
  function Enc([string]$s) { Put ([Net.WebUtility]::HtmlEncode($s)) }
  function Sub([string]$text, [hashtable]$map) {
    foreach ($key in ($map.Keys | Sort-Object Length -Descending)) {
      if (-not $text.Contains($key)) { throw "Couldn't find $key in _CalculatorPage.cshtml" }
      $text = $text.Replace($key, $map[$key])
    }
    $text
  }

  $start = $src.IndexOf('<div class="gm-info gm-calcpage">')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-info gm-calcpage""> in _CalculatorPage.cshtml" }
  $h = $src.Substring($start)

  $calculator = Format-QuantityCalculator (Join-Path (Split-Path (Split-Path $templatePath)) 'Shared\_QuantityCalculator.cshtml') $null
  $h = Sub $h @{ '@Html.Partial("_QuantityCalculator", Model.Calculator)' = (Put $calculator); '@Html.Partial("_BulkEnquiryModal", Model.EnquiryCategories)' = (Put $enquiryHtml) }

  $h = Set-RazorBlock $h '@if \(Model\.Products\.Count > 0\)\s*\{' { param($b)
    if ($products.Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@foreach \(var product in Model\.Products\)\s*\{' { param($lb)
      ($products | ForEach-Object {
        Sub $lb.Inner @{ '@product.Url' = (Enc $_.Url); '@product.ImageUrl(600)' = (Enc $_.ImageFormat.Replace('{0}', '600')); '@product.Name' = (Enc $_.Name)
          '@HomeProduct.FormatPrice(product.Price, true)' = (Put (Format-GbpPrice $_.Price $true)); '@HomeProduct.FormatPrice(product.TradePrice, true)' = (Put (Format-GbpPrice $_.TradePrice $true)) }
      }) -join ''
    }
  }
  $h = Set-RazorBlock $h '@for \(var i = 0; i < faqs\.Length; i\+\+\)\s*\{' { param($lb)
    $markup = Get-LoopMarkup $lb.Inner
    $out = for ($i = 0; $i -lt $faqs.Count; $i++) {
      Sub $markup @{ '@(i == 0 ? "open" : "")' = $(if ($i -eq 0) { 'open' } else { '' }); '@faq.Question' = (Enc $faqs[$i].Question); '@faq.Answer' = (Enc $faqs[$i].Answer) }
    }
    $out -join ''
  }
  Assert-NoRazorLeft '_CalculatorPage' $h
  [regex]::Replace($h, [string][char]2 + '(\d+)' + [char]3, { param($x) $values[[int]$x.Groups[1].Value] })
}
