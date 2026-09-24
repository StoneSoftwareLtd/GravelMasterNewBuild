# The new About us page (Views/Content/_AboutPage.cshtml) for the previews. Dot-sourced by site-preview.ps1
# (localhost:8780/about-us), after category-page.ps1, whose Razor helpers it uses.
#
#   Format-AboutPage  renders the partial
#
# The page has no data from the site: its team and photos are listed in the partial's own C# block, which this
# reads. The markup comes from the .cshtml as it is, and the render fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

function Format-AboutPage([string]$templatePath) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $team = @([regex]::Matches($src, 'new \{ Name = "([^"]+)", Role = "([^"]+)", Photo = "([^"]+)" \}') | ForEach-Object { [pscustomobject]@{ Name = $_.Groups[1].Value; Role = $_.Groups[2].Value; Photo = $_.Groups[3].Value } })
  $photos = @([regex]::Matches($src, 'new \{ File = "([^"]+)", Alt = "([^"]+)", Width = (\d+), Height = (\d+) \}') | ForEach-Object { [pscustomobject]@{ File = $_.Groups[1].Value; Alt = $_.Groups[2].Value; Width = $_.Groups[3].Value; Height = $_.Groups[4].Value } })
  $slots = [regex]::Match($src, 'var slots = "(\w+)";').Groups[1].Value
  if (-not $team -or -not $photos -or $slots.Length -lt $photos.Count) { throw "Couldn't read team, inspiration or slots from _AboutPage.cshtml" }

  function Enc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
  function Sub([string]$text, [object[]]$pairs) {
    foreach ($pair in $pairs) {
      if (-not $text.Contains($pair[0])) { throw "Couldn't find $($pair[0]) in _AboutPage.cshtml" }
      $text = $text.Replace($pair[0], $pair[1])
    }
    $text
  }

  $start = $src.IndexOf('<div class="gm-about">')
  if ($start -lt 0) { throw "Couldn't find <div class=""gm-about""> in _AboutPage.cshtml" }
  $h = $src.Substring($start)
  $h = Set-RazorBlock $h '@foreach \(var member in team\)\s*\{' { param($b)
    ($team | ForEach-Object {
      Sub $b.Inner @(@('@(member.Photo)', (Enc $_.Photo)), @('@member.Name', (Enc $_.Name)), @('@member.Role', (Enc $_.Role)))
    }) -join ''
  }
  $h = Set-RazorBlock $h '@for \(var i = 0; i < inspiration\.Length; i\+\+\)\s*\{' { param($b)
    $inner = Get-LoopMarkup $b.Inner
    $out = for ($i = 0; $i -lt $photos.Count; $i++) {
      $p = $photos[$i]
      Sub $inner @(@('@photo.File', (Enc $p.File)), @('@photo.Alt', (Enc $p.Alt)), @('@photo.Width', $p.Width), @('@photo.Height', $p.Height), @('@slots[i]', [string]$slots[$i]))
    }
    $out -join ''
  }
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$))')
  if ($m.Success) { throw "_AboutPage still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  $h
}
