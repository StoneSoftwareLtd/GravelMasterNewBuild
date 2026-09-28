# The preview's working basket. Dot-sourced by site-preview.ps1, after basket-page.ps1, whose product reader it uses.
#
# No cookies reach the live site, so it never has a basket for the preview. The preview keeps one itself instead, in
# memory while it runs (one basket for whoever is using the preview), and answers the basket's addresses the way
# BasketController does, so the new pages' own scripts work unchanged:
#   /basket/addtobasket          adds a size (the product page's Add to cart, a suggestion's or add-on's Add) and answers
#                                with the "added to your basket" summary, in AddToCartComponent.cshtml's markup
#   /basket/updatequantity       "basket total:line total"
#   /basket/getbasketsummary     "N Items: GBP X|"
#   /basket/getselectedpostcode  the basket's postcode area
#   /basket/updatebasket         the basket page's quantities, then back to /basket
#   /basket/removefrombasket     removes a line
#   /basket/applycouponcode      a voucher: PREVIEW10 is a sample 10% voucher; any other code is invalid, as the live
#                                site's vouchers can't be read
#   /checkout/processorder, sent "Continue to payment": checks the delivery postcode as CheckoutController.ProcessOrder
#                                does, then goes to the payment error page: payment isn't set up in the preview
# Prices come from the live site's own price lookup (/product/calculateprices), which only reads prices, for the
# postcode area each size was added with, as on the product page. Products are read from their live pages. Nothing is
# sent to the live site's basket or checkout.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

Add-Type -AssemblyName System.Web

$script:previewBasket = [pscustomobject]@{
  Lines = New-Object System.Collections.ArrayList
  Area = $null              # Session["PA"]: the postcode area the basket is priced for
  Coupon = $null            # the voucher applied
  CouponMessage = $null     # Cart.CouponMessage, shown after a voucher attempt
}
$script:basketProductPaths = @{}   # product code (in capitals) -> its product page
$script:basketProductModels = @{}  # product page -> what it sells, read from the live page
$script:livePrices = @{}           # "productId|size|area|quantity" -> the live price lookup's answer
$script:gbp = [Globalization.CultureInfo]::GetCultureInfo('en-GB')

# The sample voucher: the live site's vouchers are in its database, which the preview can't read
$script:sampleCoupon = [pscustomobject]@{ Code = 'PREVIEW10'; Description = '10% off everything (a sample voucher in the preview)'; Rate = [decimal]0.10 }

# The add-ons the "added to your basket" summary offers: AddToCartComponent.cshtml has these three written in, with
# their names, prices, photos and codes
$script:summaryAddOns = @(
  [pscustomobject]@{ Title = 'FeatherSnap Bird Feeder'; Name = 'FeatherSnap Bird Feeder'; Image = 'https://www.gravelmaster.co.uk/cdn/Feathsnapparent-330.jpg'; Price = [decimal]149.99; Code = 'Feathsnapparent'; Variant = 'Feathsnap'; Page = 'bird-feeder' },
  [pscustomobject]@{ Title = 'Weed Control Membrane 1m x 15m'; Name = 'Weed Membrane 1m x 15m'; Image = 'https://www.gravelmaster.co.uk/cdn/WM1M-600.jpg'; Price = [decimal]21.00; Code = 'WM1M'; Variant = 'WM1M-15'; Page = 'weed-membrane-1m-width' },
  [pscustomobject]@{ Title = 'Weed Control Membrane 2m x 10m'; Name = 'Weed Membrane 2m x 10m'; Image = 'https://www.gravelmaster.co.uk/cdn/WM1M-600.jpg'; Price = [decimal]23.00; Code = 'WM2M'; Variant = 'WM2M-10'; Page = 'weed-membrane-2m-width' }
)

function Format-Pounds([decimal]$d) { $d.ToString('C', $script:gbp) }   # ToString("c") on the site

# Where each product's page is, for the adds that only send its code (suggestions and add-ons)
function Register-BasketProduct([string]$code, [string]$path) {
  if ($code -and $path) { $script:basketProductPaths[$code.ToUpperInvariant()] = $path }
}
$script:knownBasketProductsRead = $false
function Register-KnownBasketProducts {
  if ($script:knownBasketProductsRead) { return }
  $script:knownBasketProductsRead = $true
  $data = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'data.json')) | ConvertFrom-Json
  foreach ($a in $script:summaryAddOns) {
    $p = @($data.products | Where-Object { $_.url -eq $a.Page })[0]
    if ($p) { Register-BasketProduct $a.Code "/products/$($p.category)/p/$($p.url)" }
  }
  foreach ($s in @((Get-SampleBasket @('empty')).Suggestions)) { Register-BasketProduct $s.ProductCode $s.Url }
  foreach ($s in @((Get-SampleConfirmation).Suggestions)) { Register-BasketProduct $s.ProductCode $s.Url }
}

