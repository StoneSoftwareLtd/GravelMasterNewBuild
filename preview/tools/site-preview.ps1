# Local preview of the WHOLE GravelMaster website with the new header and footer: http://localhost:8780/
#
# Every page is fetched from www.gravelmaster.co.uk and its old header and footer are swapped for the
# new ones built from the package's .cshtml files - the same swap _Layout makes when UseNewChrome is on -
# so you can click around real pages and the new header and footer stay.
#
# The homepage, every category page (with or without filters) and every product page show the new homepage,
# category page and product page from Views/Home/_HomePage.cshtml, Views/Shared/_CategoryPage.cshtml and
# Views/Shared/_ProductPage.cshtml, filled from the live page. Product prices come from the live site's own
# price lookup, as they do on the real page. /about-us and /trade show the new About us and Trade Accounts pages (Views/Content/_AboutPage.cshtml and
# _TradePage.cshtml). /basket shows the new basket page (Views/Basket/_BasketPage.cshtml) with a sample basket, since
# no cookies reach the live site. /checkout/processorder shows the new checkout (Views/Checkout/_CheckoutPage.cshtml)
# for that sample basket, in the live basket page's frame (the live site sends a checkout with no basket back to
# /basket); Continue to payment is blocked like every other form.
#
# It is read-only, so nothing reaches the real website except page views and read-only lookups:
#   - adding to basket, sign-ups, enquiries and every form post are blocked, except a category page's
#     Sort by (only "sort=<one of the four sorts>"), which only changes the order of the products
#   - no cookies are sent, so you are never logged in or using a real basket
#   - analytics, ads, Hotjar, Clarity, Facebook and chat scripts are removed from the pages
#
# Saving gm-chrome.css, gm-chrome.js, a gm-* image or a .cshtml file rebuilds the new header and footer
# if needed and reloads any open preview page.
#
# Like the real site's switch, add ?newchrome=0 to any address to see the old header and footer
# instead (it sticks while you click around) and ?newchrome=1 to go back to the new ones.
param(
  [int]$Port = 8780,
  [switch]$NoBrowser
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$site = 'https://www.gravelmaster.co.uk'
$package = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\Website\Website')).Path
$fragments = Join-Path $PSScriptRoot 'fragments'
$utf8 = New-Object System.Text.UTF8Encoding $false
. (Join-Path $PSScriptRoot 'category-page.ps1')
. (Join-Path $PSScriptRoot 'product-page.ps1')
. (Join-Path $PSScriptRoot 'about-page.ps1')
. (Join-Path $PSScriptRoot 'trade-page.ps1')
. (Join-Path $PSScriptRoot 'basket-page.ps1')
. (Join-Path $PSScriptRoot 'checkout-page.ps1')
# a category page: /garden-chippings/products/, /garden-chippings/slate-chippings/products/, and either with filters after
$categoryPathPattern = '^/(?!products/)[a-z0-9-]+(?:/[a-z0-9-]+)?/products(?:/|$)'

# Requests with real effects on the live site (found in the live pages' scripts and forms)
$blockedPattern = 'addtobasket|removefrombasket|updatequantity|updatebasket|applycouponcode|newsletterregister|sendlooseenquiry|sendcalculatorcalculation|quicksignup|logoff|logout'
# Scripts removed from preview pages so visits aren't counted or recorded
$trackerPattern = 'googletagmanager\.com|cookie-script\.com|static\.hotjar\.com|fbevents\.js|facebook\.com/tr\?|clarity\.ms|bat\.bing\.com|embed\.tawk\.to'
# Stand-ins for the removed scripts, so page code that calls them doesn't throw
$trackerStub = '<script>/* preview: analytics removed */ window.dataLayer = window.dataLayer || []; window.gtag = function () {}; window.fbq = function () {}; window.uetq = window.uetq || []; window.hj = function () {}; window.clarity = function () {};</script>'
$reloadScript = @'
<script>/* preview: keep links added by page scripts inside the preview (links in the page are rewritten already) */
["click", "auxclick"].forEach(function (type) {
  document.addEventListener(type, function (e) {
    var link = e.target.closest ? e.target.closest("a[href]") : null;
    if (!link || !/^(www\.)?gravelmaster\.co\.uk$/i.test(link.hostname)) return;
    link.href = location.origin + link.pathname + link.search + link.hash;
  }, true);
});
</script>
<script>/* preview: reload when the new header/footer files change */
(function () {
  var last = null;
  function poll() {
    fetch('/__preview/changes', { cache: 'no-store' })
      .then(function (r) { return r.text(); })
      .then(function (t) { if (last !== null && t !== last) location.reload(); last = t; })
      .catch(function () {})
      .then(function () { setTimeout(poll, 1500); });
  }
  poll();
})();
</script>
'@
$blockedPage = [Text.Encoding]::UTF8.GetBytes(@'
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>[Preview] Not available</title></head>
<body style="font-family:'Segoe UI',Arial,sans-serif;max-width:640px;margin:60px auto;padding:0 16px;color:#333">
<h1 style="font-size:22px">Not available in the preview</h1>
<p>The preview only shows pages. Adding to basket, sign-ups, enquiries and forms are switched off, so nothing is sent to the real website.</p>
<p><a href="javascript:history.back()">Go back</a></p>
</body></html>
'@)

$script:chrome = $null
$staticCache = @{}

function Update-Chrome {
  $stamp = Join-Path $fragments 'built.txt'
  $inputs = @(Get-ChildItem -LiteralPath (Join-Path $package 'Views\Shared') -Filter '*.cshtml') +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'Views\Home') -Filter '*.cshtml' -ErrorAction SilentlyContinue) +
    @(Get-Item -LiteralPath (Join-Path $PSScriptRoot 'data.json'), (Join-Path $PSScriptRoot 'build.ps1'), (Join-Path $PSScriptRoot 'category-page.ps1'))
  $newest = $inputs | ForEach-Object { $_.LastWriteTimeUtc } | Sort-Object -Descending | Select-Object -First 1
  $upToDate = (Test-Path -LiteralPath $stamp) -and (Get-Item -LiteralPath $stamp).LastWriteTimeUtc -ge $newest
  if ($upToDate -and $script:chrome) { return }
  if (-not $upToDate) { & (Join-Path $PSScriptRoot 'build.ps1') | ForEach-Object { Write-Host $_ } }
  function Read-Fragment([string]$name) { [IO.File]::ReadAllText((Join-Path $fragments $name)) }
  $script:chrome = @{
    Head = Read-Fragment 'head.html'; Header = Read-Fragment 'header.html'; HeaderCheckout = Read-Fragment 'header-checkout.html'
    Footer = Read-Fragment 'footer.html'; MobileMenu = Read-Fragment 'mobile-menu.html'; Scripts = Read-Fragment 'scripts.html'
    Autocomplete = Read-Fragment 'autocomplete.js'; AutocompleteInit = Read-Fragment 'autocomplete-init.js'
    Home = $(if (Test-Path -LiteralPath (Join-Path $fragments 'home.html')) { Read-Fragment 'home.html' } else { $null })
    Enquiry = Read-Fragment 'enquiry.html'
  }
}

