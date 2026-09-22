# Builds static preview pages of the new GravelMaster header/footer straight from the Razor files in
# the package, with real menu data (data.json, from fetch-data.ps1) on top of the live site's
# stylesheets and a real old page body (old-body.html).
#
# Static markup is taken from the .cshtml files as-is; only the Razor loops that build the category
# menus are re-implemented below. If those loops change in _SiteHeader/_SiteMobileMenu, update them here.
# The build fails if any Razor is left over, so the preview can't silently drift from the partials.
#
#   preview/index.html     the new homepage (Views/Home/_HomePage.cshtml) with the new chrome
#   preview/category.html  the new category page (Views/Shared/_CategoryPage.cshtml), filled from the saved
#                          old Gravels & Chippings page (old-body.html) by category-page.ps1
#   preview/checkout.html  the checkout variant (no search, category nav or mobile menu)
#
# The pages load /css, /js and /img from the package (see .vscode/settings.json for Live Server).
#   build.ps1          build once
#   build.ps1 -Watch   build, then rebuild whenever a .cshtml file under Views is saved
param(
  [string]$Package = (Join-Path $PSScriptRoot '..\..\Website\Website'),
  [switch]$Watch
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding $false
$out = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$Package = (Resolve-Path -LiteralPath $Package).Path

function Read-Package([string]$rel) { [IO.File]::ReadAllText((Join-Path $Package $rel)) }
function Enc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
function Remove-RazorComments([string]$s) { [regex]::Replace($s, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '') }
function Get-Between([string]$s, [string]$startPattern, [string]$endLiteral, [string]$what) {
  $m = [regex]::Match($s, $startPattern)
  if (-not $m.Success) { throw "Couldn't find the start of $what" }
  $end = $s.IndexOf($endLiteral, $m.Index)
  if ($end -lt 0) { throw "Couldn't find the end of $what" }
  $s.Substring($m.Index, $end + $endLiteral.Length - $m.Index)
}
function Replace-Block([string]$text, [string]$startPattern, [string]$replacement, [string]$what) {
  # replaces a Razor block from its start (e.g. "@foreach (...)") to its matching closing brace
  $m = [regex]::Match($text, $startPattern)
  if (-not $m.Success) { throw "Couldn't find $what" }
  $open = $text.IndexOf('{', $m.Index)   # the block's own opening brace (the first one in the match)
  $depth = 0
  for ($i = $open; $i -lt $text.Length; $i++) {
    if ($text[$i] -eq '{') { $depth++ } elseif ($text[$i] -eq '}') { $depth--; if ($depth -eq 0) { break } }
  }
  $text.Substring(0, $m.Index) + $replacement + $text.Substring($i + 1)
}
function Assert-NoRazor([string]$what, [string]$s) {
  $m = [regex]::Match($s, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]')
  if ($m.Success) { throw "$what still contains Razor near: " + $s.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $s.Length - [Math]::Max(0, $m.Index - 80))) }
}
. (Join-Path $PSScriptRoot 'category-page.ps1')