function Get-BasketProductModel([string]$path) {
  $key = $path.TrimEnd('/').ToLowerInvariant()
  if (-not $script:basketProductModels.ContainsKey($key)) { $script:basketProductModels[$key] = Get-LiveProductModel $key }
  $script:basketProductModels[$key]
}

# The live site's price for a size, in a postcode area (or none), for a quantity: what the product page shows
function Get-LiveBasketPrice([string]$productId, [int]$sizeId, [string]$area, [int]$quantity) {
  $key = "$productId|$sizeId|$area|$quantity"
  if (-not $script:livePrices.ContainsKey($key)) {
    $url = '/product/calculateprices?quantity=' + $quantity + '&postarea=' + [Uri]::EscapeDataString("$area") + '&variantitem=' + $sizeId + '&productId=' + $productId
    $r = Get-Live $url 'application/json' $null
    $m = [regex]::Match([Text.Encoding]::UTF8.GetString($r.Body), '-?\d+(?:\.\d+)?')
    if ($r.Status -ne 200 -or -not $m.Success) { throw "The live price lookup gave no price for $url ($($r.Status))" }
    $script:livePrices[$key] = [decimal]::Parse($m.Value, [Globalization.CultureInfo]::InvariantCulture)
  }
  $script:livePrices[$key]
}

function Set-BasketLinePrice($line) {
  $line.Price = Get-LiveBasketPrice $line.ProductId $line.SizeId $line.Area $line.Quantity
}

# AddToBasket's area: "NG7" or "NG" -> "NG"; "S10" -> "S"
function Get-BasketArea([string]$postcodeData) {
  if ([string]::IsNullOrWhiteSpace($postcodeData) -or $postcodeData -eq 'undefined') { return $null }
  $area = $postcodeData.Trim()
  if ($area.Length -gt 2) { $area = if ([char]::IsDigit($area[1])) { $area.Substring(0, 1) } else { $area.Substring(0, 2) } }
  $area.ToUpperInvariant()
}

# $code: addtobasket's id (the product's code); $sizeId or $sizeCode: the size (selectedVariantItem, from the product
# page's form, or selectedVariantCode, from a suggestion or add-on); $referer: the page it was added from
function Add-PreviewBasketLine([string]$code, [string]$sizeId, [string]$sizeCode, [int]$quantity, [string]$area, [string]$referer) {
  $path = $null
  if ($referer -and $referer -match $script:productPathPattern) {
    $model = Get-BasketProductModel $referer
    if ($model.Code -eq $code -or $model.AddToBasketUrl -match ('[?&]id=' + [regex]::Escape($code) + '(&|$)')) { $path = $referer }
  }
  if (-not $path) { $path = $script:basketProductPaths[$code.ToUpperInvariant()] }
  if (-not $path) { Register-KnownBasketProducts; $path = $script:basketProductPaths[$code.ToUpperInvariant()] }
  if (-not $path) { throw "The preview doesn't know where product $code's page is" }
  $model = Get-BasketProductModel $path
  Register-BasketProduct $code $path
  $sizes = @($model.Options) + @($model.SampleOption | Where-Object { $_ })
  $size = if ($sizeId) { @($sizes | Where-Object { [string]$_.Id -eq $sizeId })[0] } else { @($sizes | Where-Object { $_.Code -eq $sizeCode })[0] }
  if (-not $size) { throw "No size $sizeId$sizeCode on $($model.Name)" }
  $isSample = $size -eq $model.SampleOption -or $size.Name -match 'sample'
  $isTurf = $model.Code -match '^(?i)tt[23]'
  $lineArea = if ($isSample -or $model.IsSimple) { $null } else { $area }

  # Cart.AddProduct: the same size again adds to its line (not turf, whose price depends on the number of pallets)
  $line = @($script:previewBasket.Lines | Where-Object { $_.Code -eq $size.Code -and $_.ProductCode -eq $model.Code -and -not $_.IsTurf })[0]
  if ($line) {
    $line.Quantity += $quantity
  } else {
    $line = [pscustomobject]@{
      Id = [guid]::NewGuid().ToString(); ProductCode = $model.Code; ProductId = $model.ProductId; SizeId = [int]$size.Id; Code = $size.Code
      Name = $model.Name; SizeName = $size.Name; Path = $model.PagePath; ImageUrl = $(if ($model.Photos.Count) { $model.Photos[0].ThumbUrl } else { '/img/800.png' })
      Quantity = $quantity; Area = $lineArea; Price = [decimal]0; Discount = [decimal]0; PreOrderDate = $size.PreOrderDate; IsSample = $isSample; IsTurf = $isTurf; IsSimple = [bool]$model.IsSimple
    }
    [void]$script:previewBasket.Lines.Add($line)
  }
  Set-BasketLinePrice $line

  # AddToBasket: a new area re-prices every line priced for an area, and becomes the basket's
  if ($area) {
    if ($script:previewBasket.Area -and $script:previewBasket.Area -ne $area) {
      foreach ($l in $script:previewBasket.Lines) { if ($l.Area) { $l.Area = $area; Set-BasketLinePrice $l } }
    }
    if (-not $isSample -and -not $model.IsSimple) { $script:previewBasket.Area = $area }
  }
  $line
}

