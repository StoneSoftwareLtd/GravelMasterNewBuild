# The new category page (Views/Shared/_CategoryPage.cshtml) for the previews. Dot-sourced by build.ps1
# (preview/category.html) and site-preview.ps1 (every category page on localhost:8780).
#
#   ConvertFrom-OldCategoryPage  reads an old category page from the live site into what CategoryPageModel
#                                holds (the same split of the description as CategoryDescription.Parse)
#   Format-CategoryPage          renders _CategoryPage.cshtml with it
#
# The markup comes from the .cshtml as it is: each Razor block is found in the file and filled in, and the
# render fails if any Razor is left over, so the preview can't silently drift from the partial. If a Razor
# expression in the partial changes, update its entry below.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

$script:categorySortOptions = @('Relevance', 'Name', 'Price (Low to High)', 'Price (High to Low)')
$script:divTag = New-Object Text.RegularExpressions.Regex '<div\b[^>]*>|</div\s*>', 'IgnoreCase'

function ConvertFrom-HtmlText([string]$s) {
  $text = [regex]::Replace($s, '<[^>]+>', ' ')
  [Net.WebUtility]::HtmlDecode([regex]::Replace($text, '\s+', ' ')).Trim()
}
function ConvertTo-SitePath([string]$href) {
  $path = [regex]::Replace($href, '^https?://(?:www\.)?gravelmaster\.co\.uk(?=/|$)', '', 'IgnoreCase')
  if ($path -eq '') { '/' } else { [Net.WebUtility]::HtmlDecode($path) }
}

# ---------- CategoryDescription.Parse and SplitIdealFor (ViewModels/Common/CategoryPageModels.cs) ----------
function Find-ClosingDiv([string]$html, [int]$contentStart) {
  $depth = 1
  $tag = $script:divTag.Match($html, $contentStart)
  while ($tag.Success) {
    if ($tag.Value.StartsWith('</')) { $depth-- } else { $depth++ }
    if ($depth -eq 0) { return $tag.Index }
    $tag = $tag.NextMatch()
  }
  -1
}

function Split-IdealFor([string]$text) {
  $items = @(("$text").Split(',') | ForEach-Object { $_.Trim().TrimEnd('.').Trim() } | Where-Object { $_.Length -gt 0 })
  if ($items.Count -gt 1) {
    $last = [regex]::Replace($items[$items.Count - 1], '^and\s+', '', 'IgnoreCase')
    $items = @($items[0..($items.Count - 2)])
    $and = $last.LastIndexOf(' and ', [StringComparison]::OrdinalIgnoreCase)
    if ($and -gt 0) { $items += $last.Substring(0, $and).Trim(); $items += $last.Substring($and + 5).Trim() }
    else { $items += $last }
  }
  , @($items | Where-Object { $_.Length -gt 0 })
}

function Split-CategoryDescription([string]$html) {
  $result = [pscustomobject]@{ IdealFor = @(); IntroHtml = ''; MoreHtml = $null }
  if ([string]::IsNullOrWhiteSpace($html)) { return $result }
  $html = $html.Trim()

  $wrapper = [regex]::Match($html, '^<div\b[^>]*\bid="cat_desc"[^>]*>', 'IgnoreCase')
  if ($wrapper.Success) {
    $end = Find-ClosingDiv $html ($wrapper.Index + $wrapper.Length)
    if ($end -ge 0 -and $html.Substring($end).Trim() -ieq '</div>') { $html = $html.Substring($wrapper.Length, $end - $wrapper.Length).Trim() }
  }

  $heading = [regex]::Match($html, '<h2[^>]*>\s*Ideal for:?(.*?)</h2>', 'IgnoreCase, Singleline')
  if ($heading.Success) {
    $result.IdealFor = Split-IdealFor (ConvertFrom-HtmlText $heading.Groups[1].Value)
    $html = $html.Remove($heading.Index, $heading.Length)
  }

  $more = [regex]::Match($html, '<div\b[^>]*\bid="cat_desc_readmore"[^>]*>', 'IgnoreCase')
  if ($more.Success) {
    $start = $more.Index + $more.Length
    $end = Find-ClosingDiv $html $start
    if ($end -ge 0) {
      $moreHtml = $html.Substring($start, $end - $start).Trim()
      $result.MoreHtml = if ($moreHtml.Length -gt 0) { $moreHtml } else { $null }
      $html = $html.Substring(0, $more.Index) + $html.Substring($html.IndexOf('>', $end) + 1)
    }
  }
  $result.IntroHtml = $html.Trim()
  $result
}