function Get-ChangeStamp {
  $files = @(Get-ChildItem -LiteralPath (Join-Path $package 'Views\Shared') -Filter '*.cshtml') +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'Views\Home') -Filter '*.cshtml' -ErrorAction SilentlyContinue) +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'Views\Content') -Filter '*.cshtml' -ErrorAction SilentlyContinue) +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'Views\Basket') -Filter '*.cshtml' -ErrorAction SilentlyContinue) +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'Views\Checkout') -Filter '*.cshtml' -ErrorAction SilentlyContinue) +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'css') -Filter 'gm-*') +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'js') -Filter 'gm-*') +
    @(Get-ChildItem -LiteralPath (Join-Path $package 'img') -Filter 'gm-*')
  "{0}-{1}" -f $files.Count, ($files | ForEach-Object { $_.LastWriteTimeUtc.Ticks } | Sort-Object -Descending | Select-Object -First 1)
}

# $formBody: a form post's body (only a category page's Sort by is ever passed on)
function Get-Live([string]$rawUrl, [string]$accept, [string]$formBody) {
  $req = [Net.HttpWebRequest]::Create($site + $rawUrl)
  $req.Method = 'GET'
  $req.AllowAutoRedirect = $false
  $req.AutomaticDecompression = [Net.DecompressionMethods]'GZip, Deflate'
  $req.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) GravelMasterHeaderPreview'
  if ($accept) { $req.Accept = $accept }
  $req.Timeout = 30000
  if ($formBody) {
    $req.Method = 'POST'
    $req.ContentType = 'application/x-www-form-urlencoded'
    $bytes = [Text.Encoding]::UTF8.GetBytes($formBody)
    $req.ContentLength = $bytes.Length
    $stream = $req.GetRequestStream()
    try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Close() }
  }
  try {
    $res = $req.GetResponse()
  } catch {
    $we = $_.Exception
    while ($we -and -not ($we -is [Net.WebException])) { $we = $we.InnerException }
    if ($we -and $we.Response) { $res = $we.Response } else { throw }
  }
  try {
    $ms = New-Object IO.MemoryStream
    $res.GetResponseStream().CopyTo($ms)
    [pscustomobject]@{ Status = [int]$res.StatusCode; ContentType = $res.ContentType; Location = $res.Headers['Location']; Body = $ms.ToArray() }
  } finally {
    $res.Close()
  }
}