# The totals, with the voucher's discount on each line (Cart.ApplyCouponAcrossItems)
function Get-PreviewBasketTotals {
  $sub = [decimal]0; $total = [decimal]0; $count = 0
  foreach ($l in $script:previewBasket.Lines) {
    $l.Discount = if ($script:previewBasket.Coupon) { [Math]::Round($l.Price * $script:previewBasket.Coupon.Rate, 2) } else { [decimal]0 }
    $sub += $l.Price; $total += $l.Price - $l.Discount; $count += $l.Quantity
  }
  [pscustomobject]@{ ItemCount = $count; SubTotal = $sub; Total = $total }
}

# The basket page's model (Views/Basket/_BasketPage.cshtml), as Basket/Index.cshtml's new branch fills it
function ConvertTo-PreviewBasketPage([bool]$couponAttempt) {
  $totals = Get-PreviewBasketTotals
  $lines = @(foreach ($l in $script:previewBasket.Lines) {
    [pscustomobject]@{
      Id = $l.Id; NameHtml = [Net.WebUtility]::HtmlEncode($l.Name); Url = $l.Path; ImageUrl = $l.ImageUrl; SizeHtml = [Net.WebUtility]::HtmlEncode($l.SizeName)
      UnitPrice = [Math]::Round($l.Price / $l.Quantity, 2); Quantity = $l.Quantity; CanChangeQuantity = -not $l.IsTurf
      Discount = $l.Discount; LinePrice = $l.Price - $l.Discount; PreOrderDate = $l.PreOrderDate; IsOutOfStock = $false
    }
  })
  [pscustomobject]@{
    Lines = $lines; ItemCount = $totals.ItemCount; SubTotal = $totals.SubTotal; Total = $totals.Total
    Discount = [Math]::Max([decimal]0, $totals.SubTotal - $totals.Total)
    ShowVoucher = $true
    VoucherMessage = $(if ($couponAttempt) { $script:previewBasket.CouponMessage } else { $null })
    PostalArea = $script:previewBasket.Area
    Suggestions = @((Get-SampleBasket @('empty')).Suggestions)
  }
}

