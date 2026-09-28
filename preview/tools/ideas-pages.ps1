# The new Ideas & Advice pages (Views/Ideas/_IdeasTopics.cshtml, _IdeasList.cshtml and _IdeasArticle.cshtml) for the
# previews. Dot-sourced by site-preview.ps1 (localhost:8780/ideas-advice...), after category-page.ps1 and
# info-pages.ps1, whose helpers it uses.
#
#   Get-OldIdeasTopics          the topics, as the old banner's tabs list them (every Ideas & Advice page has them)
#   ConvertFrom-OldIdeasTopic   an old topic page: its name, description and articles
#   Get-IdeasLatest             a stand-in for the landing page's latest articles (below)
#   ConvertFrom-OldIdeasArticle an old article page: its title, picture and HTML
#   Format-IdeasPage            renders a page as _ContentHubLayout.cshtml's new branch does: the .gm-info wrapper, the
#                               bar (_IdeasTopics) and the page (_IdeasList or _IdeasArticle)
#
# The markup comes from the .cshtml files as they are, and the render fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

$script:ideasTopicPages = @{}

function Get-OldIdeasTopics([string]$html) {
  @([regex]::Matches($html, '<a href="(/ideas-advice/[^"]+)" class="pl-Tab">\s*<span class="pl-Tab-title">([\s\S]*?)</span>') | ForEach-Object {
    [pscustomobject]@{ Name = ConvertFrom-HtmlText $_.Groups[2].Value; Url = $_.Groups[1].Value }
  })
}

function ConvertFrom-OldIdeasCards([string]$html) {
  @(foreach ($m in [regex]::Matches($html, '<a href="(/ideas-advice/(\d+)/[^"]+)">\s*<div class="card">\s*(?:<img src="([^"]*)"\s*/?>)?\s*<h2>([\s\S]*?)</h2>\s*<div[^>]*>([\s\S]*?)</div>')) {
    [pscustomobject]@{
      Id = [int]$m.Groups[2].Value
      Name = ConvertFrom-HtmlText $m.Groups[4].Value
      Url = $m.Groups[1].Value
      ImageUrl = $(if ($m.Groups[3].Value) { [Net.WebUtility]::HtmlDecode($m.Groups[3].Value) } else { $null })
      Summary = ConvertFrom-HtmlText $m.Groups[5].Value
    }
  })
}

# $path is the page's address; its name is the tab's (the page title can be empty, as Product Information's is)
function ConvertFrom-OldIdeasTopic([string]$html, [string]$path) {
  $tab = @(Get-OldIdeasTopics $html | Where-Object { $_.Url.TrimEnd('/') -ieq $path.TrimEnd('/') })
  if ($tab.Count -eq 0) { return $null }
  # DisplayCategory.cshtml's "<div>@Model.Description</div>", after its own style and stylesheets
  $description = [regex]::Match($html, '\.card\{\s*margin-top:20px;\s*\}\s*</style>\s*(?:<link[^>]*>\s*)+<div>([\s\S]*?)</div>').Groups[1].Value
  [pscustomobject]@{
    Title = $tab[0].Name
    Description = $(if ((ConvertFrom-HtmlText $description) -ne '') { ConvertFrom-HtmlText $description } else { $null })
    IsLanding = $false
    Articles = @(ConvertFrom-OldIdeasCards $html)
  }
}

# The landing page shows IdeasRepository.GetLatestArticles(): the 20 newest by date, from every topic. The live landing
# page doesn't show them (it has three chosen articles) and no page shows the dates, so the preview stands in with the
# topic pages' articles, newest first by their number, which goes up as articles are added. $fetch gets a live page.
function Get-IdeasLatest($topics, [scriptblock]$fetch) {
  $all = @(foreach ($topic in $topics) {
    if (-not $script:ideasTopicPages.ContainsKey($topic.Url)) { $script:ideasTopicPages[$topic.Url] = @(ConvertFrom-OldIdeasCards (& $fetch $topic.Url)) }
    $script:ideasTopicPages[$topic.Url]
  })
  [pscustomobject]@{
    Title = 'Ideas & Advice'
    Description = $null
    IsLanding = $true
    Articles = @($all | Sort-Object Id -Unique | Sort-Object Id -Descending | Select-Object -First 20)
  }
}

