# The new basket page (Views/Basket/_BasketPage.cshtml) for the previews. Dot-sourced by site-preview.ps1
# (localhost:8780/basket), after category-page.ps1 and product-page.ps1, whose helpers it uses.
#
#   Get-SampleBasket   a sample basket: the preview sends no cookies, so the live site's basket is always empty.
#                      Real products, sizes, photos and prices, read from their live product pages
#   Format-BasketPage  renders _BasketPage.cshtml with a basket
#
# The markup comes from the .cshtml as it is: each Razor block is found in the file and filled in, and the render
# fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

$script:sampleBasketProducts = $null

# A product's model, read from its live product page (cached for the preview's run)
function Get-LiveProductModel([string]$path) {
  $req = [Net.HttpWebRequest]::Create('https://www.gravelmaster.co.uk' + $path)
  $req.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) GravelMasterHeaderPreview'
  $req.AutomaticDecompression = [Net.DecompressionMethods]'GZip, Deflate'
  $res = $req.GetResponse()
  try { $html = (New-Object IO.StreamReader($res.GetResponseStream(), [Text.Encoding]::UTF8)).ReadToEnd() } finally { $res.Close() }
  $mb = [regex]::Match($html, '<div itemscope itemtype="http://schema.org/WebSite" id="mainBody"[^>]*>')
  $modal = $html.IndexOf('<div class="modal fade show" id="priceModal"')
  if (-not $mb.Success -or $modal -lt 0) { throw "Couldn't read $path" }
  $model = ConvertFrom-OldProductPage $html.Substring($mb.Index, $html.LastIndexOf('</div>', $modal) - $mb.Index) $path
  $model | Add-Member -NotePropertyName PagePath -NotePropertyValue $path -PassThru
}

# $flags: 'empty' (no lines), 'voucher' (a voucher message), 'discount' (10% off, to show the discount rows), 'stock'
# (a line of each stock state: the planter, a real pre-order size, and the pegs marked sold out as a sample, since the
# preview can't see a size's stock)
function Get-SampleBasket([string[]]$flags) {
  if (-not $script:sampleBasketProducts) {
    $script:sampleBasketProducts = @{
      Cotswold = Get-LiveProductModel '/products/garden-chippings/p/cotswold-chippings-20mm'
      Turf = Get-LiveProductModel '/products/turf-and-seed/p/pro-hard-wearing-turf'
      Bag = Get-LiveProductModel '/products/accessories/p/empty-bags'
      Membrane1 = Get-LiveProductModel '/products/weed-control-membrane/p/weed-membrane-1m-width'
      Membrane2 = Get-LiveProductModel '/products/weed-control-membrane/p/weed-membrane-2m-width'
      Pegs = Get-LiveProductModel '/products/weed-control-membrane/p/plastic-pegs'
    }
  }
  $p = $script:sampleBasketProducts
  if ($flags -contains 'stock' -and -not $p.Planter) { $p.Planter = Get-LiveProductModel '/products/accessories/p/large-galvanised' }
  # $size is the size's name or code
  function Line($model, [string]$size, [int]$qty, [bool]$canChange) {
    $option = @($model.Options | Where-Object { $_.Name -eq $size -or $_.Code -eq $size })[0]
    if (-not $option) { throw "No size '$size' on $($model.Name)" }
    [pscustomobject]@{
      Id = [guid]::NewGuid().ToString(); NameHtml = [Net.WebUtility]::HtmlEncode($model.Name); Url = $model.PagePath
      ImageUrl = $model.Photos[0].ThumbUrl; SizeHtml = [Net.WebUtility]::HtmlEncode($option.Name)
      UnitPrice = [decimal]$option.Price; Quantity = $qty; CanChangeQuantity = $canChange
      Discount = [decimal]0; LinePrice = [decimal]$option.Price * $qty; PreOrderDate = $option.PreOrderDate; IsOutOfStock = $false
    }
  }
  function Suggestion($model, [string]$sizeName, [string]$name, [string]$unit) {
    $option = @($model.Options | Where-Object { $_.Name -eq $sizeName })[0]
    [pscustomobject]@{ Name = $name; Url = $model.PagePath; ImageUrl = $model.Photos[0].ThumbUrl; Price = [decimal]$option.Price; PriceUnit = $unit; ProductCode = $model.Code; VariantCode = $option.Code }
  }

  $lines = @()
  if ($flags -notcontains 'empty') {
    $lines = @(
      (Line $p.Cotswold 'Approx 850Kg Bulk Bag' 2 $true),
      (Line $p.Turf 'm2 Rolls' 10 $false),
      (Line $p.Pegs '10 Plastic Pegs' 1 $true)
    )
    if ($flags -contains 'stock') {
      $lines[2].IsOutOfStock = $true
      $lines = @($lines[0], (Line $p.Planter 'RSDBED' 1 $true)) + @($lines[1], $lines[2])
    }
  }
  if ($flags -contains 'discount') {
    foreach ($l in $lines) { $l.Discount = [Math]::Round($l.LinePrice * 0.1, 2); $l.LinePrice -= $l.Discount }
  }
  $subTotal = [decimal]0; $total = [decimal]0; $count = 0
  foreach ($l in $lines) { $subTotal += $l.LinePrice + $l.Discount; $total += $l.LinePrice; $count += $l.Quantity }
  [pscustomobject]@{
    Lines = $lines; ItemCount = $count; SubTotal = $subTotal; Total = $total; Discount = [Math]::Max([decimal]0, $subTotal - $total)
    ShowVoucher = $true
    VoucherMessage = $(if ($flags -contains 'voucher') { 'Invalid coupon code' } else { $null })
    PostalArea = 'NG'
    # the old page's four "weekly special offers", with its names and sizes
    Suggestions = @(
      # the Empty Waste Bags product has no photos on the image server, so the old page's own picture
      ((Suggestion $p.Bag 'Empty Waste Bag' 'Empty Waste Bag' $null) | ForEach-Object { $_.ImageUrl = '/img/800.png'; $_ }),
      (Suggestion $p.Membrane1 '1m x 15m Membrane' '1m x 15m Weed Membrane' 'per roll'),
      (Suggestion $p.Membrane2 '2m x 10m Membrane' '2m x 10m Weed Membrane' 'per roll'),
      (Suggestion $p.Pegs '10 Plastic Pegs' '10 Plastic Fixing Pegs' 'per set')
    )
  }
}

