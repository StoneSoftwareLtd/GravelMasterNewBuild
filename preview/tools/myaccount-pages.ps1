# The new My Account pages (Views/MyAccount/_*Page.cshtml, with _AccountAreaHead.cshtml at the top) for the previews.
# Dot-sourced by site-preview.ps1, after basket-page.ps1 (Get-LiveProductModel) and account-pages.ps1 (the helpers).
#
#   Get-SampleAccount       a sample signed-in customer and two orders of real products (photos and pages read from the
#                           live product pages): the preview is never signed in, so the live site sends /myaccount to sign in
#   Format-MyAccountPage    renders one of the pages
#
# The markup comes from the .cshtml files as they are: each Razor block is found and filled in, and the render fails if
# any Razor is left over. Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

$script:sampleAccountOrders = $null

# $flags: 'trade' (a trade account), 'empty' (no orders), 'noreturns' (the Returns tab switched off)
function Get-SampleAccount([string[]]$flags) {
  if (-not $script:sampleAccountOrders) {
    # Description: what AccountOrderLine.Describe makes of an order line saved as "Name<br/>Size" (the size)
    function Line($path, [string]$size, [int]$qty, [int]$id) {
      $m = Get-LiveProductModel $path
      [pscustomobject]@{ ItemId = $id; ProductName = $m.Name; Url = $path; ImageUrl = $m.Photos[0].ThumbUrl; Description = $size; Quantity = $qty }
    }
    $script:sampleAccountOrders = @(
      [pscustomobject]@{ Number = '123456'; Date = (Get-Date).Date.AddDays(-6); DeliveryAddress = '1 Sample Street, Nottingham, NG7 2RD'; DeliveryPostcode = 'NG7 2RD'
        Lines = @((Line '/products/garden-chippings/p/cotswold-chippings-20mm' 'Approx 850Kg Bulk Bag' 2 9001), (Line '/products/weed-control-membrane/p/plastic-pegs' '10 Plastic Pegs' 1 9002)) },
      [pscustomobject]@{ Number = '118870'; Date = (Get-Date).Date.AddDays(-62); DeliveryAddress = '1 Sample Street, Nottingham, NG7 2RD'; DeliveryPostcode = 'NG7 2RD'
        Lines = @((Line '/products/turf-and-seed/p/pro-hard-wearing-turf' 'm2 Rolls' 10 8801)) }
    )
  }
  [pscustomobject]@{
    Area = [pscustomobject]@{ FirstName = 'sam'; LastName = 'sample'; Email = 'sample.customer@example.com'; IsTrade = $flags -contains 'trade'; ShowReturns = $flags -notcontains 'noreturns'; Section = 'Orders' }
    Orders = $(if ($flags -contains 'empty') { @() } else { $script:sampleAccountOrders })
  }
}

function Get-MyAccountPartial([string]$templatePath, [string]$rootMarker) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $start = $src.IndexOf($rootMarker)
  if ($start -lt 0) { throw "Couldn't find $rootMarker in $templatePath" }
  $src.Substring($start)
}

# _AccountAreaHead.cshtml for $area (FirstName, Email, IsTrade, ShowReturns, Section)
function Format-AccountAreaHead([string]$viewsPath, $area) {
  $h = Get-MyAccountPartial (Join-Path $viewsPath '_AccountAreaHead.cshtml') '<div class="acc-areahead">'
  $first = if ($area.FirstName) { (Get-Culture).TextInfo.ToTitleCase($area.FirstName.Trim()) } else { '' }
  $h = $h.Replace('@(first.Length > 0 ? "Hi " + first : "Hello")', $(if ($first) { 'Hi ' + (Enc $first) } else { 'Hello' }))
  $h = Set-RazorBlock $h '@if \(Model\.IsTrade\)\s*\{' { param($b) if ($area.IsTrade) { $b.Inner } else { '' } }
  $h = $h.Replace('@Model.Email', (Enc $area.Email))
  $h = Set-RazorBlock $h '@foreach \(var tab in tabs\)\s*\{' { param($b)
    $item = [regex]::Match($b.Inner, '<li>[\s\S]*?</li>').Value
    $tabs = @(@('Orders', 'Orders', '/myaccount/orders'), @('Returns', 'Returns', '/myaccount/returns'), @('PriceMatch', 'Price match', '/myaccount/pricematch'), @('Address', 'Address', '/myaccount/editaddress'))
    ($tabs | Where-Object { $_[0] -ne 'Returns' -or $area.ShowReturns } | ForEach-Object {
      $current = if ($_[0] -eq $area.Section) { ' aria-current="page"' } else { '' }
      $item.Replace('@tab.Value[1]', $_[2]).Replace(' aria-current="@(tab.Key == Model.Section ? "page" : null)"', $current).Replace('@tab.Value[0]', $_[1])
    }) -join "`n            "
  }
  Test-NoRazorLeft $h '_AccountAreaHead'
}