# The saved pages are one page each, so their links open the same address in the whole-website preview
# (site-preview.ps1) instead of the live site, which still has the old header and footer.
$stayInPreviewScript = @'
<script>/* preview: open links in the whole-website preview, not the live site */
(function () {
  var previewSite = 'http://localhost:8780';
  var liveSite = /^(www\.)?gravelmaster\.co\.uk$/i;

  function previewAddress(url) {
    var u = new URL(url, location.href);
    var sameSite = u.origin === location.origin && !/\.html$/i.test(u.pathname);
    if (!sameSite && !liveSite.test(u.hostname)) return null;
    return previewSite + u.pathname + u.search + u.hash;
  }

  function showHelp() {
    if (document.getElementById('preview-help')) return;
    var box = document.createElement('div');
    box.id = 'preview-help';
    box.setAttribute('role', 'dialog');
    box.style.cssText = 'position:fixed;inset:0;z-index:2147483647;background:rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;padding:16px;font:16px/1.5 "Segoe UI",Arial,sans-serif';
    box.innerHTML = '<div style="background:#fff;color:#222;max-width:520px;border-radius:8px;padding:24px 28px">' +
      '<h2 style="margin:0 0 10px;font-size:20px;color:#222">Start the website preview first</h2>' +
      '<p style="margin:0 0 10px">This is one saved page. Other pages open in the whole-website preview, which shows every page with the new header and footer, but it isn\'t running.</p>' +
      '<p style="margin:0 0 16px">Double-click <b>Start website preview.cmd</b> in the repository folder (or in VS Code: <b>Terminal &gt; Run Task &gt; "Preview: open the whole website with the new header and footer"</b>), then click the link again.</p>' +
      '<button type="button" style="font:inherit;padding:8px 18px;border:0;border-radius:6px;background:#5ca458;color:#fff;cursor:pointer">OK</button></div>';
    box.querySelector('button').addEventListener('click', function () { box.remove(); });
    document.body.appendChild(box);
  }

  // postForm: a form to post to the address instead of opening it (e.g. Sort by)
  function go(address, postForm) {
    // Windows takes about 2 seconds to report that nothing is running, so say what's happening meanwhile
    var note = document.getElementById('preview-opening') || document.createElement('div');
    note.id = 'preview-opening';
    note.textContent = 'Opening in the website preview\u2026';
    note.style.cssText = 'position:fixed;left:50%;bottom:24px;transform:translateX(-50%);z-index:2147483647;background:#222;color:#fff;padding:10px 18px;border-radius:20px;font:14px "Segoe UI",Arial,sans-serif';
    document.body.appendChild(note);
    fetch(previewSite + '/__preview/changes', { mode: 'no-cors', cache: 'no-store' })
      .then(function () {
        if (!postForm) { location.href = address; return; }
        postForm.action = address;
        postForm.submit();
      })
      .catch(function () { note.remove(); showHelp(); });
  }

  document.addEventListener('click', function (e) {
    var link = e.target.closest ? e.target.closest('a[href]') : null;
    if (!link || e.defaultPrevented) return;
    var href = link.getAttribute('href');
    if (!href || href.charAt(0) === '#' || /^(javascript|mailto|tel):/i.test(href)) return;
    var address = previewAddress(link.href);
    if (!address) return;
    e.preventDefault();
    go(address);
  }, true);

  document.addEventListener('submit', function (e) {
    var form = e.target;
    if (!form.getAttribute('action')) return;
    var address = previewAddress(form.action);
    if (!address) return;
    e.preventDefault();
    if ((form.method || 'get').toLowerCase() === 'get') {
      go(address.split('?')[0] + '?' + new URLSearchParams(new FormData(form)).toString());
    } else {
      go(address, form);
    }
  }, true);
})();
</script>
'@