# ---------- an old category page -> CategoryPageModel ----------
# $path is the page's address on the site (e.g. /garden-chippings/products/filter-colour-black-2), $sort the
# posted sort, $enquiryCategories the top-level category names. Returns $null for a page it can't read.
function ConvertFrom-OldCategoryPage([string]$html, [string]$path, [string]$sort, [string[]]$enquiryCategories) {
  $path = $path.Split('?')[0]
  $address = [regex]::Match($path, '^/([a-z0-9-]+)(?:/([a-z0-9-]+))?/products(?:/|$)', 'IgnoreCase')
  $title = [regex]::Match($html, '<h1[^>]*>([\s\S]*?)</h1>')
  # a category page has the product grid, even when a filter leaves it empty
  if (-not $address.Success -or ($address.Groups[1].Value -ieq 'products') -or -not $title.Success -or ($html.IndexOf('id="grid-list"') -lt 0)) { return $null }

  $model = [pscustomobject]@{
    Title = ConvertFrom-HtmlText $title.Groups[1].Value
    CategoryUrl = $(if ($address.Groups[2].Success) { $address.Groups[2].Value } else { $address.Groups[1].Value }).ToLower()
    Breadcrumbs = @(); Description = $null; DeliveryMessage = $null; FilterGroups = @(); ClearFiltersUrl = $null
    SelectedSort = $(if ($script:categorySortOptions -contains $sort) { $sort } else { $script:categorySortOptions[0] })
    Products = @(); EnquiryCategories = @($enquiryCategories)
  }

  # breadcrumb: <ul class="crumbs"> <li><a href="/garden-chippings/products">Gravels &amp; Chippings</a></li> <li>Slate Chippings</li>
  $crumbs = [regex]::Match($html, '<ul class="crumbs[^"]*"[^>]*>([\s\S]*?)</ul>').Groups[1].Value
  $model.Breadcrumbs = @(foreach ($li in [regex]::Matches($crumbs, '<li[^>]*>([\s\S]*?)</li>')) {
    $link = [regex]::Match($li.Groups[1].Value, '<a[^>]*href="([^"]*)"')
    [pscustomobject]@{ Name = ConvertFrom-HtmlText $li.Groups[1].Value; Url = $(if ($link.Success) { ConvertTo-SitePath $link.Groups[1].Value } else { $null }) }
  })

  # description: <div id="cat_desc"> ... </div>
  $desc = [regex]::Match($html, '<div id="cat_desc"[^>]*>')
  $descHtml = ''
  if ($desc.Success) {
    $end = Find-ClosingDiv $html ($desc.Index + $desc.Length)
    if ($end -ge 0) { $descHtml = $html.Substring($desc.Index, $html.IndexOf('>', $end) + 1 - $desc.Index) }
  }
  $model.Description = Split-CategoryDescription $descHtml

  $model.DeliveryMessage = ConvertFrom-HtmlText ([regex]::Match($html, '<div id="time"[^>]*>([\s\S]*?)</div>').Groups[1].Value)

  # filters: <button class="accordion filter-1">Colour</button> <ul class="attr_list"> <li class="selected"><a title=".." href="..">..</a></li>
  $model.FilterGroups = @(foreach ($g in [regex]::Matches($html, '<button class="accordion filter-\d+"[^>]*>([\s\S]*?)</button>\s*<ul class="attr_list">([\s\S]*?)</ul>')) {
    $options = @(foreach ($o in [regex]::Matches($g.Groups[2].Value, '<li(?<sel>\s+class="selected")?[^>]*>\s*<a[^>]*href="(?<href>[^"]*)"[^>]*>(?<name>[\s\S]*?)</a>')) {
      [pscustomobject]@{ Name = ConvertFrom-HtmlText $o.Groups['name'].Value; Url = ConvertTo-SitePath $o.Groups['href'].Value; Selected = $o.Groups['sel'].Success }
    })
    [pscustomobject]@{ Name = ConvertFrom-HtmlText $g.Groups[1].Value; Options = $options }
  })
  if (@($model.FilterGroups | ForEach-Object { $_.Options } | Where-Object { $_.Selected }).Count -gt 0) {
    $model.ClearFiltersUrl = [regex]::Replace($path, '(/products)(?:/.*)?$', '$1/', 'IgnoreCase')
  }

  # product tiles
  $model.Products = @(foreach ($m in [regex]::Matches($html, '<div class="grid-list-block">([\s\S]*?)<span class="grid-price-shop">')) {
    $b = $m.Groups[1].Value
    $link = [regex]::Match($b, '<a href="([^"]+)"')
    $image = [regex]::Match($b, '\sdata-src="([^"]+)"')
    if (-not $image.Success) { $image = [regex]::Match($b, '<picture>[\s\S]*?\ssrc="(?!data:)([^"]+)"') }
    $price = { param($cls) [decimal]([regex]::Match($b, '<span class="grid-price ' + $cls + '">\s*(?:&#163;|\u00A3)([\d,.]+)').Groups[1].Value -replace ',', '') }
    if (-not $link.Success) { continue }
    [pscustomobject]@{
      Name = ConvertFrom-HtmlText ([regex]::Match($b, '<h2>([\s\S]*?)</h2>').Groups[1].Value)
      Url = ConvertTo-SitePath $link.Groups[1].Value
      ImageFormat = [regex]::Replace($image.Groups[1].Value, '-\d+(\.\w+)$', '-{0}$1')
      Price = & $price 'cust-price'
      TradePrice = & $price 'trade-price'
      Synopsis = ConvertFrom-HtmlText ([regex]::Match($b, '<span class="synopsis">([\s\S]*?)</span>').Groups[1].Value)
    }
  })
  $model
}