# AddToCartComponent.cshtml's markup, with the classes and ids gm-product.js reads (styles left out)
function Format-PreviewAddedSummary {
  $totals = Get-PreviewBasketTotals
  $enc = { param($s) [Net.WebUtility]::HtmlEncode([string]$s) }
  $sb = New-Object Text.StringBuilder
  foreach ($l in $script:previewBasket.Lines) {
    [void]$sb.Append('<div class="modal-item-wrap nofont" id="bask-' + (& $enc $l.Code) + '">')
    [void]$sb.Append('<div class="addtoheader"><h1>Added to your basket</h1></div>')
    [void]$sb.Append('<div class="modal-item modal-item-img"><a href="' + (& $enc $l.Path) + '"><img class="img-fluid" src="' + (& $enc $l.ImageUrl) + '" alt="" /></a></div>')
    [void]$sb.Append('<div class="modal-item modal-item-info"><h2> <a href="' + (& $enc $l.Path) + '"><strong>' + (& $enc $l.Name) + '</strong></a></h2><p>' + (& $enc $l.SizeName) + '</p>')
    if (-not $l.IsTurf) {
      [void]$sb.Append('<div class="quantity buttons_added"><input type="button" value="-" class="minus"><input type="number" step="1" min="1" name="item.Quantity" disabled id="qty" data-id="' + $l.Id + '" value="' + $l.Quantity + '" data-code="' + (& $enc $l.Code) + '" title="Qty" class="input-text qty text"><input type="button" value="+" class="plus"></div>')
    }
    [void]$sb.Append('</div><div class="modal-item modal-item-price"><h3 id="popupLine">' + (Format-Pounds ($l.Price - $l.Discount)) + '</h3></div>')
    if ($l.PreOrderDate) { [void]$sb.Append('<div class="preorder"><span>This item is not in stock. </span>Pre-Order For Delivery W/C: ' + ([datetime]$l.PreOrderDate).ToString('d MMM', $script:gbp) + '</div>') }
    [void]$sb.Append('</div>')
  }
  [void]$sb.Append('<div><div id="popupTotal">Basket Total: <b>' + (Format-Pounds $totals.Total) + '</b></div></div>')
  [void]$sb.Append('<div id="grid-list" class="gridListDesktop showOnDesktop">')
  foreach ($a in $script:summaryAddOns) {
    [void]$sb.Append('<div class="grid-list-block"><a title="' + (& $enc $a.Title) + '"><picture><img src="' + (& $enc $a.Image) + '"></picture><span class="grid-block-wrap"><span class="grid-info match"><h2>' + (& $enc $a.Name) + '</h2></span>')
    [void]$sb.Append('<span class="grid-price-wrap"><span class="grid-price cust-price">' + (Format-Pounds $a.Price) + ' </span><span class="grid-price trade-price" style="display: none;">' + (Format-Pounds $a.Price) + ' </span></span></span>')
    [void]$sb.Append('<span class="grid-price-shop" data-productcode="' + (& $enc $a.Code) + '" data-selectedVariantCode="' + (& $enc $a.Variant) + '">ADD</span></a></div>')
  }
  [void]$sb.Append('</div>')
  $sb.ToString()
}

# The checkout's model for the working basket (checkout-page.ps1's Get-SampleCheckout, with this basket's lines)
function Get-PreviewCheckout {
  $page = ConvertTo-PreviewBasketPage $false
  $lines = @($script:previewBasket.Lines)
  $flags = @()
  if (@($lines | Where-Object { -not $_.IsSample }).Count -eq 0) { $flags += 'samples' }           # samples go by post
  elseif (-not $script:previewBasket.Area) { $flags += 'simple' }                                  # nothing priced for an area
  elseif (@($lines | Where-Object { -not $_.PreOrderDate }).Count -eq 0) { $flags += 'preorder' }  # all pre-orders
  elseif (@($lines | Where-Object { $_.PreOrderDate }).Count -gt 0) { $flags += 'mixed' }          # some pre-orders
  $area = if ($script:previewBasket.Area) { $script:previewBasket.Area } else { '' }
  Get-SampleCheckout $flags $area $page
}