function Format-BasketPage([string]$templatePath, $model) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $uk = [Globalization.CultureInfo]::GetCultureInfo('en-GB')
  function Enc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
  function Money([decimal]$d) { Format-GbpPrice $d $true }
  function Sub([string]$text, [object[]]$pairs) {
    foreach ($pair in $pairs) {
      if (-not $text.Contains($pair[0])) { throw "Couldn't find $($pair[0]) in _BasketPage.cshtml" }
      $text = $text.Replace($pair[0], $pair[1])
    }
    $text
  }
  $ifShown = { param($shown, $b) if ($shown) { $b.Inner } elseif ($b.ElseInner -ne $null) { $b.ElseInner } else { '' } }

  $count = [int]$model.ItemCount
  $itemsText = if ($count -eq 1) { '1 item' } else { "$count items" }
  $voucherOpen = -not [string]::IsNullOrWhiteSpace($model.VoucherMessage)
  $lines = @($model.Lines)
  $suggestions = @($model.Suggestions)

  $start = $src.IndexOf('<div class="gm-basket"')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-basket""> in _BasketPage.cshtml" }
  $h = $src.Substring($start)

  $h = Set-RazorBlock $h '@if \(Model\.Lines\.Count == 0\)\s*\{' { param($b)
    if ($lines.Count -eq 0) { return $b.Inner }
    $f = $b.ElseInner
    $f = Set-RazorBlock $f '@for \(var i = 0; i < Model\.Lines\.Count; i\+\+\)\s*\{' { param($lb)
      $markup = Get-LoopMarkup $lb.Inner
      $out = for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        # the stock: "@if (line.IsOutOfStock) { } else if (line.PreOrderDate.HasValue) { } else { }"
        $out1 = Find-RazorBlock $markup '@if \(line\.IsOutOfStock\)\s*\{'
        $rest = $markup.Substring($out1.End)
        $pre = Find-RazorBlock $rest '^\s*else if \(line\.PreOrderDate\.HasValue\)\s*\{'
        if ($null -eq $pre.ElseInner) { throw "Couldn't find the in-stock else block in _BasketPage.cshtml" }
        $stock = if ($line.IsOutOfStock) { $out1.Inner }
          elseif ($line.PreOrderDate) { Sub $pre.Inner @(, @('@line.PreOrderDate.Value.ToString("d MMM", uk)', ([datetime]$line.PreOrderDate).ToString('d MMM', $uk))) }
          else { $pre.ElseInner }
        $o = $markup.Substring(0, $out1.Start) + $stock + $rest.Substring($pre.End)
        $o = Set-RazorBlock $o '@if \(line\.CanChangeQuantity\)\s*\{' { param($ib) & $ifShown $line.CanChangeQuantity $ib }
        $o = Set-RazorBlock $o '@if \(line\.Discount > 0\)\s*\{' { param($ib)
          if ($line.Discount -gt 0) { Sub $ib.Inner @(, @('@HomeProduct.FormatPrice(line.Discount, true)', (Money $line.Discount))) } else { '' }
        }
        $o = Sub $o @(
          @('@line.ImageUrl', (Enc $line.ImageUrl)), @('@line.Url', (Enc $line.Url)), @('@Html.Raw(line.NameHtml)', $line.NameHtml),
          @('@HomeProduct.FormatPrice(line.UnitPrice, true)', (Money $line.UnitPrice)), @('@Html.Raw(line.SizeHtml)', $line.SizeHtml),
          @('@HomeProduct.FormatPrice(line.LinePrice, true)', (Money $line.LinePrice)), @('@line.Quantity', [string]$line.Quantity),
          @('@line.Id', (Enc $line.Id)))
        $o.Replace('@i', [string]$i)
      }
      $out -join ''
    }
    $f = Set-RazorBlock $f '@if \(Model\.Discount > 0\)\s*\{' { param($ib)
      if ($model.Discount -gt 0) { Sub $ib.Inner @(, @('@HomeProduct.FormatPrice(Model.Discount, true)', (Money $model.Discount))) } else { '' }
    }
    $f = Set-RazorBlock $f '@if \(Model\.ShowVoucher\)\s*\{' { param($ib)
      if (-not $model.ShowVoucher) { return '' }
      $v = Set-RazorBlock $ib.Inner '@if \(voucherOpen\)\s*\{' { param($vb) if ($voucherOpen) { Sub $vb.Inner @(, @('@Model.VoucherMessage', (Enc $model.VoucherMessage))) } else { '' } }
      Sub $v @(@('@(voucherOpen ? " is-open" : "")', $(if ($voucherOpen) { ' is-open' } else { '' })), @('@(voucherOpen ? "true" : "false")', $(if ($voucherOpen) { 'true' } else { 'false' })))
    }
    Sub $f @(@('@HomeProduct.FormatPrice(Model.SubTotal, true)', (Money $model.SubTotal)), @('@HomeProduct.FormatPrice(Model.Total, true)', (Money $model.Total)))
  }

  $h = Set-RazorBlock $h '@if \(Model\.Lines\.Count > 0 && Model\.Suggestions\.Count > 0\)\s*\{' { param($b)
    if ($lines.Count -eq 0 -or $suggestions.Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@foreach \(var product in Model\.Suggestions\)\s*\{' { param($lb)
      ($suggestions | ForEach-Object {
        Sub $lb.Inner @(
          @('@HomeProduct.FormatPrice(product.Price, true)@(product.PriceUnit != null ? " " + product.PriceUnit : "")', ((Money $_.Price) + $(if ($_.PriceUnit) { ' ' + (Enc $_.PriceUnit) } else { '' }))),
          @('@product.ImageUrl', (Enc $_.ImageUrl)), @('@product.Url', (Enc $_.Url)), @('@product.Name', (Enc $_.Name)),
          @('@product.ProductCode', (Enc $_.ProductCode)), @('@product.VariantCode', (Enc $_.VariantCode)))
      }) -join ''
    }
  }

  if ($lines.Count -gt 0) { $h = Sub $h @(, @('@itemsText', $itemsText)) }   # only the full basket shows the count
  $h = Sub $h @(, @('@Model.PostalArea', (Enc $model.PostalArea)))
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$))')
  if ($m.Success) { throw "_BasketPage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  $h
}