# ---------- rendering _CategoryPage.cshtml ----------
# HomeProduct.FormatPrice
function Format-GbpPrice([decimal]$price, [bool]$withPence) {
  $uk = [Globalization.CultureInfo]::GetCultureInfo('en-GB')
  if ($withPence -or $price -ne [Math]::Floor($price)) { '&#163;' + $price.ToString('#,0.00', $uk) } else { '&#163;' + $price.ToString('#,0', $uk) }
}

# Finds a Razor block (the pattern ends at its opening brace) and any else block after it
function Find-RazorBlock([string]$text, [string]$startPattern) {
  $m = [regex]::Match($text, $startPattern)
  if (-not $m.Success) { throw "Couldn't find $startPattern in the partial" }
  $open = $m.Index + $m.Length - 1
  if ($text[$open] -ne '{') { throw "The pattern $startPattern must end at the block's opening brace" }
  $close = Find-ClosingBrace $text $open
  $block = @{ Start = $m.Index; Inner = $text.Substring($open + 1, $close - $open - 1); ElseInner = $null; End = $close + 1 }
  $else = [regex]::Match($text.Substring($close + 1), '^\s*else\s*\{')
  if ($else.Success) {
    $elseOpen = $close + $else.Length
    $elseClose = Find-ClosingBrace $text $elseOpen
    $block.ElseInner = $text.Substring($elseOpen + 1, $elseClose - $elseOpen - 1)
    $block.End = $elseClose + 1
  }
  $block
}
function Find-ClosingBrace([string]$text, [int]$open) {
  $depth = 0
  for ($i = $open; $i -lt $text.Length; $i++) {
    if ($text[$i] -eq '{') { $depth++ } elseif ($text[$i] -eq '}') { $depth--; if ($depth -eq 0) { return $i } }
  }
  throw "Unbalanced braces in the partial"
}
# Replaces a Razor block with what $fill returns for it
function Set-RazorBlock([string]$text, [string]$startPattern, [scriptblock]$fill) {
  $block = Find-RazorBlock $text $startPattern
  $text.Substring(0, $block.Start) + (& $fill $block) + $text.Substring($block.End)
}
# The same for every block that matches (e.g. two "@if (option.Selected)" in one option)
function Set-EachRazorBlock([string]$text, [string]$startPattern, [scriptblock]$fill) {
  while ([regex]::IsMatch($text, $startPattern)) { $text = Set-RazorBlock $text $startPattern $fill }
  $text
}
# A loop body without its leading C# statements ("var product = gridProducts[i];", "string imageUrl = ...;")
function Get-LoopMarkup([string]$inner) { [regex]::Replace($inner, '(?m)^[ \t]*(?:var|string|int|bool) \w+ = [^\r\n]*;[ \t]*\r?\n', '') }