# Answers one of the basket's addresses. $query and $form: the request's NameValueCollections. Returns what to send:
# Status, ContentType and Body, or Location for a redirect, and a Note for the preview's log.
function Invoke-PreviewBasket([string]$method, [string]$path, $query, $form, [bool]$isAjax, [string]$referer) {
  $answer = { param($body, $type, $note) [pscustomobject]@{ Status = 200; ContentType = $(if ($type) { $type } else { 'text/html; charset=utf-8' }); Body = [string]$body; Location = $null; Note = $note } }
  $redirect = { param($to, $note) [pscustomobject]@{ Status = 302; ContentType = $null; Body = ''; Location = $to; Note = $note } }
  $value = { param($name) $(if ($form[$name] -ne $null) { $form[$name] } else { $query[$name] }) }
  $action = ($path.Trim('/') -split '/')[-1].ToLowerInvariant()
  $b = $script:previewBasket

  switch ($action) {
    'addtobasket' {
      $qty = if (& $value 'qty') { [int](& $value 'qty') } else { 1 }
      $area = Get-BasketArea (& $value 'postcodeData')
      $line = Add-PreviewBasketLine (& $value 'id') $form['selectedVariantItem'] (& $value 'selectedVariantCode') $qty $area $referer
      $note = "basket: added $qty x $($line.Name), $($line.SizeName)"
      if (-not $isAjax) { return & $redirect '/basket' $note }
      return & $answer (Format-PreviewAddedSummary) $null $note
    }
    'updatequantity' {
      $line = @($b.Lines | Where-Object { $_.Code -eq $query['code'] })[0]
      if (-not $line) { throw "No line with code $($query['code']) in the basket" }
      $line.Quantity = [int]$query['quantity']
      Set-BasketLinePrice $line
      $totals = Get-PreviewBasketTotals
      return & $answer ((Format-Pounds $totals.Total) + ':' + (Format-Pounds ($line.Price - $line.Discount))) 'text/plain; charset=utf-8' "basket: $($line.Name) now $($line.Quantity)"
    }
    'getbasketsummary' {
      $totals = Get-PreviewBasketTotals
      return & $answer ("{0} Items: {1}|" -f $totals.ItemCount, (Format-Pounds $totals.Total)) 'text/plain; charset=utf-8' 'basket summary'
    }
    'getselectedpostcode' {
      return & $answer $(if ($b.Area) { $b.Area } else { '' }) 'text/plain; charset=utf-8' 'basket area'
    }
    'updatebasket' {
      # the form posts one item.Quantity per line, in the basket's order; a number under 1 removes the line
      $posted = $form.GetValues('item.Quantity')
      $quantities = if ($posted) { @($posted) } else { @() }
      if ($quantities.Count -eq $b.Lines.Count) {
        for ($i = $b.Lines.Count - 1; $i -ge 0; $i--) {
          $n = [int]$quantities[$i]
          if ($n -lt 1) { $b.Lines.RemoveAt($i) } else { $b.Lines[$i].Quantity = $n; Set-BasketLinePrice $b.Lines[$i] }
        }
      }
      return & $redirect '/basket' 'basket: quantities updated'
    }
    'removefrombasket' {
      $line = @($b.Lines | Where-Object { $_.Id -eq $form['id'] })[0]
      $message = ''
      if ($line) { $message = "'" + $line.Name + "' has been removed"; $b.Lines.Remove($line) }
      if ($b.Lines.Count -eq 0) { $b.Area = $null }
      $totals = Get-PreviewBasketTotals
      $json = @{ Message = $message; CartTotal = (Format-Pounds $totals.Total); DeleteId = $form['id']; SubTotal = (Format-Pounds $totals.SubTotal); Summary = ('{0} Items<br/>{1}' -f $totals.ItemCount, (Format-Pounds $totals.Total)) } | ConvertTo-Json -Compress
      return & $answer $json 'application/json; charset=utf-8' "basket: removed $($line.Name)"
    }
    'applycouponcode' {
      $code = ([string]$form['couponcode']).Trim()
      if ($code -ieq $script:sampleCoupon.Code) {
        $totals = Get-PreviewBasketTotals
        if ($totals.Total -gt 40) { $b.Coupon = $script:sampleCoupon; $b.CouponMessage = $script:sampleCoupon.Description }
        else { $b.CouponMessage = 'Sorry, this coupon code is only valid for orders over ' + (Format-Pounds 40) }
      } else {
        $b.CouponMessage = 'Invalid coupon code'
      }
      return & $redirect '/basket/index?couponAttempt=true' "basket: voucher $code"
    }
    'processorder' {
      # "Continue to payment". CheckoutController.ProcessOrder first checks the delivery postcode is in the basket's
      # area (for a basket priced for one); then it would make the order and send the customer to pay
      if ($b.Lines.Count -eq 0) { return & $redirect '/basket' 'checkout: no basket' }
      if ($b.Area) {
        $postcode = ([string]$form['Address.Postcode']).Trim().ToLowerInvariant()
        $areaOf = [regex]::Match($postcode, '^[a-z]{1,2}').Value
        if ($areaOf -ne $b.Area.ToLowerInvariant()) { return & $redirect ('/checkout/orderresulterror?loc=' + $b.Area.ToLowerInvariant()) "checkout: postcode $postcode isn't in $($b.Area)" }
      }
      return & $redirect '/checkout/orderresulterror' 'checkout: payment is not set up in the preview'
    }
  }
  throw "Not a basket address: $path"
}
