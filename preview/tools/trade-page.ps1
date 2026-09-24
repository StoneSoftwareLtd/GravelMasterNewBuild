# The new Trade Accounts page (Views/Content/_TradePage.cshtml) for the previews. Dot-sourced by site-preview.ps1
# (localhost:8780/trade), after category-page.ps1, whose Razor helpers it uses.
#
#   Format-TradePage  renders the partial
#
# The page has no data from the site: its perks and the sign-up address are in the partial's own C# block, which
# this reads. The markup comes from the .cshtml as it is, and the render fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

function Format-TradePage([string]$templatePath) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $applyUrl = [regex]::Match($src, 'const string applyUrl = "([^"]+)";').Groups[1].Value
  $perks = @([regex]::Matches($src, 'new \{ Title = "([^"]+)", Text = "([^"]+)",\s*Icon = "((?:[^"\\]|\\.)*)" \}') | ForEach-Object {
    [pscustomobject]@{ Title = $_.Groups[1].Value; Text = $_.Groups[2].Value; Icon = $_.Groups[3].Value.Replace('\"', '"') }
  })
  if (-not $applyUrl -or -not $perks) { throw "Couldn't read applyUrl or perks from _TradePage.cshtml" }

  function Enc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
  function Sub([string]$text, [object[]]$pairs) {
    foreach ($pair in $pairs) {
      if (-not $text.Contains($pair[0])) { throw "Couldn't find $($pair[0]) in _TradePage.cshtml" }
      $text = $text.Replace($pair[0], $pair[1])
    }
    $text
  }

  $start = $src.IndexOf('<div class="gm-trade">')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-trade""> in _TradePage.cshtml" }
  $h = $src.Substring($start)
  $h = Set-RazorBlock $h '@foreach \(var perk in perks\)\s*\{' { param($b)
    ($perks | ForEach-Object {
      Sub $b.Inner @(@('@Html.Raw(perk.Icon)', $_.Icon), @('@perk.Title', (Enc $_.Title)), @('@perk.Text', (Enc $_.Text)))
    }) -join ''
  }
  $h = Sub $h @(, @('@applyUrl', (Enc $applyUrl)))
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$))')
  if ($m.Success) { throw "_TradePage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  $h
}