function Format-CategoryPage([string]$templatePath, $model, [string]$enquiryHtml) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments

  # settings from the partial's own C# block
  $idealIcons = @([regex]::Matches($src, 'new \{ Word = "([^"]+)", Icon = "([^"]+)" \}') | ForEach-Object { [pscustomobject]@{ Word = $_.Groups[1].Value; Icon = $_.Groups[2].Value } })
  $promoBlock = [regex]::Match($src, 'var promoProducts = new Dictionary<string, string>\s*\{([\s\S]*?)\};').Groups[1].Value
  $promoProducts = @{}
  foreach ($p in [regex]::Matches($promoBlock, '\{\s*"([^"]+)",\s*"([^"]+)"\s*\}')) { $promoProducts[$p.Groups[1].Value] = $p.Groups[2].Value }
  $promoPosition = [regex]::Match($src, 'const int promoPosition = (\d+);')
  if (-not $idealIcons -or $promoProducts.Count -eq 0 -or -not $promoPosition.Success) { throw "Couldn't read idealIcons, promoProducts or promoPosition from _CategoryPage.cshtml" }

  # the same working-out as the partial
  $d = $model.Description
  $isFiltered = [bool]$model.ClearFiltersUrl
  $promo = $null
  if (-not $isFiltered -and $model.SelectedSort -eq $script:categorySortOptions[0] -and $model.CategoryUrl -and $promoProducts.ContainsKey($model.CategoryUrl)) {
    $promo = @($model.Products | Where-Object { $_.Url.EndsWith('/p/' + $promoProducts[$model.CategoryUrl], [StringComparison]::OrdinalIgnoreCase) }) | Select-Object -First 1
  }
  $grid = New-Object Collections.ArrayList
  foreach ($p in $model.Products) { if (-not [object]::ReferenceEquals($p, $promo)) { [void]$grid.Add($p) } }
  if ($promo) { $grid.Insert([Math]::Min([int]$promoPosition.Groups[1].Value, $grid.Count), $promo) }
  $count = @($model.Products).Count
  $productsText = "$count " + $(if ($count -eq 1) { 'product' } else { 'products' })
  $chosen = @($model.FilterGroups | ForEach-Object { $_.Options } | Where-Object { $_.Selected }).Count

  # Values go in as placeholders until the Razor check is done, so page text can't look like Razor
  $values = New-Object Collections.ArrayList
  function Put([string]$html) { [void]$values.Add($html); [string][char]2 + ($values.Count - 1) + [char]3 }
  function Enc([string]$s) { Put ([Net.WebUtility]::HtmlEncode($s)) }
  function Sub([string]$text, [hashtable]$map) {
    foreach ($key in ($map.Keys | Sort-Object Length -Descending)) {
      if (-not $text.Contains($key)) { throw "Couldn't find $key in _CategoryPage.cshtml" }
      $text = $text.Replace($key, $map[$key])
    }
    $text
  }

  $start = $src.IndexOf('<div class="gm-category">')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-category""> in _CategoryPage.cshtml" }
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
  $h = Sub $h @{ '@Model.Title' = (Enc $model.Title) }

  # description and "Ideal for"
  $h = Set-RazorBlock $h '@if \(description\.IntroHtml\.Length > 0\)\s*\{' { param($b) if ($d.IntroHtml.Length -gt 0) { Sub $b.Inner @{ '@Html.Raw(description.IntroHtml)' = (Put $d.IntroHtml) } } else { '' } }
  $h = Set-RazorBlock $h '@if \(description\.MoreHtml != null\)\s*\{' { param($b) if ($null -ne $d.MoreHtml) { Sub $b.Inner @{ '@Html.Raw(description.MoreHtml)' = (Put $d.MoreHtml) } } else { '' } }
  $h = Set-RazorBlock $h '@if \(description\.IdealFor\.Count > 0\)\s*\{' { param($b)
    if (@($d.IdealFor).Count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@foreach \(var use in description\.IdealFor\)\s*\{' { param($lb)
      (@($d.IdealFor) | ForEach-Object {
        $use = $_
        $icon = $idealIcons | Where-Object { $use.IndexOf($_.Word, [StringComparison]::OrdinalIgnoreCase) -ge 0 } | Select-Object -First 1
        $item = Set-RazorBlock (Get-LoopMarkup $lb.Inner) '@if \(icon != null\)\s*\{' { param($ib) if ($icon) { Sub $ib.Inner @{ '@icon.Icon' = (Enc $icon.Icon) } } else { $ib.ElseInner } }
        Sub $item @{ '@use' = (Enc $use) }
      }) -join ''
    }
  }

  # phone filter bar, delivery message, filters
  $h = Set-RazorBlock $h '@if \(Model\.FilterGroups\.Count > 0\)\s*\{' { param($b)
    if (@($model.FilterGroups).Count -eq 0) { return '' }
    Sub $b.Inner @{ '@(Model.IsFiltered ? " (" + Model.FilterGroups.Sum(g => g.Options.Count(o => o.Selected)) + ")" : "")' = (Enc $(if ($isFiltered) { " ($chosen)" } else { '' })) }
  }
  $h = Set-RazorBlock $h '@if \(!string\.IsNullOrWhiteSpace\(Model\.DeliveryMessage\)\)\s*\{' { param($b) if ($model.DeliveryMessage) { Sub $b.Inner @{ '@Model.DeliveryMessage' = (Enc $model.DeliveryMessage) } } else { '' } }
  $h = Set-RazorBlock $h '@if \(Model\.FilterGroups\.Count > 0\)\s*\{' { param($b)
    if (@($model.FilterGroups).Count -eq 0) { return '' }
    $w = Set-RazorBlock $b.Inner '@if \(Model\.IsFiltered\)\s*\{' { param($ib) if ($isFiltered) { Sub $ib.Inner @{ '@Model.ClearFiltersUrl' = (Enc $model.ClearFiltersUrl) } } else { '' } }
    $w = Set-RazorBlock $w '@for \(int g = 0; g < Model\.FilterGroups\.Count; g\+\+\)\s*\{' { param($lb)
      $groups = @($model.FilterGroups)
      (0..($groups.Count - 1) | ForEach-Object {
        $g = $_; $group = $groups[$g]
        $hasSelection = @($group.Options | Where-Object { $_.Selected }).Count -gt 0
        $markup = Set-RazorBlock (Get-LoopMarkup $lb.Inner) '@foreach \(var option in group\.Options\)\s*\{' { param($ob)
          (@($group.Options) | ForEach-Object {
            $option = $_
            $o = Set-EachRazorBlock $ob.Inner '@if \(option\.Selected\)\s*\{' { param($ib) if ($option.Selected) { $ib.Inner } else { '' } }
            Sub $o @{ '@option.Url' = (Enc $option.Url); '@(option.Selected ? " is-on" : "")' = $(if ($option.Selected) { ' is-on' } else { '' }); '@option.Name' = (Enc $option.Name) }
          }) -join ''
        }
        Sub $markup @{ '@(g < 2 || group.HasSelection ? "open" : "")' = $(if ($g -lt 2 -or $hasSelection) { 'open' } else { '' }); '@group.Name' = (Enc $group.Name) }
      }) -join ''
    }
    Sub $w @{ '@productsText' = (Enc $productsText) }
  }

  # count and Sort by
  $h = Sub $h @{ 'Showing @productsText' = ('Showing ' + (Enc $productsText)) }
  $h = Set-RazorBlock $h '@foreach \(var sort in CategoryPageModel\.SortOptions\)\s*\{' { param($b)
    ($script:categorySortOptions | ForEach-Object { Sub $b.Inner @{ '@(sort == Model.SelectedSort ? "selected" : "")' = $(if ($_ -eq $model.SelectedSort) { 'selected' } else { '' }); '@sort' = (Enc $_) } }) -join ''
  }

  # products, or the "no products" message
  $h = Set-RazorBlock $h '@if \(count == 0\)\s*\{' { param($b)
    if ($count -eq 0) {
      return Set-RazorBlock $b.Inner '@if \(Model\.IsFiltered\)\s*\{' { param($ib) if ($isFiltered) { Sub $ib.Inner @{ '@Model.ClearFiltersUrl' = (Enc $model.ClearFiltersUrl) } } else { '' } }
    }
    Set-RazorBlock $b.ElseInner '@for \(int i = 0; i < gridProducts\.Count; i\+\+\)\s*\{' { param($lb)
      (0..($grid.Count - 1) | ForEach-Object {
        $i = $_; $product = $grid[$i]
        $isPromo = [object]::ReferenceEquals($product, $promo)
        Set-RazorBlock (Get-LoopMarkup $lb.Inner) '(?<!@)if \(product == promo\)\s*\{' { param($ib)
          $image = { param($size) Enc $product.ImageFormat.Replace('{0}', [string]$size) }
          $common = @{ '@product.Url' = (Enc $product.Url); '@product.Name' = (Enc $product.Name); '@product.Synopsis' = (Enc $product.Synopsis) }
          if ($isPromo) {
            Sub $ib.Inner ($common + @{ '@product.ImageUrl(600)' = (& $image 600)
              '@HomeProduct.FormatPrice(product.Price, false)' = (Put (Format-GbpPrice $product.Price $false)); '@HomeProduct.FormatPrice(product.TradePrice, false)' = (Put (Format-GbpPrice $product.TradePrice $false)) })
          } else {
            Sub $ib.ElseInner ($common + @{ '@product.ImageUrl(330)' = (& $image 330); '@product.ImageUrl(600)' = (& $image 600)
              '@(i < 3 ? "eager" : "lazy")' = $(if ($i -lt 3) { 'eager' } else { 'lazy' })
              '@HomeProduct.FormatPrice(product.Price, true)' = (Put (Format-GbpPrice $product.Price $true)); '@HomeProduct.FormatPrice(product.TradePrice, true)' = (Put (Format-GbpPrice $product.TradePrice $true)) })
          }
        }
      }) -join ''
    }
  }

  # the shared bulk enquiry pop-up (rendered by build.ps1)
  $h = Sub $h @{ '@Html.Partial("_BulkEnquiryModal", Model.EnquiryCategories)' = (Put $enquiryHtml) }

  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]')
  if ($m.Success) { throw "_CategoryPage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  [regex]::Replace($h, [string][char]2 + '(\d+)' + [char]3, { param($x) $values[[int]$x.Groups[1].Value] })
}