# $sort: the Sort by choice posted to a category page, if any
function Convert-Page([string]$html, [string]$rawUrl, [bool]$useNewChrome, [string]$sort) {
  # _Layout: bool isCheckout = Request.Url.ToString().Contains("checkout")
  $isCheckout = $rawUrl.Contains('checkout')
  $swapped = $false
  $newPage = $null

  $footStart = $html.IndexOf('<div id="sign-up-wrapper">')
  $footEnd = if ($footStart -ge 0) { $html.IndexOf('</footer>', $footStart) } else { -1 }
  $header = [regex]::Match($html, '<header class="sticky">[\s\S]*?</header>')
  if ($useNewChrome -and $header.Success -and $footEnd -gt $footStart) {
    # old newsletter band + footer (which holds the Track Order modal) -> _SiteFooter, _TrackOrderModal, _SiteMobileMenu, gm-chrome.js
    $newFooter = $chrome.Footer + "`n" + $(if ($isCheckout) { '' } else { $chrome.MobileMenu + "`n" }) + $chrome.Scripts
    $html = $html.Substring(0, $footStart) + $newFooter + $html.Substring($footEnd + '</footer>'.Length)
    # old header -> _SiteHeader
    $html = $html.Substring(0, $header.Index) + $(if ($isCheckout) { $chrome.HeaderCheckout } else { $chrome.Header }) + $html.Substring($header.Index + $header.Length)
    # fonts and gm-chrome.css, where _Layout puts them
    $html = [regex]::Replace($html, '<link href="https://fonts\.googleapis\.com/css2\?family=Quicksand:wght@400&display=swap" rel="stylesheet"\s*/?>', '')
    $icons = $html.IndexOf('<link rel="apple-touch-icon"')
    $at = if ($icons -ge 0) { $icons } else { $html.IndexOf('</head>') }
    $html = $html.Insert($at, $chrome.Head + "`n")
    # _Layout's search autocomplete (with the Enter fix) and its null-safe start-up
    $html = [regex]::Replace($html, 'function autocomplete\(inp, arr\) \{[\s\S]*?(?=\r?\n\s*</script>)', [Text.RegularExpressions.MatchEvaluator] { param($m) $chrome.Autocomplete })
    $html = [regex]::Replace($html, 'autocomplete\(document\.getElementById\("myInput"\), countries\);\s*autocomplete\(document\.getElementById\("myInput2"\), countries\);', [Text.RegularExpressions.MatchEvaluator] { param($m) $chrome.AutocompleteInit })
    $swapped = $true

    # the new homepage (Views/Home/_HomePage.cshtml) or category page (Views/Shared/_CategoryPage.cshtml)
    # in place of the old page's content
    $path = $rawUrl.Split('?')[0]
    $mainBody = [regex]::Match($html, '<div itemscope itemtype="http://schema.org/WebSite" id="mainBody"[^>]*>')
    $modal = $html.IndexOf('<div class="modal fade show" id="priceModal"')
    $mainEnd = if ($modal -gt 0) { $html.LastIndexOf('</div>', $modal) } else { -1 }
    $content = $null
    $extraHead = $null
    if ($mainBody.Success -and $mainEnd -gt $mainBody.Index) {
      if ($chrome.Home -and $path -eq '/') {
        $content = $chrome.Home; $css = '/css/gm-home.css?v1'; $newPage = 'new homepage'
      }
      elseif ($path -match $categoryPathPattern) {
        $model = ConvertFrom-OldCategoryPage $html.Substring($mainBody.Index, $mainEnd - $mainBody.Index) $path $sort @()
        if ($model) {
          $content = Format-CategoryPage (Join-Path $package 'Views\Shared\_CategoryPage.cshtml') $model $chrome.Enquiry
          $css = '/css/gm-category.css?v1'; $newPage = 'new category page'
        }
      }
      elseif ($path -match $script:productPathPattern) {
        $model = ConvertFrom-OldProductPage $html.Substring($mainBody.Index, $mainEnd - $mainBody.Index) $path
        if ($model) {
          $content = Format-ProductPage (Join-Path $package 'Views\Shared\_ProductPage.cshtml') $model $chrome.Enquiry
          $css = '/css/gm-product.css?v1'; $newPage = 'new product page'
        }
      }
      elseif ($path -match '^/about-us/?$') {
        $content = Format-AboutPage (Join-Path $package 'Views\Content\_AboutPage.cshtml')
        $css = '/css/gm-about.css?v1'; $newPage = 'new about page'
        $extraHead = '<link href="https://fonts.googleapis.com/css2?family=Caveat:wght@600&display=swap" rel="stylesheet" />'
      }
      elseif ($path -match '^/trade/?$') {
        $content = Format-TradePage (Join-Path $package 'Views\Content\_TradePage.cshtml')
        $css = '/css/gm-trade.css?v1'; $newPage = 'new trade page'
      }
      elseif ($path -match '^/basket(/index)?/?$') {
        # No cookies reach the live site, so its basket is always empty: show a sample one instead.
        # ?empty=1, ?voucher=1 and ?discount=1 show the empty basket, a voucher message and the discount rows.
        $flags = @('empty', 'voucher', 'discount' | Where-Object { $rawUrl -match "[?&]$_=1(&|$)" })
        $sample = Get-SampleBasket $flags
        $notice = '<p style="margin:0;padding:8px 18px;background:#fff4d6;color:#4a3b00;font:600 14px/1.4 Quicksand,Arial,sans-serif;text-align:center">Preview: ' +
          $(if ($flags -contains 'empty') { 'an empty basket' } else { 'a sample basket of real products at their live prices. The preview can''t use a real basket, so changes to it are blocked' }) +
          '. Try <a href="/basket">sample</a>, <a href="/basket?empty=1">empty</a> or <a href="/basket?voucher=1&amp;discount=1">with a voucher</a>.</p>'
        $content = $notice + (Format-BasketPage (Join-Path $package 'Views\Basket\_BasketPage.cshtml') $sample)
        $css = '/css/gm-basket.css?v1'; $newPage = 'new basket page'
        $extraHead = '<link href="https://fonts.googleapis.com/css2?family=Caveat:wght@600&display=swap" rel="stylesheet" />'
      }
      elseif ($path -match '^/checkout/processorder/?$') {
        # The live basket page's frame (see the main loop) with a sample checkout for the sample basket.
        # ?samples=1, ?preorder=1, ?mixed=1, ?simple=1 and ?notimes=1 show the other kinds of delivery; ?area=PO a
        # postcode area without Saturdays (and where the Isle of Wight is)
        $flags = @('samples', 'preorder', 'mixed', 'simple', 'notimes' | Where-Object { $rawUrl -match "[?&]$_=1(&|$)" })
        $areaMatch = [regex]::Match($rawUrl, '[?&]area=([A-Za-z]{1,2})(&|$)')
        $area = if ($areaMatch.Success) { $areaMatch.Groups[1].Value.ToUpperInvariant() } else { 'NG' }
        $sample = Get-SampleCheckout $flags $area
        $q = if ($area -ne 'NG') { "area=$area&amp;" } else { '' }
        $notice = '<p style="margin:0;padding:8px 18px;background:#fff4d6;color:#4a3b00;font:600 14px/1.5 Quicksand,Arial,sans-serif;text-align:center">Preview: a sample checkout for the sample basket, with sample delivery dates and prices (the real ones come from the site''s settings) and the basket priced for ' + $area + ' postcodes. Nothing is sent: Continue to payment is blocked. Try ' +
          '<a href="/checkout/processorder">dates</a>, <a href="/checkout/processorder?' + $q + 'samples=1">samples</a>, <a href="/checkout/processorder?' + $q + 'preorder=1">pre-order</a>, <a href="/checkout/processorder?' + $q + 'mixed=1">mixed pre-order</a>, <a href="/checkout/processorder?' + $q + 'simple=1">no date step</a>, <a href="/checkout/processorder?' + $q + 'notimes=1">no morning slot</a> or <a href="/checkout/processorder?area=PO">PO postcodes</a>.</p>'
        $content = $notice + (Format-CheckoutPage (Join-Path $package 'Views\Checkout\_CheckoutPage.cshtml') $sample)
        $css = '/css/gm-checkout.css?v1'; $newPage = 'new checkout'
      }
    }
    if ($content) {
      # full width, without the old white box and orange side borders
      $html = $html.Substring(0, $mainBody.Index) + '<div itemscope itemtype="http://schema.org/WebSite" id="mainBody"><meta itemprop="url" content="https://www.gravelmaster.co.uk" />' + $content + "`n" + $html.Substring($mainEnd)
      $head = $html.IndexOf('<link href="/css/gm-chrome.css')
      if ($head -ge 0) { $html = $html.Insert($head, $(if ($extraHead) { $extraHead + "`n" } else { '' }) + "<link href=""$css"" rel=""stylesheet"" />`n") }
      # The old product page's script works its own markup, which is gone: load the site's default page
      # script instead, as Detail.cshtml will when the new page shows (docs/merging.md)
      if ($newPage -eq 'new product page') {
        $html = [regex]::Replace($html, 'require\(\["/scripts/Controllers/Root/Product/Detail\.js[^"]*"\]\)', 'require(["/scripts/Controllers/Root/Content/Display.js"])')
      }
      # The same for the basket: Basket/Index.js calls the old page's own functions (onJqueryLoaded)
      if ($newPage -eq 'new basket page') {
        $html = [regex]::Replace($html, 'require\(\["/scripts/Controllers/Root/Basket/Index\.js[^"]*"\]\)', 'require(["/scripts/Controllers/Root/Content/Display.js"])')
      }
      # The checkout is shown in the basket page's frame: give it the checkout's script (as ProcessOrder.cshtml will:
      # the old ProcessOrder.js works the old form), title, and no cookie bar (_Layout leaves it off checkout pages)
      if ($newPage -eq 'new checkout') {
        $html = [regex]::Replace($html, 'require\(\["/scripts/Controllers/Root/Basket/Index\.js[^"]*"\]\)', 'require(["/scripts/Controllers/Root/Content/Display.js"])')
        $html = [regex]::Replace($html, '<link href="/css/cookiebar\.min\.css" rel="stylesheet"\s*/?>|<script type="text/javascript" src="/scripts/cookiebar\.min\.js"></script>', '')
        $html = [regex]::Replace($html, '<title>[\s\S]*?</title>', '<title>GravelMaster | Checkout</title>')
      }
    }
  }

  # analytics, ads, recordings and chat
  $html = [regex]::Replace($html, '<script\b[^>]*>[\s\S]*?</script>', [Text.RegularExpressions.MatchEvaluator] { param($m) if ($m.Value -match $trackerPattern -or $m.Value -match "gtag\('config'") { '' } else { $m.Value } })
  $html = [regex]::Replace($html, '<noscript>[\s\S]*?</noscript>', [Text.RegularExpressions.MatchEvaluator] { param($m) if ($m.Value -match $trackerPattern) { '' } else { $m.Value } })
  $head = [regex]::Match($html, '<head[^>]*>')
  if ($head.Success) { $html = $html.Insert($head.Index + $head.Length, "`n" + $trackerStub) }

  # keep links to the live site inside the preview
  $html = [regex]::Replace($html, '(\s(?:href|action)\s*=\s*["''])https?://(?:www\.)?gravelmaster\.co\.uk/', '$1/', 'IgnoreCase')
  $html = [regex]::Replace($html, '(\s(?:href|action)\s*=\s*["''])https?://(?:www\.)?gravelmaster\.co\.uk(?=["''])', '$1/', 'IgnoreCase')

  $html = ([regex]'(?i)<title>').Replace($html, '<title>[Preview] ', 1)   # the page title only, not SVG titles
  $bodyEnd = $html.LastIndexOf('</body>')
  if ($bodyEnd -ge 0) { $html = $html.Insert($bodyEnd, $reloadScript) }
  [pscustomobject]@{ Html = $html; Swapped = $swapped; NewPage = $newPage }
}