function ConvertFrom-OldIdeasArticle([string]$mainHtml) {
  $start = $mainHtml.IndexOf('<div class="padding-wrap blog"')
  if ($start -lt 0) { return $null }
  $b = $mainHtml.Substring($start)
  $open = [regex]::Match($b, '<div id="news_article"[^>]*>')
  if (-not $open.Success) { return $null }
  $end = Find-ClosingDiv $b ($open.Index + $open.Length)
  if ($end -lt 0) { return $null }
  $image = [regex]::Match($b.Substring(0, $open.Index), '<img src="([^"]*)"').Groups[1].Value
  $contents = $b.Substring($open.Index + $open.Length, $end - $open.Index - $open.Length).Trim()
  [pscustomobject]@{
    Title = ConvertFrom-HtmlText ([regex]::Match($b, '<h1[^>]*>([\s\S]*?)</h1>').Groups[1].Value)
    ImageUrl = $(if ($image) { [Net.WebUtility]::HtmlDecode($image) } else { $null })
    # without its empty paragraphs, as DisplayArticle.cshtml's new branch gives it (IdeasArticleModel.WithoutEmptyParagraphs)
    Contents = [regex]::Replace($contents, '<p(?:\s[^>]*)?>(?:\s|&nbsp;|&#160;|<br\s*/?>)*</p>', '', 'IgnoreCase')
  }
}

