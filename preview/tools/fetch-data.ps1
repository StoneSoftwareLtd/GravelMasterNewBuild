# Fetches real menu data and a sample old-page body from the live GravelMaster site, so the
# header/footer preview renders what _SiteHeader/_SiteMobileMenu would render in production.
# Run once (or again when categories/products change). Writes data.json and old-body.html here.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$site = 'https://www.gravelmaster.co.uk'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Get-Page([string]$path) {
  (Invoke-WebRequest -Uri ($site + $path) -UseBasicParsing -TimeoutSec 90).Content
}

$homePage = Get-Page '/'

# Top-level categories, in menu order (TopLevelCategories ordered by PriorityOnSubMenu), from the old header
$categories = New-Object System.Collections.ArrayList
$seen = @{}
foreach ($m in [regex]::Matches($homePage, '<a href="/([^"/]+)/products/" class="toplink[^"]*" title="([^"]+)"')) {
  $url = $m.Groups[1].Value
  if ($seen.ContainsKey($url)) { continue }
  $seen[$url] = $true
  [void]$categories.Add([ordered]@{ name = [Net.WebUtility]::HtmlDecode($m.Groups[2].Value); url = $url; idealFor = $null; subs = @() })
}

# Subcategories (their URLs sit under the parent category's URL)
foreach ($m in [regex]::Matches($homePage, '<a class="topLink" href="/([^"/]+)/([^"/]+)/products/" title="([^"]+)"')) {
  $parent = $categories | Where-Object { $_.url -eq $m.Groups[1].Value }
  if ($parent -and -not ($parent.subs | Where-Object { $_.url -eq $m.Groups[2].Value })) {
    $parent.subs += [ordered]@{ name = [Net.WebUtility]::HtmlDecode($m.Groups[3].Value); url = $m.Groups[2].Value }
  }
}

# Every live product (MasterLayoutViewModel.LiveProducts / LiveUrls, ordered by name)
$names = ([regex]::Match($homePage, 'var countries\s*=\s*(\[.*?\]);')).Groups[1].Value | ConvertFrom-Json
$urls  = ([regex]::Match($homePage, 'var urls\s*=\s*(\[.*?\]);')).Groups[1].Value | ConvertFrom-Json
if ($names.Count -ne $urls.Count -or $names.Count -eq 0) { throw "Product name/url lists don't line up ($($names.Count) vs $($urls.Count))" }
$products = for ($i = 0; $i -lt $names.Count; $i++) {
  $u = [regex]::Match($urls[$i], '^/products/([^/]+)/p/([^/]+)$')
  if ($u.Success) { [ordered]@{ name = $names[$i]; category = $u.Groups[1].Value; url = $u.Groups[2].Value } }
}

# Product tiles from the category pages: image, short description and customer/trade "From" prices
$tiles = [ordered]@{}
function Add-Tiles([string]$html) {
  foreach ($m in [regex]::Matches($html, '<div class="grid-list-block">([\s\S]*?)<span class="grid-price-shop">')) {
    $b = $m.Groups[1].Value
    $link = [regex]::Match($b, '<a href="/products/([^/"]+)/p/([^"]+)"')
    if (-not $link.Success -or $tiles.Contains($link.Groups[2].Value)) { continue }
    $price = { param($cls) ([regex]::Match($b, '<span class="grid-price ' + $cls + '">\s*(?:&#163;|£)([\d,.]+)')).Groups[1].Value }
    $tiles[$link.Groups[2].Value] = [ordered]@{
      category = $link.Groups[1].Value
      url      = $link.Groups[2].Value
      name     = [Net.WebUtility]::HtmlDecode(([regex]::Match($b, '<h2>([\s\S]*?)</h2>')).Groups[1].Value.Trim())
      image    = ([regex]::Match($b, 'data-src="([^"]+)"')).Groups[1].Value
      synopsis = [Net.WebUtility]::HtmlDecode(([regex]::Match($b, '<span class="synopsis">([\s\S]*?)</span>')).Groups[1].Value.Trim())
      price    = & $price 'cust-price'
      tradePrice = & $price 'trade-price'
    }
  }
}