function Send-Response($res, [int]$status, [string]$contentType, [byte[]]$body, [bool]$withBody) {
  $res.StatusCode = $status
  if ($contentType) { $res.ContentType = $contentType }
  $res.Headers.Add('Cache-Control', 'no-store')
  if ($withBody -and $body) {
    $res.ContentLength64 = $body.Length
    $res.OutputStream.Write($body, 0, $body.Length)
  }
}

# Already running (e.g. started automatically when the folder opened)? Then just open it.
try {
  $probe = [Net.HttpWebRequest]::Create("http://localhost:$Port/__preview/changes")
  $probe.Timeout = 3000
  $probe.GetResponse().Close()
  Write-Host "The website preview is already running: http://localhost:$Port/"
  if (-not $NoBrowser) { Start-Process "http://localhost:$Port/" }
  exit 0
} catch {}

Update-Chrome
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() } catch { Write-Host "Couldn't start the preview on port $Port - is it already running? ($($_.Exception.Message))" -ForegroundColor Red; exit 1 }
Write-Host "GravelMaster preview with the new header and footer: http://localhost:$Port/"
Write-Host "Read-only: basket, sign-ups, enquiries and forms are blocked (only Sort by on category pages goes through). Press Ctrl+C to stop."
if (-not $NoBrowser) { Start-Process "http://localhost:$Port/" }

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  $path = $req.Url.AbsolutePath
  $withBody = $req.HttpMethod -ne 'HEAD'
  $note = ''

  # ?newchrome=0 / ?newchrome=1 picks the old or new header and footer and is remembered in a cookie;
  # the parameter itself is not passed on to the live site
  $choice = [regex]::Match($req.Url.Query, '[?&]newchrome=([01])(?:&|$)')
  $query = @($req.Url.Query.TrimStart('?').Split('&') | Where-Object { $_ -and $_ -notmatch '^newchrome=' })
  $rawUrl = $req.Url.AbsolutePath + $(if ($query.Count) { '?' + ($query -join '&') } else { '' })
  if ($choice.Success) {
    $useNewChrome = $choice.Groups[1].Value -eq '1'
    $res.AppendCookie((New-Object Net.Cookie 'gm-preview-newchrome', $choice.Groups[1].Value, '/'))
  } else {
    $useNewChrome = -not ($req.Cookies['gm-preview-newchrome'] -and $req.Cookies['gm-preview-newchrome'].Value -eq '0')
  }
  try {
    if ($path -eq '/__preview/changes') {
      Send-Response $res 200 'text/plain' ([Text.Encoding]::UTF8.GetBytes((Get-ChangeStamp))) $withBody
      continue
    }
    # A category page's Sort by is the one form post passed on, and only as exactly "sort=<one of the sorts>"
    $sort = $null
    if ($req.HttpMethod -eq 'POST' -and $path -match $categoryPathPattern -and $rawUrl -notmatch $blockedPattern) {
      $reader = New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)
      $posted = [regex]::Match($reader.ReadToEnd(), '^sort=([^&=]*)$')
      $reader.Close()
      if ($posted.Success) {
        $value = [Uri]::UnescapeDataString($posted.Groups[1].Value.Replace('+', ' '))
        if ($script:categorySortOptions -contains $value) { $sort = $value }
      }
    }
    if ($sort) {
      $live = Get-Live $rawUrl 'text/html' ('sort=' + [Uri]::EscapeDataString($sort))
      if ($live.Status -eq 200 -and $live.ContentType -and $live.ContentType.StartsWith('text/html')) {
        Update-Chrome
        $page = Convert-Page ($utf8.GetString($live.Body)) $rawUrl $useNewChrome $sort
        Send-Response $res 200 'text/html; charset=utf-8' ($utf8.GetBytes($page.Html)) $withBody
        $note = "sorted by $sort" + $(if ($page.NewPage) { " ($($page.NewPage))" } else { '' })
      } else {
        Send-Response $res 502 'text/plain; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes("The live site answered the sort with $($live.Status)")) $true
        $note = "sort failed: $($live.Status)"
      }
    }
    elseif ($req.HttpMethod -ne 'GET' -and $req.HttpMethod -ne 'HEAD') {
      Send-Response $res 403 'text/html; charset=utf-8' $blockedPage $true
      $note = 'blocked (read-only preview)'
    }
    elseif ($rawUrl -match $blockedPattern) {
      Send-Response $res 403 'text/html; charset=utf-8' $blockedPage $withBody
      $note = 'blocked (read-only preview)'
    }
    elseif ($path -match '^/(css|js|img)/gm-[^/]+$') {
      # the new header/footer's own files, straight from the package
      $file = Join-Path $package ($path.TrimStart('/') -replace '/', '\')
      if (Test-Path -LiteralPath $file -PathType Leaf) {
        $types = @{ '.css' = 'text/css'; '.js' = 'text/javascript'; '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.jpeg' = 'image/jpeg'; '.svg' = 'image/svg+xml' }
        $ext = [IO.Path]::GetExtension($file).ToLower()
        Send-Response $res 200 $types[$ext] ([IO.File]::ReadAllBytes($file)) $withBody
        $note = 'package'
      } else {
        Send-Response $res 404 'text/plain' ([Text.Encoding]::UTF8.GetBytes('Not in the package')) $withBody
        $note = 'not in package'
      }
    }
    elseif ($path -match '\.(png|jpe?g|gif|svg|webp|ico|js)$') {
      # images and scripts load straight from the live site
      $res.Redirect($site + $rawUrl)
      $note = 'from live site'
    }
    elseif ($staticCache.ContainsKey($rawUrl)) {
      $hit = $staticCache[$rawUrl]
      Send-Response $res 200 $hit.ContentType $hit.Body $withBody
      $note = 'cached'
    }
    else {
      # The live checkout sends a visitor with no basket back to /basket, and the preview has no basket, so the
      # sample checkout is shown in the live basket page's frame (the same layout, which gets the checkout header
      # here because the address has "checkout" in it, as _Layout decides)
      $fetchUrl = if ($path -match '^/checkout/processorder/?$') { '/basket' } else { $rawUrl }
      $live = Get-Live $fetchUrl $req.Headers['Accept']
      if ($live.Status -ge 300 -and $live.Status -lt 400 -and $live.Location) {
        $res.StatusCode = $live.Status
        $res.RedirectLocation = [regex]::Replace($live.Location, '^https?://(?:www\.)?gravelmaster\.co\.uk(?=/|$)', '', 'IgnoreCase')
        if (-not $res.RedirectLocation) { $res.RedirectLocation = '/' }
        $note = "redirect -> $($res.RedirectLocation)"
      }
      elseif ($live.ContentType -and $live.ContentType.StartsWith('text/html')) {
        Update-Chrome
        $page = Convert-Page ($utf8.GetString($live.Body)) $rawUrl $useNewChrome $null
        Send-Response $res $live.Status 'text/html; charset=utf-8' ($utf8.GetBytes($page.Html)) $withBody
        $note = if ($page.NewPage) { "new header and footer, $($page.NewPage)" } elseif ($page.Swapped) { 'new header and footer' } elseif (-not $useNewChrome) { 'old header and footer (newchrome=0)' } else { 'page left as it is (no old header/footer found)' }
      }
      else {
        Send-Response $res $live.Status $live.ContentType $live.Body $withBody
        if ($live.Status -eq 200 -and ($path -match '\.(css|woff2?|ttf|eot|otf)$' -or $path.StartsWith('/Content/') -or $path.StartsWith('/fonts/'))) {
          $staticCache[$rawUrl] = $live
        }
      }
    }
  } catch {
    Write-Host "  error for $rawUrl : $($_.Exception.Message)" -ForegroundColor Red
    try { Send-Response $res 502 'text/plain; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes("Preview error: $($_.Exception.Message)")) $true } catch {}
    $note = 'error'
  } finally {
    try { $res.Close() } catch {}
    if ($path -ne '/__preview/changes') { Write-Host ("{0} {1} {2} {3}" -f (Get-Date).ToString('HH:mm:ss'), $req.HttpMethod, $rawUrl, $note) }
  }
}
