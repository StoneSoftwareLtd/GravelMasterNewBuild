# The new product page (Views/Shared/_ProductPage.cshtml) for the whole-website preview. Dot-sourced by
# site-preview.ps1 after category-page.ps1, whose Razor helpers it uses.
#
#   ConvertFrom-OldProductPage  reads an old product page from the live site into what ProductPageModel holds
#   Format-ProductPage          renders _ProductPage.cshtml with it
#
# The description is split by the real ProductDescription.Parse: ViewModels/Common/*PageModels.cs are compiled
# into the preview with Add-Type, so the preview runs the same C# the site will. (A change to those .cs files
# needs the preview restarting.)
# The markup comes from the .cshtml as it is: each Razor block is found in the file and filled in, and the
# render fails if any Razor is left over, so the preview can't silently drift from the partial. If a Razor
# expression in the partial changes, update its entry below.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

if (-not ('Agilis.ECommerce.Mvc.Web.ViewModels.Common.ProductDescription' -as [type])) {
  $models = Join-Path $PSScriptRoot '..\..\Website\Website\ViewModels\Common'
  Add-Type -Path (Join-Path $models 'HomePageModels.cs'), (Join-Path $models 'CategoryPageModels.cs'), (Join-Path $models 'ProductPageModels.cs') -ReferencedAssemblies System.Core
}
$script:ukCulture = [Globalization.CultureInfo]::GetCultureInfo('en-GB')
# a product page: /products/slate-chippings/p/blue-slate-20mm
$script:productPathPattern = '^/products/[a-z0-9-]+/p/[a-z0-9-]+/?$'