# The homepage's banner slides (managed in the admin site)
$banners = @([regex]::Matches($homePage, '<li class="orange-border glide__slide">\s*<a href=''([^'']+)''>\s*<img[^>]*src=''([^'']+)''') |
  ForEach-Object { [ordered]@{ link = $_.Groups[1].Value; image = $_.Groups[2].Value } })

foreach ($c in $categories) {
  foreach ($s in @($c.subs) | Where-Object { $_ }) { Add-Tiles (Get-Page "/$($c.url)/$($s.url)/products/") }
}

# "Ideal for" heading from each category description (mirrors MasterLayoutViewModel.GetIdealFor)
foreach ($c in $categories) {
  $page = Get-Page "/$($c.url)/products/"
  Add-Tiles $page
  $m = [regex]::Match($page, '<h2[^>]*>\s*Ideal for:?(.*?)</h2>', 'IgnoreCase, Singleline')
  if ($m.Success) {
    $text = [regex]::Replace($m.Groups[1].Value, '<[^>]+>', ' ')
    $text = [Net.WebUtility]::HtmlDecode([regex]::Replace($text, '\s+', ' ')).Trim()
    if ($text.Length -gt 0) { $c.idealFor = $text }
  }
  if ($c.url -eq 'garden-chippings') { $sample = $page }
}

# The old site's stylesheets on that page (the new chrome has to sit on top of these)
$headEnd = $sample.IndexOf('</head>')
$stylesheets = [regex]::Matches($sample.Substring(0, $headEnd), '<link href="([^"]+)" rel="stylesheet"') |
  ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -notmatch 'fonts\.googleapis' } |
  ForEach-Object { if ($_.StartsWith('/')) { $site + $_ } else { $_ } }

$data = [ordered]@{ fetched = (Get-Date).ToString('yyyy-MM-dd HH:mm'); stylesheets = @($stylesheets); categories = $categories; products = @($products); tiles = @($tiles.Values); banners = $banners }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'data.json'), ($data | ConvertTo-Json -Depth 6), $utf8)

# Sample old page body (the Gravels & Chippings category page): #mainBody contents, scripts removed,
# root-relative links pointed at the live site so images and links resolve in the preview.
$start = $sample.IndexOf('id="mainBody"')
$start = $sample.IndexOf('>', $start) + 1
$end = $sample.IndexOf('<div class="modal fade show" id="priceModal"')
$body = $sample.Substring($start, $end - $start)
$body = $body.Substring(0, $body.LastIndexOf('</div>'))
$body = [regex]::Replace($body, '<script[\s\S]*?</script>', '', 'IgnoreCase')
$body = [regex]::Replace($body, '(\s(?:src|href|data-src|srcset|data-srcset)=")/(?!/)', "`$1$site/")
# lazy-loaded images: use the real address (data-src) in place of the blank placeholder (src="data:...")
$body = [regex]::Replace($body, '<img\b[^>]*\sdata-src="[^"]*"[^>]*>', [Text.RegularExpressions.MatchEvaluator] {
  param($m)
  $tag = [regex]::Replace($m.Value, '\ssrc="data:[^"]*"', '')
  [regex]::Replace($tag, '\sdata-src="', ' src="')
})
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'old-body.html'), $body, $utf8)

"categories: $($categories.Count); subcategories: $(($categories | ForEach-Object { $_.subs.Count } | Measure-Object -Sum).Sum); products: $(@($products).Count); product tiles: $($tiles.Count); banners: $($banners.Count); sample body: $($body.Length) chars"

# rebuild the preview pages so they use the new data
& (Join-Path $PSScriptRoot 'build.ps1')