function Invoke-Build {
  $data = Get-Content -Raw (Join-Path $PSScriptRoot 'data.json') -Encoding UTF8 | ConvertFrom-Json
  $categories = @($data.categories)

  # MasterLayoutViewModel.GetMenuProducts: a category's products, one per product URL
  function Get-MenuProducts([string]$categoryUrl) {
    $seen = @{}
    foreach ($p in $data.products) {
      if ($p.category -eq $categoryUrl -and -not $seen.ContainsKey($p.url)) { $seen[$p.url] = $true; $p }
    }
  }

  # ---------- _SiteHeader.cshtml ----------
  $headerSrc = Read-Package 'Views\Shared\_SiteHeader.cshtml'
  function Get-Dictionary([string]$name) {
    $block = [regex]::Match($headerSrc, "var $name = new Dictionary<string, string>[^{]*\{([\s\S]*?)\};").Groups[1].Value
    $d = @{}
    foreach ($m in [regex]::Matches($block, '\{\s*"([^"]+)",\s*"([^"]+)"\s*\}')) { $d[$m.Groups[1].Value] = $m.Groups[2].Value }
    if ($d.Count -eq 0) { throw "Couldn't read $name from _SiteHeader.cshtml" }
    $d
  }
  $introFallbacks = Get-Dictionary 'introFallbacks'
  $calculatorTitles = Get-Dictionary 'calculatorTitles'
  $accents = [regex]::Matches([regex]::Match($headerSrc, 'string\[\] accents = \{([^}]*)\}').Groups[1].Value, '"(\w+)"') | ForEach-Object { $_.Groups[1].Value }
  $menuListLimit = [int][regex]::Match($headerSrc, 'const int menuListLimit = (\d+);').Groups[1].Value
  $flowThreshold = [int][regex]::Match($headerSrc, 'const int flowThreshold = (\d+);').Groups[1].Value
  if (-not $accents -or -not $menuListLimit -or -not $flowThreshold) { throw "Couldn't read accents/limits from _SiteHeader.cshtml" }
  $calcIcon = [regex]::Match($headerSrc, '<span class="mega__calc-icon">\s*(<svg[\s\S]*?</svg>)').Groups[1].Value

  function Build-MegaList($products, [string]$viewAllUrl, [bool]$withViewAll) {
    $sb = New-Object Text.StringBuilder
    [void]$sb.AppendLine('<ul class="mega__list">')
    foreach ($p in @($products | Select-Object -First $menuListLimit)) {
      [void]$sb.AppendLine("  <li><a href=""/products/$($p.category.ToLower())/p/$($p.url.ToLower())"">$(Enc $p.name)</a></li>")
    }
    if ($withViewAll -and @($products).Count -gt $menuListLimit) { [void]$sb.AppendLine("  <li><a href=""$viewAllUrl"">View all $(@($products).Count)</a></li>") }
    [void]$sb.Append('</ul>')
    $sb.ToString()
  }

  function Build-NavBar {
    $sb = New-Object Text.StringBuilder
    [void]$sb.AppendLine('<nav class="nav-bar" aria-label="Categories">')
    [void]$sb.AppendLine('<ul class="nav-bar__list container">')
    for ($i = 0; $i -lt $categories.Count; $i++) {
      $c = $categories[$i]
      $intro = if ($c.idealFor) { 'Ideal for: ' + $c.idealFor } elseif ($introFallbacks.ContainsKey($c.url)) { $introFallbacks[$c.url] } else { $null }
      $calc = $calculatorTitles[$c.url]
      $subGroups = @(@($c.subs) | Where-Object { $_ } | ForEach-Object { [pscustomobject]@{ Category = $_; Products = @(Get-MenuProducts $_.url) } })
      $subUrls = @{}
      foreach ($g in $subGroups) { foreach ($p in $g.Products) { $subUrls[$p.url] = $true } }
      $main = @(Get-MenuProducts $c.url | Where-Object { -not $subUrls.ContainsKey($_.url) })

      [void]$sb.AppendLine("<li class=""nav-item nav-item--$($accents[$i % $accents.Count])"">")
      [void]$sb.AppendLine("  <a href=""/$($c.url)/products/"" aria-haspopup=""true""><span class=""nav-text"">$(Enc $c.name)</span> <span class=""caret"">&#9662;</span></a>")
      [void]$sb.AppendLine('  <div class="dropdown mega"><div class="mega__inner container"><div class="mega__promo">')
      if ($intro) { [void]$sb.AppendLine("    <p class=""mega__intro"">$(Enc $intro)</p>") }
      [void]$sb.AppendLine("    <a href=""/$($c.url)/products/"" class=""mega__shop-all"">Shop all</a>")
      if ($calc) {
        [void]$sb.AppendLine("    <div class=""mega__calc""><span class=""mega__calc-icon"">$calcIcon</span><div class=""mega__calc-body""><p class=""mega__calc-title"">$(Enc $calc)</p><a href=""/calculator"" class=""mega__calc-btn"">Use our calculator</a></div><img class=""mega__calc-img"" src=""/img/gm-bag-bulk.jpg"" alt="""" width=""92"" height=""92""></div>")
      }
      [void]$sb.AppendLine('  </div><div class="mega__cols">')
      if ($main.Count -gt 0) {
        $flow = if ($main.Count -gt $flowThreshold) { ' mega__group--flow' } else { '' }
        [void]$sb.AppendLine("    <div class=""mega__group$flow""><a href=""/$($c.url)/products/"" class=""mega__heading"">$(Enc $c.name)</a>$(Build-MegaList $main "/$($c.url)/products/" $true)</div>")
      }
      foreach ($g in $subGroups) {
        $flow = if ($g.Products.Count -gt $flowThreshold) { ' mega__group--flow' } else { '' }
        $list = if ($g.Products.Count -gt 0) { Build-MegaList $g.Products '' $false } else { '' }
        [void]$sb.AppendLine("    <div class=""mega__group$flow""><a href=""/$($c.url)/$($g.Category.url)/products/"" class=""mega__heading"">$(Enc $g.Category.name)</a>$list</div>")
      }
      [void]$sb.AppendLine('  </div></div></div>')
      [void]$sb.AppendLine('</li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.Append('</nav>')
    $sb.ToString()
  }

  function Build-Header([bool]$isCheckout) {
    $h = Get-Between $headerSrc '<header ' '</header>' 'the header'
    $h = Remove-RazorComments $h
    $h = $h.Replace('@(isCheckout ? " site-header--checkout" : "")', $(if ($isCheckout) { ' site-header--checkout' } else { '' }))
    # the category nav block (its Razor loop is rebuilt above)
    $nav = [regex]::Match($h, '@if \(!isCheckout\)\s*\{\s*<nav class="nav-bar"[\s\S]*?</nav>\s*\}')
    if (-not $nav.Success) { throw "Couldn't find the category nav block in _SiteHeader.cshtml" }
    $h = $h.Remove($nav.Index, $nav.Length).Insert($nav.Index, $(if ($isCheckout) { '' } else { Build-NavBar }))
    # the remaining simple @if (!isCheckout) { ... } blocks
    $h = [regex]::Replace($h, '@if \(!isCheckout\)\s*\{([\s\S]*?)\r?\n[ \t]*\}', { param($m) if ($isCheckout) { '' } else { $m.Groups[1].Value } })
    $h = $h.Replace('@Model.MasterLayoutViewModel.BasketTotal', '&#163;0.00')
    Assert-NoRazor '_SiteHeader' $h
    $h
  }

  # ---------- _SiteFooter.cshtml, _TrackOrderModal.cshtml ----------
  $footer = Remove-RazorComments (Read-Package 'Views\Shared\_SiteFooter.cshtml')
  $footer = $footer.Replace('@(DateTime.Now.Year)', (Get-Date).Year.ToString())
  Assert-NoRazor '_SiteFooter' $footer

  $track = Remove-RazorComments (Read-Package 'Views\Shared\_TrackOrderModal.cshtml')
  $track = [regex]::Replace($track, '@using \(Ajax\.BeginForm\([^\r\n]*\)\)\s*\{([\s\S]*?)\r?\n[ \t]*\}',
    '<form action="/checkout/checkmyorder?id=track" data-ajax="true" data-ajax-mode="replace" data-ajax-update="#trackBodyMessage" id="form0" method="post">$1</form>')
  Assert-NoRazor '_TrackOrderModal' $track

  # ---------- _SiteMobileMenu.cshtml ----------
  $mobileSrc = Remove-RazorComments (Read-Package 'Views\Shared\_SiteMobileMenu.cshtml')
  $mobile = Get-Between $mobileSrc '<div class="menu-backdrop"' '</aside>' 'the mobile menu'
  $chev = [regex]::Match($mobile, '<span class="mobile-menu__chev"[^>]*>[\s\S]*?</svg></span>').Value
  $items = New-Object Text.StringBuilder
  for ($i = 0; $i -lt $categories.Count; $i++) {
    $c = $categories[$i]
    [void]$items.AppendLine("<li class=""mobile-menu__item mm--$($accents[$i % $accents.Count])"">")
    [void]$items.AppendLine("  <button type=""button"" class=""mobile-menu__toggle"" aria-expanded=""false""><span class=""mobile-menu__name"">$(Enc $c.name)</span>$chev</button>")
    [void]$items.AppendLine('  <ul class="mobile-submenu">')
    [void]$items.AppendLine("    <li><a href=""/$($c.url)/products/"">Shop all $(Enc $c.name)</a></li>")
    foreach ($s in @($c.subs) | Where-Object { $_ }) { [void]$items.AppendLine("    <li><a href=""/$($c.url)/$($s.url)/products/"">$(Enc $s.name)</a></li>") }
    [void]$items.AppendLine('  </ul>')
    [void]$items.AppendLine('</li>')
  }
  $list = [regex]::Match($mobile, '(<ul class="mobile-menu__list">)[\s\S]*?(</ul>\s*</nav>)')
  if (-not $list.Success) { throw "Couldn't find the category list in _SiteMobileMenu.cshtml" }
  $mobile = $mobile.Remove($list.Index, $list.Length).Insert($list.Index, $list.Groups[1].Value + "`n" + $items.ToString() + $list.Groups[2].Value)
  Assert-NoRazor '_SiteMobileMenu' $mobile

  # ---------- Views/Shared/_BulkEnquiryModal.cshtml (shared by the new homepage and category page) ----------
  $enquirySrc = Read-Package 'Views\Shared\_BulkEnquiryModal.cshtml'
  $enquiryColours = [regex]::Matches([regex]::Match($enquirySrc, 'string\[\] categoryColours = \{([^}]*)\}').Groups[1].Value, '"(#\w+)"') | ForEach-Object { $_.Groups[1].Value }
  if (-not $enquiryColours) { throw "Couldn't read categoryColours from _BulkEnquiryModal.cshtml" }
  $enquiryHtml = Get-Between $enquirySrc '<link href="/css/gm-enquiry\.css' '</script>' 'the bulk enquiry pop-up'
  $enquiryHtml = Remove-RazorComments $enquiryHtml
  # its model is the top-level category names in menu order
  $options = for ($i = 0; $i -lt $categories.Count; $i++) {
    $colour = $enquiryColours[$i % $enquiryColours.Count]
    "<option value=""$(Enc $categories[$i].name)"" data-color=""$colour"" style=""color:$colour"">$(Enc $categories[$i].name)</option>"
  }
  $enquiryHtml = Replace-Block $enquiryHtml '@for \(int i = 0; i < categories\.Count; i\+\+\)\s*\{' ($options -join "`n") 'the pop-up''s category options loop'
  Assert-NoRazor '_BulkEnquiryModal' $enquiryHtml

  # ---------- Views/Home/_HomePage.cshtml (the new homepage) ----------
  # Its loops are rebuilt here from the live site's data: banners, product tiles (image, price, trade price)
  # and categories. Card lists (offers, bestseller tabs) are read from the partial's own C# block.
  $homeHtml = $null
  $homeFile = Join-Path $Package 'Views\Home\_HomePage.cshtml'
  if (Test-Path -LiteralPath $homeFile) {
    $homeSrc = [IO.File]::ReadAllText($homeFile)
    $tiles = @{}
    foreach ($t in $data.tiles) { $tiles[$t.url] = $t }

    function ConvertFrom-CSharpString([string]$literal) {
      if ($literal -eq '(string)null') { return $null }
      if ($literal -eq 'true') { return $true }
      if ($literal -eq 'false') { return $false }
      ($literal | ConvertFrom-Json)   # C# "..." with \" and \uXXXX escapes reads as a JSON string
    }
    function Get-CardList([string]$name) {
      $block = [regex]::Match($homeSrc, "var $name = new\[\]\s*\{([\s\S]*?)\r?\n\s*\};").Groups[1].Value
      $cards = foreach ($obj in [regex]::Matches($block, 'new \{((?:[^{}"]|"(?:[^"\\]|\\.)*"|\{[^{}]*\})*)\}')) {
        $card = [ordered]@{}
        foreach ($p in [regex]::Matches($obj.Groups[1].Value, '(\w+) = ("(?:[^"\\]|\\.)*"|\(string\)null|true|false|new\[\] \{[^}]*\})')) {
          $value = $p.Groups[2].Value
          if ($value.StartsWith('new[]')) { $card[$p.Groups[1].Value] = @([regex]::Matches($value, '"((?:[^"\\]|\\.)*)"') | ForEach-Object { ConvertFrom-CSharpString ('"' + $_.Groups[1].Value + '"') }) }
          else { $card[$p.Groups[1].Value] = ConvertFrom-CSharpString $value }
        }
        [pscustomobject]$card
      }
      if (-not $cards) { throw "Couldn't read $name from _HomePage.cshtml" }
      @($cards)
    }
    # MasterLayoutViewModel.GetHomeProduct / GetCheapestHomeProduct and HomeProduct.FormatPrice
    function Get-HomeProduct([string]$url) { $tiles[$url] }
    function Get-CheapestHomeProduct([string]$category) {
      # sample products (e.g. the GBP 25 Sample Box in Gravels & Chippings) aren't bulk bags, so they don't count
      $data.tiles | Where-Object { $_.category -eq $category -and $_.url -notmatch 'sample' -and $_.name -notmatch 'sample' } |
        Sort-Object { [decimal]$_.price } | Select-Object -First 1
    }
    function Format-Price([string]$value, [bool]$pence) {
      $d = [decimal]$value
      if ($pence -or $d -ne [Math]::Floor($d)) { '&#163;' + $d.ToString('#,0.00', [Globalization.CultureInfo]::GetCultureInfo('en-GB')) }
      else { '&#163;' + $d.ToString('#,0', [Globalization.CultureInfo]::GetCultureInfo('en-GB')) }
    }
    function Get-ImageUrl($tile, [int]$size) { $tile.image -replace '-\d+(\.\w+)$', "-$size`$1" }
    function Get-ProductLink($tile) { "/products/$($tile.category.ToLower())/p/$($tile.url.ToLower())" }

    $offers = Get-CardList 'offers'
    $bestsellers = Get-CardList 'bestsellers'

    $h = Get-Between $homeSrc '<div class="gm-home">' '<script src="/js/gm-home.js' 'the homepage'
    $h = $h.Substring(0, $h.LastIndexOf('<script'))
    $h = Remove-RazorComments $h
    $homeScript = [regex]::Match($homeSrc, '<script src="/js/gm-home\.js[^"]*"></script>').Value

    # hero banners
    $bannerItems = @($data.banners)
    $slides = (0..($bannerItems.Count - 1) | ForEach-Object { "<a href=""$(Enc $bannerItems[$_].link)"" class=""carousel__slide""><img src=""$(Enc $bannerItems[$_].image)"" alt="""" class=""hero__img"" width=""1400"" height=""467"" $(if ($_ -eq 0) { 'fetchpriority=high' } else { 'loading=lazy' })></a>" }) -join "`n"
    $h = Replace-Block $h '@for \(int i = 0; i < bannerList\.Count; i\+\+\)\s*\{' $slides 'the banner loop'
    $controls = ''
    if (@($data.banners).Count -gt 1) {
      $controls = '<button type="button" class="carousel__arrow carousel__arrow--prev" aria-label="Previous slide">&#8249;</button><button type="button" class="carousel__arrow carousel__arrow--next" aria-label="Next slide">&#8250;</button><div class="carousel__dots">' +
        ((0..(@($data.banners).Count - 1) | ForEach-Object { "<button type=""button"" class=""carousel__dot$(if ($_ -eq 0) { ' is-active' })"" aria-label=""Go to slide $($_ + 1)""></button>" }) -join '') + '</div>'
    }
    $h = Replace-Block $h '@if \(bannerList\.Count > 1\)\s*\{' $controls 'the banner controls'

    # offer cards
    $cards = foreach ($offer in $offers) {
      $product = Get-HomeProduct $offer.Product
      $priced = if ($offer.Cheapest) { Get-CheapestHomeProduct $offer.Cheapest } else { $product }
      if (-not $product -or ($offer.ShowPrice -and -not $priced)) { continue }
      $link = if ($offer.Link) { $offer.Link } else { Get-ProductLink $product }
      $roundel = if ($offer.ShowPrice) { "<span class=""offer-card__roundel""><small>FROM</small><strong><span class=""cust-price"">$(Format-Price $priced.price $false)</span><span class=""trade-price"">$(Format-Price $priced.tradePrice $false)</span></strong><small>Bulk Bag</small></span>" } else { '' }
      "<a href=""$(Enc $link)"" class=""card offer-card offer-card--$($offer.Style)""><img class=""offer-card__img"" src=""$(Enc (Get-ImageUrl $product 600))"" alt="""" width=""600"" height=""600"" loading=""lazy"">$roundel<span class=""offer-card__body""><span class=""offer-card__title"">$(Enc $offer.Title)</span><span class=""offer-card__desc"">$(Enc $offer.Text)</span><span class=""offer-card__btn"">$(Enc $offer.Button) <span class=""offer-card__arrow"" aria-hidden=""true"">&rarr;</span></span></span></a>"
    }
    $h = Replace-Block $h '@foreach \(var offer in offers\)\s*\{' ($cards -join "`n") 'the offer cards loop'

    # bestseller tabs and panels
    $tabs = for ($t = 0; $t -lt $bestsellers.Count; $t++) {
      $tab = $bestsellers[$t]
      "<button type=""button"" class=""bs-tab$(if ($t -eq 0) { ' bs-tab--active' })"" role=""tab"" id=""bs-tab-$($tab.Id)"" aria-controls=""bs-panel-$($tab.Id)"" aria-selected=""$(if ($t -eq 0) { 'true' } else { 'false' })"" tabindex=""$(if ($t -eq 0) { '0' } else { '-1' })""><span class=""bs-tab__icon"">$($tab.Icon)</span>$(Enc $tab.Label)</button>"
    }
    $h = Replace-Block $h '@for \(int t = 0; t < bestsellers\.Length; t\+\+\)\s*\{\s*var tab = bestsellers\[t\];\s*<button' ($tabs -join "`n") 'the bestseller tabs loop'
    $panels = for ($t = 0; $t -lt $bestsellers.Count; $t++) {
      $tab = $bestsellers[$t]
      $cardsHtml = foreach ($url in $tab.Products) {
        $product = Get-HomeProduct $url
        if (-not $product) { continue }
        "<a href=""$(Enc (Get-ProductLink $product))"" class=""bs-card""><img class=""bs-card__img"" src=""$(Enc (Get-ImageUrl $product 330))"" alt="""" width=""330"" height=""330"" loading=""lazy""><h3 class=""bs-card__name"">$(Enc $product.name)</h3><p class=""bs-card__meta"">Price (inc. VAT &amp; delivery)</p><p class=""bs-card__price"">From <span class=""cust-price"">$(Format-Price $product.price $true)</span><span class=""trade-price"">$(Format-Price $product.tradePrice $true)</span></p></a>"
      }
      "<div class=""bs-panel"" id=""bs-panel-$($tab.Id)"" role=""tabpanel"" aria-labelledby=""bs-tab-$($tab.Id)""$(if ($t -ne 0) { ' hidden' })><div class=""bs-grid"">$($cardsHtml -join "`n")</div><div class=""bs-banner""><span class=""bs-banner__text"">Try before you buy with our samples bags</span><a href=""$(Enc $tab.ShopAll)"" class=""bs-banner__link"">$(Enc $tab.ShopAllText)</a></div></div>"
    }
    $h = Replace-Block $h '@for \(int t = 0; t < bestsellers\.Length; t\+\+\)\s*\{\s*var tab = bestsellers\[t\];\s*<div class="bs-panel"' ($panels -join "`n") 'the bestseller panels loop'

    # the shared bulk enquiry pop-up
    $partialCall = '@Html.Partial("_BulkEnquiryModal", categories)'
    if (-not $h.Contains($partialCall)) { throw "Couldn't find $partialCall in _HomePage.cshtml" }
    $h = $h.Replace($partialCall, $enquiryHtml)

    Assert-NoRazor '_HomePage' $h
    $homeHtml = $h + "`n" + $homeScript
  }

  # ---------- pieces of _Layout.cshtml ----------
  $layout = Read-Package 'Views\Shared\_Layout.cshtml'
  $fontLink = [regex]::Match($layout, '@if \(useNewChrome\)\s*\{\s*(<link href="https://fonts\.googleapis\.com[^>]*>)').Groups[1].Value
  $chromeCss = [regex]::Match($layout, '<link href="~/css/gm-chrome\.css[^"]*" rel="stylesheet" />').Value.Replace('~/', '/')
  $bodyTag = [regex]::Match($layout, '<body[^>]*>').Value
  $bodyStyle = [regex]::Match($layout, '<body[^>]*>\s*(<style>[\s\S]*?</style>)').Groups[1].Value.Replace('@@', '@')
  $mainBodyTag = [regex]::Match($layout, '<div itemscope itemtype="http://schema.org/WebSite" id="mainBody"[^>]*>').Value
  $autocomplete = [regex]::Match($layout, 'function autocomplete\(inp, arr\) \{[\s\S]*?(?=\r?\n\s*</script>)').Value
  $autocompleteInit = [regex]::Match($layout, '\["myInput", "myInput2"\]\.forEach\(function \(id\) \{[\s\S]*?\}\);').Value
  $chromeJs = [regex]::Match($layout, '<script src="/js/gm-chrome\.js[^"]*"></script>').Value
  # _Layout loads Trustpilot's TrustBox script in <head>; the homepage's review widgets need it
  $trustBoxScript = [regex]::Match($layout, '<script[^>]*src="//widget\.trustpilot\.com/[^"]*"[^>]*></script>').Value
  foreach ($pair in @(@('font link', $fontLink), @('gm-chrome.css link', $chromeCss), @('body tag', $bodyTag), @('body style', $bodyStyle), @('#mainBody', $mainBodyTag), @('autocomplete()', $autocomplete), @('autocomplete init', $autocompleteInit), @('gm-chrome.js', $chromeJs))) {
    if (-not $pair[1]) { throw "Couldn't find the $($pair[0]) in _Layout.cshtml" }
  }
  $names = @($data.products | ForEach-Object { $_.name }) | ConvertTo-Json -Compress
  $urls = @($data.products | ForEach-Object { "/products/$($_.category)/p/$($_.url)" }) | ConvertTo-Json -Compress
  $oldBody = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'old-body.html'))

  # ---------- Views/Shared/_CategoryPage.cshtml (the new category page) ----------
  # Filled from the saved old Gravels & Chippings page, as site-preview.ps1 fills it from each live category page
  $categoryModel = ConvertFrom-OldCategoryPage $oldBody '/garden-chippings/products/' $null @($categories | ForEach-Object { $_.name })
  if (-not $categoryModel) { throw "Couldn't read old-body.html as a category page" }
  $categoryHtml = Format-CategoryPage (Join-Path $Package 'Views\Shared\_CategoryPage.cshtml') $categoryModel $enquiryHtml
  # this saved page isn't at the category's address, so Sort by posts to it (in the whole-website preview)
  $sortForm = '<form class="plp-sort" method="post">'
  if (-not $categoryHtml.Contains($sortForm)) { throw "Couldn't find the Sort by form in _CategoryPage.cshtml" }
  $categoryHtml = $categoryHtml.Replace($sortForm, '<form class="plp-sort" method="post" action="/garden-chippings/products/">')

  # $kind: 'home' (the new homepage), 'category' (the new category page) or 'checkout'
  function Build-Page([string]$kind) {
    $isCheckout = $kind -eq 'checkout'
    $css = ($data.stylesheets | ForEach-Object { "<link href=""$_"" rel=""stylesheet"" />" }) -join "`n"
    $title = @{ home = 'New homepage'; category = 'New category page'; checkout = 'Checkout' }[$kind]
    switch ($kind) {
      'home' {
        # the homepage's Head section, and #mainBody without the old white box (as _Layout will render it)
        $css += "`n<link href=""/css/gm-home.css?v1"" rel=""stylesheet"" />"
        $mainTag = '<div itemscope itemtype="http://schema.org/WebSite" id="mainBody">'
        $content = $homeHtml
      }
      'checkout' {
        $mainTag = $mainBodyTag
        $content = '<div class="container" style="padding:40px 15px"><h1>Checkout</h1><p>Checkout page content would be here.</p></div>'
      }
      default {
        # the category page's stylesheet, and #mainBody without the old white box
        $css += "`n<link href=""/css/gm-category.css?v1"" rel=""stylesheet"" />"
        $mainTag = '<div itemscope itemtype="http://schema.org/WebSite" id="mainBody">'
        $content = $categoryHtml
      }
    }
    @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>[Preview] $title</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
$fontLink
$trustBoxScript
$css
$chromeCss
</head>
$bodyTag
$bodyStyle
$(Build-Header $isCheckout)
$mainTag
$content
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/js/bootstrap.bundle.min.js"></script>
<script>
var countries = $names;
var urls = $urls;
$autocomplete
</script>
$footer
$track
$(if (-not $isCheckout) { $mobile })
$chromeJs
<script>
$autocompleteInit
</script>
$stayInPreviewScript
</body>
</html>
"@
  }

  if ($homeHtml) { [IO.File]::WriteAllText((Join-Path $out 'index.html'), (Build-Page 'home'), $utf8) }
  else { [IO.File]::WriteAllText((Join-Path $out 'index.html'), (Build-Page 'category'), $utf8) }
  [IO.File]::WriteAllText((Join-Path $out 'category.html'), (Build-Page 'category'), $utf8)
  [IO.File]::WriteAllText((Join-Path $out 'checkout.html'), (Build-Page 'checkout'), $utf8)

  # The same pieces on their own, for site-preview.ps1 to swap into real pages from the live site
  $fragments = Join-Path $PSScriptRoot 'fragments'
  New-Item -ItemType Directory -Force $fragments | Out-Null
  function Write-Fragment([string]$name, [string]$text) { [IO.File]::WriteAllText((Join-Path $fragments $name), $text, $utf8) }
  Write-Fragment 'head.html' "$fontLink`n$chromeCss"
  Write-Fragment 'header.html' (Build-Header $false)
  Write-Fragment 'header-checkout.html' (Build-Header $true)
  Write-Fragment 'footer.html' "$footer`n$track"
  Write-Fragment 'mobile-menu.html' $mobile
  Write-Fragment 'scripts.html' $chromeJs
  Write-Fragment 'autocomplete.js' $autocomplete
  Write-Fragment 'autocomplete-init.js' $autocompleteInit
  if ($homeHtml) { Write-Fragment 'home.html' $homeHtml }
  Write-Fragment 'enquiry.html' $enquiryHtml
  Write-Fragment 'built.txt' (Get-Date).ToString('o')

  "$((Get-Date).ToString('HH:mm:ss')) built index.html (homepage), category.html (category page), checkout.html and fragments from $Package (menu data fetched $($data.fetched))"
}

Invoke-Build

if ($Watch) {
  # all of Views, so the homepage partial (Views/Home) rebuilds as well as the header and footer
  $views = Join-Path $Package 'Views'
  $watcher = New-Object IO.FileSystemWatcher $views, '*.cshtml'
  $watcher.IncludeSubdirectories = $true
  $watcher.NotifyFilter = [IO.NotifyFilters]'LastWrite, FileName'
  "watching $views for .cshtml changes (Ctrl+C to stop)"
  while ($true) {
    $change = $watcher.WaitForChanged([IO.WatcherChangeTypes]'Changed, Created, Renamed', 1000)
    if ($change.TimedOut) { continue }
    Start-Sleep -Milliseconds 400   # editors save in more than one write
    try { Invoke-Build } catch { Write-Host "build failed: $($_.Exception.Message)" -ForegroundColor Red }
  }
}