# $views is the Views\Ideas folder, $topics the bar's topics, $path the page's address; $list or $article is the page
function Format-IdeasPage([string]$views, $topics, [string]$path, $list, $article) {
  $values = New-Object Collections.ArrayList
  function Put([string]$html) { [void]$values.Add($html); [string][char]2 + ($values.Count - 1) + [char]3 }
  function Enc([string]$s) { Put ([Net.WebUtility]::HtmlEncode($s)) }
  function Sub([string]$text, [hashtable]$map) {
    foreach ($key in ($map.Keys | Sort-Object Length -Descending)) {
      if (-not $text.Contains($key)) { throw "Couldn't find $key in the Ideas partials" }
      $text = $text.Replace($key, $map[$key])
    }
    $text
  }
  function Read-Partial([string]$name, [string]$startsWith) {
    $src = [IO.File]::ReadAllText((Join-Path $views $name))
    $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
    $start = $src.IndexOf($startsWith)
    if ($start -lt 0) { throw "Couldn't find $startsWith in $name" }
    $src.Substring($start)
  }

  # the bar: the topic whose page this is gets aria-current
  $bar = Read-Partial '_IdeasTopics.cshtml' '<nav class="ida-bar"'
  $bar = Set-RazorBlock $bar '@foreach \(var topic in Model\)\s*\{' { param($b)
    ($topics | ForEach-Object {
      $current = $_.Url.TrimEnd('/') -ieq $path.TrimEnd('/')
      Sub $b.Inner @{ ' aria-current="@(string.Equals(topic.Url.TrimEnd(''/''), here, StringComparison.OrdinalIgnoreCase) ? "page" : null)"' = $(if ($current) { ' aria-current="page"' } else { '' })
        '@topic.Url' = (Enc $_.Url); '@topic.Name' = (Enc $_.Name) }
    }) -join ''
  }

  if ($article) {
    $page = Read-Partial '_IdeasArticle.cshtml' '<nav class="container inf-crumbs"'
    $page = Set-RazorBlock $page '@if \(Model\.ImageUrl != null\)\s*\{' { param($b) if ($article.ImageUrl) { Sub $b.Inner @{ '@Model.ImageUrl' = (Enc $article.ImageUrl) } } else { '' } }
    $page = Sub $page @{ '@Model.Title' = (Enc $article.Title); '@Html.Raw(Model.Contents)' = (Put $article.Contents) }
  } else {
    $cards = @($list.Articles)
    $count = $cards.Count
    $first = if ($list.IsLanding -and $count -gt 0) { 1 } else { 0 }
    $hasDescription = [bool]("$($list.Description)".Trim())
    $page = Read-Partial '_IdeasList.cshtml' '<nav class="container inf-crumbs"'
    $card = {
      param([string]$markup, $c, [string]$var, [int]$i)
      $markup = Set-RazorBlock $markup ('@if \(' + $var + '\.ImageUrl != null\)\s*\{') { param($b) if ($c.ImageUrl) { $b.Inner } else { '' } }
      $markup = Set-RazorBlock $markup ('@if \(!string\.IsNullOrWhiteSpace\(' + $var + '\.Summary\)\)\s*\{') { param($b) if ("$($c.Summary)".Trim()) { $b.Inner } else { '' } }
      $map = @{ "@$var.Url" = (Enc $c.Url); "@$var.Name" = (Enc $c.Name) }
      if ($c.ImageUrl) { $map["@$var.ImageUrl"] = (Enc $c.ImageUrl) }
      if ("$($c.Summary)".Trim()) { $map["@$var.Summary"] = (Enc $c.Summary) }
      if ($markup.Contains('@(i < 3 + first ? "eager" : "lazy")')) { $map['@(i < 3 + first ? "eager" : "lazy")'] = $(if ($i -lt 3 + $first) { 'eager' } else { 'lazy' }) }
      Sub $markup $map
    }
    # the breadcrumb, the eyebrow and the introduction
    $page = Set-RazorBlock $page '@if \(Model\.IsLanding\)\s*\{' { param($b) if ($list.IsLanding) { $b.Inner } else { $b.ElseInner } }
    $page = Set-RazorBlock $page '@if \(Model\.IsLanding\)\s*\{' { param($b) if ($list.IsLanding) { $b.Inner } else { '' } }
    $page = Set-RazorBlock $page '@if \(!string\.IsNullOrWhiteSpace\(Model\.Description\)\)\s*\{' { param($b) if ($hasDescription) { $b.Inner } else { '' } }
    $page = Set-RazorBlock $page '@if \(Model\.IsLanding && string\.IsNullOrWhiteSpace\(Model\.Description\)\)\s*\{' { param($b) if ($list.IsLanding -and -not $hasDescription) { $b.Inner } else { '' } }
    # the articles
    $page = Set-RazorBlock $page '@if \(count == 0\)\s*\{' { param($b)
      if ($count -eq 0) { return $b.Inner }
      $inner = Set-RazorBlock $b.ElseInner '(?<!@)if \(first == 1\)\s*\{' { param($fb)
        if ($first -ne 1) { return '' }
        & $card (Get-LoopMarkup $fb.Inner) $cards[0] 'feature' 0
      }
      Set-RazorBlock $inner '(?<!@)if \(count > first\)\s*\{' { param($gb)
        if ($count -le $first) { return '' }
        $grid = Sub $gb.Inner @{ '@(Model.IsLanding ? "ida-list__title" : "inf-sr")' = $(if ($list.IsLanding) { 'ida-list__title' } else { 'inf-sr' }); '@(Model.IsLanding ? "More articles" : "Articles")' = $(if ($list.IsLanding) { 'More articles' } else { 'Articles' }) }
        Set-RazorBlock $grid '@for \(int i = first; i < count; i\+\+\)\s*\{' { param($lb)
          $markup = Get-LoopMarkup $lb.Inner
          ($first..($count - 1) | ForEach-Object { & $card $markup $cards[$_] 'card' $_ }) -join ''
        }
      }
    }
    # the landing page's Instagram and Pinterest links
    $page = Set-RazorBlock $page '@if \(Model\.IsLanding\)\s*\{' { param($b) if ($list.IsLanding) { $b.Inner } else { '' } }
    if ($page.Contains('@Model.Description')) { $page = Sub $page @{ '@Model.Description' = (Enc $list.Description) } }
    $page = Sub $page @{ '@Model.Title' = (Enc $list.Title) }
  }

  # _ContentHubLayout.cshtml's new branch
  $h = '<div class="gm-info gm-ideas">' + "`n" + $bar + "`n" + $page + "`n</div>"
  Assert-NoRazorLeft 'the Ideas partials' $h
  [regex]::Replace($h, [string][char]2 + '(\d+)' + [char]3, { param($x) $values[[int]$x.Groups[1].Value] })
}
