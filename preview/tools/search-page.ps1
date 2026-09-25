# The new search results page (Views/Category/_SearchPage.cshtml) for the previews. Dot-sourced by site-preview.ps1
# (localhost:8780/search?searchphrase=...), after category-page.ps1, whose tile reader and Razor helpers it uses.
#
#   ConvertFrom-OldSearchPage  reads an old search results page from the live site into what SearchPageModel holds
#   Format-SearchPage          renders _SearchPage.cshtml with it
#
# The markup comes from the .cshtml as it is: each Razor block is found in the file and filled in, and the render
# fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

$script:searchCategories = $null
# CategoryController's searches that always give Post Mix Concrete, whatever the product names say
$script:postMixKeywords = @('postmix', 'post mix', 'fence crete', 'fencecrete', 'fencing cement', 'cement', 'ce ment')

# $pageHtml is the whole old page (its autocomplete list is every product on sale), $mainHtml its content, $rawUrl
# the address it was asked for. Returns $null for a page it can't read.
function ConvertFrom-OldSearchPage([string]$pageHtml, [string]$mainHtml, [string]$rawUrl) {
  if ($mainHtml.IndexOf('id="grid-list"') -lt 0) { return $null }

  # what CategoryController.Search is given: the address's /search/<phrase>, or else ?searchphrase=
  $path = $rawUrl.Split('?')[0]
  $phrase = $null
  $inPath = [regex]::Match($path, '^/search/(.+)$', 'IgnoreCase')
  if ($inPath.Success) { $phrase = [Uri]::UnescapeDataString($inPath.Groups[1].Value) }
  else {
    $q = [regex]::Match($rawUrl, '[?&]searchphrase=([^&]*)', 'IgnoreCase')
    if ($q.Success) { $phrase = [Uri]::UnescapeDataString($q.Groups[1].Value.Replace('+', ' ')) }
  }

  # More matched than the one page of 100 the controller shows? It matches the names of the products on sale, which
  # _Layout lists for the autocomplete ("var countries = [...]")
  $hasMore = $false
  $list = [regex]::Match($pageHtml, 'var countries = (\[[\s\S]*?\]);')
  if ($list.Success -and $script:postMixKeywords -notcontains ("$phrase").ToLower()) {
    $needle = ("$phrase").ToLower()
    $names = $list.Groups[1].Value | ConvertFrom-Json   # a variable first: PowerShell 5.1 pipes the array as one item
    $hasMore = @($names | Where-Object { $_.ToLower().Contains($needle) }).Count -gt 100
  }

  # the top-level categories in menu order, as the new header shows them (data.json)
  if (-not $script:searchCategories) {
    $data = Get-Content -Raw (Join-Path $PSScriptRoot 'data.json') -Encoding UTF8 | ConvertFrom-Json
    $script:searchCategories = @($data.categories | ForEach-Object { [pscustomobject]@{ Name = $_.name; Url = "/$($_.url)/products/" } })
  }

  [pscustomobject]@{
    Phrase = $phrase
    Products = @(ConvertFrom-OldProductTiles $mainHtml)   # already in the old grid's order, without the turf
    HasMore = $hasMore
    Categories = $script:searchCategories
  }
}

function Format-SearchPage([string]$templatePath, $model) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments

  # the same working-out as the partial
  $phrase = ("$($model.Phrase)").Trim()
  $products = @($model.Products)
  $count = $products.Count
  $productsText = "$count " + $(if ($count -eq 1) { 'product' } else { 'products' })

  # Values go in as placeholders until the Razor check is done, so a search for "@home" can't look like Razor
  $values = New-Object Collections.ArrayList
  function Put([string]$html) { [void]$values.Add($html); [string][char]2 + ($values.Count - 1) + [char]3 }
  function Enc([string]$s) { Put ([Net.WebUtility]::HtmlEncode($s)) }
  function Sub([string]$text, [hashtable]$map) {
    foreach ($key in ($map.Keys | Sort-Object Length -Descending)) {
      if (-not $text.Contains($key)) { throw "Couldn't find $key in _SearchPage.cshtml" }
      $text = $text.Replace($key, $map[$key])
    }
    $text
  }

  $start = $src.IndexOf('<div class="gm-category gm-search"')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-category gm-search""> in _SearchPage.cshtml" }
  $h = $src.Substring($start)

  # heading and how many were found
  $h = Set-RazorBlock $h '@if \(phrase\.Length > 0\)\s*\{' { param($b) if ($phrase.Length -gt 0) { $b.Inner } else { $b.ElseInner } }
  $countText = if ($count -eq 0) { 'No products found' } elseif ($model.HasMore) { 'Showing the first ' + $productsText } else { $productsText + ' found' }
  $h = Sub $h @{ '@(count == 0 ? "No products found" : Model.HasMore ? "Showing the first " + productsText : productsText + " found")' = (Enc $countText) }

  # the cards
  $h = Set-RazorBlock $h '@if \(count > 0\)\s*\{' { param($b)
    if ($count -eq 0) { return '' }
    Set-RazorBlock $b.Inner '@for \(int i = 0; i < Model\.Products\.Count; i\+\+\)\s*\{' { param($lb)
      $card = Get-LoopMarkup $lb.Inner
      (0..($count - 1) | ForEach-Object {
        $i = $_; $product = $products[$i]
        $image = { param($size) Enc $product.ImageFormat.Replace('{0}', [string]$size) }
        Sub $card @{ '@product.Url' = (Enc $product.Url); '@product.Name' = (Enc $product.Name); '@product.Synopsis' = (Enc $product.Synopsis)
          '@product.ImageUrl(330)' = (& $image 330); '@product.ImageUrl(600)' = (& $image 600)
          '@(i < 4 ? "eager" : "lazy")' = $(if ($i -lt 4) { 'eager' } else { 'lazy' })
          '@HomeProduct.FormatPrice(product.Price, true)' = (Put (Format-GbpPrice $product.Price $true))
          '@HomeProduct.FormatPrice(product.TradePrice, true)' = (Put (Format-GbpPrice $product.TradePrice $true)) }
      }) -join ''
    }
  }

  # help when nothing, or not everything, is found
  $h = Set-RazorBlock $h '@if \(count == 0 \|\| Model\.HasMore\)\s*\{' { param($b)
    if ($count -gt 0 -and -not $model.HasMore) { return '' }
    $help = Set-RazorBlock $b.Inner '@if \(count == 0\)\s*\{' { param($ib)
      if ($count -eq 0) { Set-RazorBlock $ib.Inner '(?<!@)if \(phrase\.Length > 0\)\s*\{' { param($pb) if ($phrase.Length -gt 0) { $pb.Inner } else { $pb.ElseInner } } }
      else { Sub $ib.ElseInner @{ '@(phrase.Length > 0 ? "Add another word to narrow your search" : "Search for a product by name")' = (Enc $(if ($phrase.Length -gt 0) { 'Add another word to narrow your search' } else { 'Search for a product by name' })) } }
    }
    Set-RazorBlock $help '@foreach \(var category in Model\.Categories\)\s*\{' { param($lb)
      (@($model.Categories) | ForEach-Object { Sub $lb.Inner @{ '@category.Url' = (Enc $_.Url); '@category.Name' = (Enc $_.Name) } }) -join ''
    }
  }

  $h = $h.Replace('@phrase', (Enc $phrase))
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$|if\b)|(?:var|string|int) \w+ = )')
  if ($m.Success) { throw "_SearchPage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  [regex]::Replace($h, [string][char]2 + '(\d+)' + [char]3, { param($x) $values[[int]$x.Groups[1].Value] })
}