# One order line's markup: the "@foreach (var line in ...)" body, or the request-return page's single line
function Format-AccountLine([string]$markup, $line, [bool]$showReturns) {
  $o = Set-RazorBlock $markup '@if \(line\.ImageUrl != null\)\s*\{' { param($b) if ($line.ImageUrl) { $b.Inner.Replace('@line.ImageUrl', (Enc $line.ImageUrl)) } else { $b.ElseInner } }
  $o = Set-RazorBlock $o '@if \(line\.ProductName != null\)\s*\{' { param($b) if ($line.ProductName) { $b.Inner.Replace('@line.Url', (Enc $line.Url)).Replace('@line.ProductName', (Enc $line.ProductName)) } else { '' } }
  if ($o.Contains('@if (Model.Area.ShowReturns)')) {
    $o = Set-RazorBlock $o '@if \(Model\.Area\.ShowReturns\)\s*\{' { param($b)
      if (-not $showReturns) { return '' }
      $name = if ($line.ProductName) { $line.ProductName } else { $line.Description }
      $b.Inner.Replace('@line.ItemId', [string]$line.ItemId).Replace('@(line.ProductName ?? line.Description)', (Enc $name))
    }
  }
  $o = Set-RazorBlock $o '@if \(!string\.IsNullOrEmpty\(line\.Description\)\)\s*\{' { param($b) if ($line.Description) { $b.Inner.Replace('@line.Description', (Enc $line.Description)) } else { '' } }
  $o.Replace('@line.Quantity', (Enc ([string]$line.Quantity)))
}

# $page: orders, returns, requestreturn, returnconfirmation, pricematch, editaddress
function Format-MyAccountPage([string]$viewsPath, [string]$page, $sample) {
  $uk = [Globalization.CultureInfo]::GetCultureInfo('en-GB')
  $area = $sample.Area
  $section = @{ orders = 'Orders'; returns = 'Returns'; requestreturn = 'Returns'; returnconfirmation = 'Returns'; pricematch = 'PriceMatch'; editaddress = 'Address' }[$page]
  $area = [pscustomobject]@{ FirstName = $area.FirstName; LastName = $area.LastName; Email = $area.Email; IsTrade = $area.IsTrade; ShowReturns = $area.ShowReturns; Section = $section }
  $file = @{ orders = '_OrdersPage'; returns = '_ReturnsPage'; requestreturn = '_RequestReturnPage'; returnconfirmation = '_ReturnDonePage'; pricematch = '_PriceMatchPage'; editaddress = '_AddressPage' }[$page]
  $h = Get-MyAccountPartial (Join-Path $viewsPath "$file.cshtml") '<div class="gm-account"'
  $head = Format-AccountAreaHead $viewsPath $area
  $h = [regex]::Replace($h, '@Html\.Partial\("~/Views/MyAccount/_AccountAreaHead\.cshtml", Model(\.Area)?\)', [Text.RegularExpressions.MatchEvaluator] { param($m) $head })
  $h = $h.Replace('@Html.AntiForgeryToken()', $script:antiForgeryStandIn)

  switch ($page) {
    'orders' {
      $h = Set-RazorBlock $h '@if \(Model\.Orders\.Count == 0\)\s*\{' { param($b)
        if (@($sample.Orders).Count -eq 0) { return $b.Inner }
        Set-RazorBlock $b.ElseInner '@foreach \(var order in Model\.Orders\)\s*\{' { param($ob)
          ($sample.Orders | ForEach-Object {
            $order = $_
            $o = Set-RazorBlock $ob.Inner '@if \(!string\.IsNullOrWhiteSpace\(order\.DeliveryAddress\)\)\s*\{' { param($ib) if ($order.DeliveryAddress) { $ib.Inner.Replace('@order.DeliveryAddress', (Enc $order.DeliveryAddress)) } else { '' } }
            $o = Set-RazorBlock $o '@foreach \(var line in order\.Lines\)\s*\{' { param($lb) ($order.Lines | ForEach-Object { Format-AccountLine $lb.Inner $_ $area.ShowReturns }) -join '' }
            $o.Replace('@order.Number', (Enc $order.Number)).Replace('@order.Date.ToString("dddd d MMMM yyyy", uk)', ([datetime]$order.Date).ToString('dddd d MMMM yyyy', $uk)).Replace('@order.DeliveryPostcode', (Enc $order.DeliveryPostcode))
          }) -join ''
        }
      }
    }
    'requestreturn' {
      $order = @($script:sampleAccountOrders)[0]   # an item from an order, even with ?empty=1
      $line = $order.Lines[0]
      $h = Set-RazorBlock $h '@if \(line != null\)\s*\{' { param($b)
        $inner = $b.Inner
        $single = [regex]::Match($inner, '<div class="acc-line acc-line--single">[\s\S]*?</div>\s*</div>')
        $inner = $inner.Substring(0, $single.Index) + (Format-AccountLine $single.Value $line $false) + $inner.Substring($single.Index + $single.Length)
        $inner.Replace('@Model.Order.Number', (Enc $order.Number)).Replace('@Model.Order.Date.ToString("d MMMM yyyy", uk)', ([datetime]$order.Date).ToString('d MMMM yyyy', $uk)).Replace('@Model.OrderItemId', [string]$line.ItemId)
      }
    }
    'returnconfirmation' {
      $h = Set-RazorBlock $h '@if \(!string\.IsNullOrEmpty\(Model\.OrderNumber\)\)\s*\{' { param($b) $b.Inner.Replace('@Model.OrderNumber', '123456') }
    }
    'editaddress' {
      $pairs = @(@('@Model.AddressId', '4242'), @('@Model.Address1', '1 Sample Street'), @('@(string.IsNullOrWhiteSpace(Model.Address2) ? "" : Model.Address2)', ''),
        @('@Model.City', 'Nottingham'), @('@Model.County', 'Nottinghamshire'), @('@Model.Postcode', 'NG7 2RD'))
      foreach ($p in $pairs) { if (-not $h.Contains($p[0])) { throw "Couldn't find $($p[0]) in _AddressPage.cshtml" }; $h = $h.Replace($p[0], $p[1]) }
    }
  }
  Test-NoRazorLeft $h $file
}