# "Thu 24 Sep" or "5 Oct" (no year) -> the next such date from about now
function ConvertFrom-ShortDate([string]$text) {
  $text = [regex]::Replace($text.Trim(), '^[A-Za-z]{3}\s+', '')
  $date = [DateTime]::MinValue
  # invariant month names: the live server writes "Sep", which this PC's en-GB would call "Sept"
  if (-not [DateTime]::TryParseExact($text, [string[]]@('d MMM', 'dd MMM'), [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$date)) { return $null }
  $date = $date.AddYears([DateTime]::Today.Year - $date.Year)
  if ($date -lt [DateTime]::Today.AddDays(-7)) { $date = $date.AddYears(1) }
  $date
}

# ---------- an old product page -> ProductPageModel ----------
# $html is the page's content (Detail.cshtml's output), $path its address. Returns $null for a page it can't read.
function ConvertFrom-OldProductPage([string]$html, [string]$path) {
  $name = [regex]::Match($html, '<h1[^>]*id="productName"[^>]*>([\s\S]*?)</h1>')
  $form = [regex]::Match($html, '<form action="([^"]+)"[^>]*id="AddToCartForm"[^>]*>([\s\S]*?)</form>')
  if (-not $name.Success -or -not $form.Success) { return $null }
  $formHtml = $form.Groups[2].Value
  $model = [pscustomobject]@{
    Name = ConvertFrom-HtmlText $name.Groups[1].Value
    Code = [regex]::Match($html, '<meta itemprop="sku" content="([^"]*)"').Groups[1].Value
    CategoryName = ''
    ProductId = [regex]::Match($html, '&productId=" \+ (\d+)').Groups[1].Value
    AddToBasketUrl = [Net.WebUtility]::HtmlDecode($form.Groups[1].Value)
    Breadcrumbs = @(); Photos = @(); VideoUrl = $null; ThreeSixtyUrl = $null
    Price = [decimal]0; TradePrice = [decimal]0
    IsSimple = [regex]::Match($html, 'var isSimple = (\w+)').Groups[1].Value -eq 'true'
    MinQuantity = 1
    IsInStock = $formHtml.Contains('id="addbask"')
    Options = @(); SelectedOptionId = [int][regex]::Match($html, 'var selectedVarItem = (\d+)').Groups[1].Value; SampleOption = $null
    NextDeliveryDate = $null; Description = $null; Related = @()
  }

  # breadcrumb: <ul class="crumbs"> <li><a href="/garden-chippings/products">Gravels &amp; Chippings</a></li> ... <li>Blue Slate Chippings 20mm</li>
  $crumbs = [regex]::Match($html, '<ul class="crumbs[^"]*"[^>]*>([\s\S]*?)</ul>').Groups[1].Value
  $model.Breadcrumbs = @(foreach ($li in [regex]::Matches($crumbs, '<li[^>]*>([\s\S]*?)</li>')) {
    $link = [regex]::Match($li.Groups[1].Value, '<a[^>]*href="([^"]*)"')
    [pscustomobject]@{ Name = ConvertFrom-HtmlText $li.Groups[1].Value; Url = $(if ($link.Success) { ConvertTo-SitePath $link.Groups[1].Value } else { $null }) }
  })
  $categoryCrumb = @($model.Breadcrumbs | Where-Object { $_.Url }) | Select-Object -Last 1
  if ($categoryCrumb) { $model.CategoryName = $categoryCrumb.Name }

  # photos: the zoomable main photo, then the thumbnail strip's (600px shown, 1000px zoom); thumbnails at 300px
  $thumb = { param($url) [regex]::Replace($url, '-\d+(\.\w+)$', '-300$1') }
  $main = [regex]::Match($html, '<a href="([^"]+)" class="MagicZoom"[^>]*>\s*<img src="([^"]+)"')
  if ($main.Success) { $model.Photos += [pscustomobject]@{ Url = $main.Groups[2].Value; ZoomUrl = $main.Groups[1].Value; ThumbUrl = (& $thumb $main.Groups[2].Value) } }
  foreach ($a in [regex]::Matches($html, '<a [^>]*data-slide-id="zoom" class="active selste" href="([^"]+)" data-image="([^"]+)"')) {
    $model.Photos += [pscustomobject]@{ Url = $a.Groups[2].Value; ZoomUrl = $a.Groups[1].Value; ThumbUrl = (& $thumb $a.Groups[2].Value) }
  }
  $video = [regex]::Match($html, 'wistia_async_(\w+)')
  if ($video.Success) { $model.VideoUrl = 'https://fast.wistia.net/embed/iframe/' + $video.Groups[1].Value + '?videoFoam=true' }
  $spin = [regex]::Match($html, '<iframe src="(https://spinzam\.com/shot/embed/\?idx=\d+)"[^>]*id="rotate3d"')
  if ($spin.Success) { $model.ThreeSixtyUrl = $spin.Groups[1].Value }

  # "From" prices: <h2 id="approxPrice">From <span class="cust-price">&#163;126.00</span><span class="trade-price">&#163;116.00</span>
  $price = { param($cls) [decimal]([regex]::Match($html, '<h2[^>]*id="approxPrice"[\s\S]*?<span class="' + $cls + '">\s*(?:&#163;|\u00A3)([\d,.]+)').Groups[1].Value -replace ',', '') }
  $model.Price = & $price 'cust-price'
  $model.TradePrice = & $price 'trade-price'

  # quantity: 1 up, or 10 up for turf (<input ... min="10" ... name="qty" id="qty">)
  $minValue = [regex]::Match($formHtml, '<input[^>]*\smin="(\d+)"[^>]*\sname="qty"')
  if ($minValue.Success) { $model.MinQuantity = [int]$minValue.Groups[1].Value }

  # sizes: the form's tiles; names, codes and prices from the page's descText, code and price lists
  $names = @{}; $codes = @{}; $prices = @{}
  foreach ($m in [regex]::Matches($html, "descText\[(\d+)\] = '([^']*)'")) { $names[$m.Groups[1].Value] = [Net.WebUtility]::HtmlDecode($m.Groups[2].Value) }
  foreach ($m in [regex]::Matches($html, "code\[(\d+)\] = '([^']*)'")) { $codes[$m.Groups[1].Value] = $m.Groups[2].Value }
  foreach ($m in [regex]::Matches($html, "price\[(\d+)\] = ([\d.]+);")) { $prices[$m.Groups[1].Value] = [decimal]$m.Groups[2].Value }
  $options = @(foreach ($a in [regex]::Matches($formHtml, '<a class="variantsels[^"]*"(?<attrs>[^>]*)>(?<body>[\s\S]*?)</a>')) {
    $id = [regex]::Match($a.Groups['attrs'].Value, 'data-variantitem="(\d+)"').Groups[1].Value
    $pre = [regex]::Match($a.Groups['attrs'].Value, 'data-variantitem-pre="True"').Success
    $preDate = [regex]::Match($a.Groups['attrs'].Value, 'data-variantitem-predate="([^"]*)"').Groups[1].Value
    $label = if ($names.ContainsKey($id)) { [regex]::Replace($names[$id], '\s+', ' ').Trim() } else { ConvertFrom-HtmlText ([regex]::Match($a.Groups['body'].Value, '<span>([\s\S]*?)</span>').Groups[1].Value) }
    [pscustomobject]@{
      Id = [int]$id; Name = $label; Code = $(if ($codes.ContainsKey($id)) { $codes[$id] } else { '' })
      Price = $(if ($prices.ContainsKey($id)) { $prices[$id] } else { [decimal]0 })
      PreOrderDate = $(if ($pre) { ConvertFrom-ShortDate $preDate } else { $null })
    }
  })
  $model.Options = @($options | Where-Object { $_.Name -notmatch 'sample' })
  $sample = [regex]::Match($html, 'id="addSample"[^>]*data-variantitem="(\d+)"')
  if ($sample.Success) {
    $sid = $sample.Groups[1].Value
    $model.SampleOption = [pscustomobject]@{ Id = [int]$sid; Name = 'Sample (Under 1Kg)'; Code = $(if ($codes.ContainsKey($sid)) { $codes[$sid] } else { '' }); Price = [decimal]4.99; PreOrderDate = $null }
  } else {
    $model.SampleOption = @($options | Where-Object { $_.Name -match 'sample' }) | Select-Object -First 1
  }

  $delivery = [regex]::Match($html, 'id="delInfoDate">Next available delivery day: <span id="time2"[^>]*>([^<]+)</span>')
  if ($delivery.Success) { $model.NextDeliveryDate = ConvertFrom-ShortDate $delivery.Groups[1].Value }

  # description: <div id="descrip"> <h2>Description</h2> [360 iframe] ...HTML... </div>
  $desc = [regex]::Match($html, '<div id="descrip"[^>]*>\s*<h2[^>]*>Description</h2>')
  $descHtml = ''
  if ($desc.Success) {
    $end = Find-ClosingDiv $html ($desc.Index + [regex]::Match($html.Substring($desc.Index), '^<div[^>]*>').Length)
    if ($end -ge 0) { $descHtml = $html.Substring($desc.Index + $desc.Length, $end - $desc.Index - $desc.Length) }
  }
  $descHtml = [regex]::Replace($descHtml, '<iframe[^>]*id="rotate3d"[^>]*>\s*</iframe>', '')
  $model.Description = [Agilis.ECommerce.Mvc.Web.ViewModels.Common.ProductDescription]::Parse($descHtml)

  # "Related Products": the desktop grid's tiles, without this product or repeats (the old grid can show the
  # FeatherSnap Bird Feeder twice on Accessories, and a product among its own related products)
  $grid = [regex]::Match($html, '<div id="grid-list" class="gridListDesktop"[\s\S]*?<div id="mobileScroller">').Value
  $seen = @{ ($path.Split('?')[0].TrimEnd('/').ToLower()) = $true }
  $model.Related = @(foreach ($m in [regex]::Matches($grid, '<div class="grid-list-block">([\s\S]*?)<span class="grid-price-shop"')) {
    $b = $m.Groups[1].Value
    $link = [regex]::Match($b, '<a href="([^"]+)"')
    $image = [regex]::Match($b, '<img src="([^"]+)"')
    $p = { param($cls) [decimal]([regex]::Match($b, '<span class="grid-price ' + $cls + '"[^>]*>\s*(?:From\s*)?(?:&#163;|\u00A3)([\d,.]+)').Groups[1].Value -replace ',', '') }
    if (-not $link.Success) { continue }
    $key = (ConvertTo-SitePath $link.Groups[1].Value).TrimEnd('/').ToLower()
    if ($seen.ContainsKey($key)) { continue }
    $seen[$key] = $true
    [pscustomobject]@{
      Name = ConvertFrom-HtmlText ([regex]::Match($b, '<h2[^>]*>([\s\S]*?)</h2>').Groups[1].Value)
      Url = ConvertTo-SitePath $link.Groups[1].Value
      ImageFormat = [regex]::Replace($image.Groups[1].Value, '-\d+(\.\w+)$', '-{0}$1')
      Price = & $p 'cust-price'
      TradePrice = & $p 'trade-price'
    }
  })
  $model
}

# ---------- rendering _ProductPage.cshtml ----------
function Format-ProductPage([string]$templatePath, $model, [string]$enquiryHtml) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments

  # settings from the partial's own C# block
  $optionImages = @([regex]::Matches($src, 'new \{ Word = "([^"]+)", Image = "([^"]+)" \}') | ForEach-Object { [pscustomobject]@{ Word = $_.Groups[1].Value; Image = $_.Groups[2].Value } })
  $useIcons = @([regex]::Matches($src, 'new \{ Word = "([^"]+)", Icon = "([^"]+)" \}') | ForEach-Object { [pscustomobject]@{ Word = $_.Groups[1].Value; Icon = $_.Groups[2].Value } })
  if (-not $optionImages -or -not $useIcons) { throw "Couldn't read optionImages or useIcons from _ProductPage.cshtml" }

  # the same working-out as the partial
  $uk = $script:ukCulture
  $inv = [Globalization.CultureInfo]::InvariantCulture
  $d = $model.Description
  $options = @($model.Options)
  $selected = @($options | Where-Object { $_.Id -eq $model.SelectedOptionId }) | Select-Object -First 1
  if (-not $selected -and $options.Count) { $selected = $options[0] }
  $canBuy = $model.IsInStock -and $selected
  $preOrder = $selected -and $selected.PreOrderDate
  $availability = if (-not $model.IsInStock) { 'OutOfStock' } elseif ($preOrder) { 'PreOrder' } else { 'InStock' }
  $photos = @($model.Photos)
  $slideCount = $photos.Count + $(if ($model.VideoUrl) { 1 } else { 0 }) + $(if ($model.ThreeSixtyUrl) { 1 } else { 0 })
  $longDate = { param($date) $date.ToString('d MMMM', $uk) }

  # Values go in as placeholders until the Razor check is done, so page text can't look like Razor
  $values = New-Object Collections.ArrayList
  function Put([string]$html) { [void]$values.Add($html); [string][char]2 + ($values.Count - 1) + [char]3 }
  function Enc([string]$s) { Put ([Net.WebUtility]::HtmlEncode($s)) }
  function Sub([string]$text, [hashtable]$map) {
    foreach ($key in ($map.Keys | Sort-Object Length -Descending)) {
      if (-not $text.Contains($key)) { throw "Couldn't find $key in _ProductPage.cshtml" }
      $text = $text.Replace($key, $map[$key])
    }
    $text
  }
  $ifShown = { param($shown, $b, [hashtable]$map) if (-not $shown) { '' } elseif ($map) { Sub $b.Inner $map } else { $b.Inner } }

  $start = $src.IndexOf('<div class="gm-product"')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-product""> in _ProductPage.cshtml" }
  $h = $src.Substring($start)

  # breadcrumb
  $h = Set-RazorBlock $h '@foreach \(var crumb in Model\.Breadcrumbs\)\s*\{' { param($b)
    (@($model.Breadcrumbs) | ForEach-Object {
      $crumb = $_
      Set-RazorBlock $b.Inner '(?<!@)if \(crumb\.Url != null\)\s*\{' { param($ib)
        if ($crumb.Url) { Sub $ib.Inner @{ '@crumb.Url' = (Enc $crumb.Url); '@crumb.Name' = (Enc $crumb.Name) } }
        else { Sub $ib.ElseInner @{ '@crumb.Name' = (Enc $crumb.Name) } }
      }
    }) -join ''
  }

  # photos
  $first = if ($photos.Count) { $photos[0] } else { $null }
  $h = Set-RazorBlock $h '@if \(Model\.Photos\.Count > 0\)\s*\{' { param($b) & $ifShown $first $b @{ '@Model.Photos[0].Url' = (Enc $first.Url); '@Model.Name' = (Enc $model.Name) } }
  $h = Set-RazorBlock $h '@if \(slideCount > 1\)\s*\{' { param($b) & $ifShown ($slideCount -gt 1) $b $null }
  $h = Set-RazorBlock $h '@if \(Model\.Photos\.Count > 0\)\s*\{' { param($b) & $ifShown $first $b @{ '@Model.Photos[0].ZoomUrl' = (Enc $first.ZoomUrl) } }
  $h = Set-RazorBlock $h '@if \(slideCount > 1\)\s*\{' { param($b)
    if ($slideCount -le 1) { return '' }
    $t = Set-RazorBlock $b.Inner '@for \(int i = 0; i < Model\.Photos\.Count; i\+\+\)\s*\{' { param($lb)
      $markup = Get-LoopMarkup $lb.Inner
      (0..($photos.Count - 1) | ForEach-Object {
        $i = $_; $photo = $photos[$i]
        Sub $markup @{ '@(i == 0 ? " is-active" : "")' = $(if ($i -eq 0) { ' is-active' } else { '' }); '@(i + 1)' = [string]($i + 1); '@Model.Photos.Count' = [string]$photos.Count
          '@(i == 0 ? "true" : "false")' = $(if ($i -eq 0) { 'true' } else { 'false' }); '@photo.Url' = (Enc $photo.Url); '@photo.ZoomUrl' = (Enc $photo.ZoomUrl); '@photo.ThumbUrl' = (Enc $photo.ThumbUrl) }
      }) -join ''
    }
    $t = Set-RazorBlock $t '@if \(Model\.VideoUrl != null\)\s*\{' { param($ib) & $ifShown $model.VideoUrl $ib @{ '@Model.VideoUrl' = (Enc $model.VideoUrl) } }
    Set-RazorBlock $t '@if \(Model\.ThreeSixtyUrl != null\)\s*\{' { param($ib) & $ifShown $model.ThreeSixtyUrl $ib @{ '@Model.ThreeSixtyUrl' = (Enc $model.ThreeSixtyUrl) } }
  }
  $h = Sub $h @{ '@HomeProduct.FormatPrice(Model.Price, false)' = (Put (Format-GbpPrice $model.Price $false)); '@HomeProduct.FormatPrice(Model.TradePrice, false)' = (Put (Format-GbpPrice $model.TradePrice $false)) }

  # stock, title, offer details
  $h = Set-RazorBlock $h '@if \(Model\.IsInStock\)\s*\{' { param($b) & $ifShown $model.IsInStock $b @{ '@(preOrder ? "Available to pre-order" : "In stock")' = $(if ($preOrder) { 'Available to pre-order' } else { 'In stock' }) } }
  $h = Sub $h @{ '@Model.Code' = (Enc $model.Code); '@Model.Price.ToString("0.00", CultureInfo.InvariantCulture)' = ([decimal]$model.Price).ToString('0.00', $inv); '@availability' = $availability }

  # the buy form, or "can't be ordered online"
  $h = Set-RazorBlock $h '@if \(Model\.Options\.Count == 0\)\s*\{' { param($b)
    if ($options.Count -eq 0) { return Set-RazorBlock $b.Inner '(?<!@)if \(Model\.IsInStock\)\s*\{' { param($ib) if ($model.IsInStock) { $ib.Inner } else { $ib.ElseInner } } }
    $f = $b.ElseInner
    $f = Sub $f @{ '@Model.AddToBasketUrl' = (Enc $model.AddToBasketUrl); '@Model.ProductId' = (Enc $model.ProductId); '@Model.CategoryName' = (Enc $model.CategoryName)
      '@(Model.IsSimple ? "true" : "false")' = $(if ($model.IsSimple) { 'true' } else { 'false' })
      '@string.Join(",", ProductPageModel.PostcodeAreas)' = ([Agilis.ECommerce.Mvc.Web.ViewModels.Common.ProductPageModel]::PostcodeAreas -join ',')
      '@{ int step = 1; }' = '' }
    $f = Set-EachRazorBlock $f '@if \(!Model\.IsSimple\)\s*\{' { param($ib) & $ifShown (-not $model.IsSimple) $ib $null }
    # "Step @(step++)" counts the steps that are left: 1, 2, 3, or 1, 2 without the postcode
    $n = 0
    for ($at = $f.IndexOf('@(step++)'); $at -ge 0; $at = $f.IndexOf('@(step++)')) { $n++; $f = $f.Substring(0, $at) + $n + $f.Substring($at + '@(step++)'.Length) }
    # sizes
    $f = Sub $f @{ '@(Model.Options.Count == 1 ? "size" : "bag size")' = $(if ($options.Count -eq 1) { 'size' } else { 'bag size' }); '@(Model.Options.Count == 1 ? " pdp-options--one" : "")' = $(if ($options.Count -eq 1) { ' pdp-options--one' } else { '' }) }
    $f = Set-RazorBlock $f '@foreach \(var option in Model\.Options\)\s*\{' { param($lb)
      $markup = Get-LoopMarkup $lb.Inner
      ($options | ForEach-Object {
        $option = $_
        $image = $optionImages | Where-Object { $option.Name.IndexOf($_.Word, [StringComparison]::OrdinalIgnoreCase) -ge 0 } | Select-Object -First 1
        $imageUrl = if ($image) { $image.Image } else { '/img/' + $option.Name.Replace(' ', '').ToLower() + '.gif' }
        $o = Set-RazorBlock $markup '@if \(option\.PreOrderDate\.HasValue\)\s*\{' { param($ib) & $ifShown $option.PreOrderDate $ib @{ '@option.PreOrderDate.Value.ToString("d MMMM", uk)' = (Enc $(if ($option.PreOrderDate) { & $longDate $option.PreOrderDate } else { '' })) } }
        Sub $o @{ '@option.Id' = [string]$option.Id; '@(option == selected ? "checked" : "")' = $(if ([object]::ReferenceEquals($option, $selected)) { 'checked' } else { '' })
          '@option.Code' = (Enc $option.Code); '@option.Price.ToString("0.00", CultureInfo.InvariantCulture)' = ([decimal]$option.Price).ToString('0.00', $inv)
          '@(option.PreOrderDate.HasValue ? option.PreOrderDate.Value.ToString("d MMMM", uk) : "")' = (Enc $(if ($option.PreOrderDate) { & $longDate $option.PreOrderDate } else { '' }))
          '@imageUrl' = (Enc $imageUrl); '@option.Name' = (Enc $option.Name) }
      }) -join ''
    }
    # sample, quantity, delivery notice, total, button
    $s = $model.SampleOption
    $f = Set-RazorBlock $f '@if \(Model\.SampleOption != null && canBuy\)\s*\{' { param($ib)
      & $ifShown ($s -and $canBuy) $ib @{ '@Model.SampleOption.Id' = [string]$s.Id; '@Model.SampleOption.Code' = (Enc $s.Code); '@Model.SampleOption.Price.ToString("0.00", CultureInfo.InvariantCulture)' = ([decimal]$s.Price).ToString('0.00', $inv) }
    }
    $f = Sub $f @{ '@Model.MinQuantity' = [string]$model.MinQuantity }
    $f = Set-RazorBlock $f '@if \(Model\.NextDeliveryDate\.HasValue \|\| !Model\.IsSimple\)\s*\{' { param($ib)
      if (-not ($model.NextDeliveryDate -or -not $model.IsSimple)) { return '' }
      $t = Set-RazorBlock $ib.Inner '@if \(Model\.NextDeliveryDate\.HasValue\)\s*\{' { param($db)
        & $ifShown $model.NextDeliveryDate $db @{ '@(preOrder ? "hidden" : "")' = $(if ($preOrder) { 'hidden' } else { '' }); '@Model.NextDeliveryDate.Value.ToString("dddd d MMMM", uk)' = (Enc $(if ($model.NextDeliveryDate) { $model.NextDeliveryDate.ToString('dddd d MMMM', $uk) } else { '' })) }
      }
      Sub $t @{ '@(preOrder ? "" : "hidden")' = $(if ($preOrder) { '' } else { 'hidden' }); '@(preOrder ? selected.PreOrderDate.Value.ToString("d MMMM", uk) : "")' = (Enc $(if ($preOrder) { & $longDate $selected.PreOrderDate } else { '' })) }
    }
    $f = Sub $f @{ '@(Model.IsSimple ? "" : " & delivery")' = (Enc $(if ($model.IsSimple) { '' } else { ' & delivery' })); '@(Model.IsSimple ? "" : "Enter your postcode")' = $(if ($model.IsSimple) { '' } else { 'Enter your postcode' }) }
    Set-RazorBlock $f '@if \(canBuy\)\s*\{' { param($ib) if ($canBuy) { Sub $ib.Inner @{ '@(preOrder ? "Pre-order" : "Add to cart")' = $(if ($preOrder) { 'Pre-order' } else { 'Add to cart' }) } } else { $ib.ElseInner } }
  }
  $h = Sub $h @{ '@Model.Name' = (Enc $model.Name) }

  # specification, uses, the description's sections
  $h = Set-RazorBlock $h '@if \(description\.IntroHtml\.Length > 0\)\s*\{' { param($b) & $ifShown ($d.IntroHtml.Length -gt 0) $b @{ '@Html.Raw(description.IntroHtml)' = (Put $d.IntroHtml) } }
  $h = Set-RazorBlock $h '@if \(description\.Specs\.Count > 0\)\s*\{' { param($b)
    if ($d.Specs.Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@foreach \(var spec in description\.Specs\)\s*\{' { param($lb) (@($d.Specs) | ForEach-Object { Sub $lb.Inner @{ '@spec.Label' = (Enc $_.Label); '@spec.Value' = (Enc $_.Value) } }) -join '' }
  }
  $h = Set-RazorBlock $h '@if \(description\.Uses\.Count > 0\)\s*\{' { param($b)
    if ($d.Uses.Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@foreach \(var use in description\.Uses\)\s*\{' { param($lb)
      (@($d.Uses) | ForEach-Object {
        $use = $_
        $icon = $useIcons | Where-Object { $use.IndexOf($_.Word, [StringComparison]::OrdinalIgnoreCase) -ge 0 } | Select-Object -First 1
        $item = Set-RazorBlock (Get-LoopMarkup $lb.Inner) '@if \(icon != null\)\s*\{' { param($ib) if ($icon) { Sub $ib.Inner @{ '@icon.Icon' = (Enc $icon.Icon) } } else { $ib.ElseInner } }
        Sub $item @{ '@use' = (Enc $use) }
      }) -join ''
    }
  }
  $h = Set-RazorBlock $h '@foreach \(var part in description\.Sections\)\s*\{' { param($b)
    (@($d.Sections) | ForEach-Object { Sub $b.Inner @{ '@part.Heading' = (Enc $_.Heading); '@Html.Raw(part.Html)' = (Put $_.Html) } }) -join ''
  }

  # You might also like
  $h = Set-RazorBlock $h '@if \(Model\.Related\.Count > 0\)\s*\{' { param($b)
    if (@($model.Related).Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@foreach \(var product in Model\.Related\)\s*\{' { param($lb)
      (@($model.Related) | ForEach-Object {
        Sub $lb.Inner @{ '@product.ImageUrl(330)' = (Enc $_.ImageFormat.Replace('{0}', '330')); '@product.Url' = (Enc $_.Url); '@product.Name' = (Enc $_.Name)
          '@HomeProduct.FormatPrice(product.Price, true)' = (Put (Format-GbpPrice $_.Price $true)); '@HomeProduct.FormatPrice(product.TradePrice, true)' = (Put (Format-GbpPrice $_.TradePrice $true)) }
      }) -join ''
    }
  }

  # the shared bulk enquiry pop-up (rendered by build.ps1)
  $h = Sub $h @{ '@Html.Partial("_BulkEnquiryModal", Model.EnquiryCategories)' = (Put $enquiryHtml) }

  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]')
  if ($m.Success) { throw "_ProductPage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  [regex]::Replace($h, [string][char]2 + '(\d+)' + [char]3, { param($x) $values[[int]$x.Groups[1].Value] })
}
