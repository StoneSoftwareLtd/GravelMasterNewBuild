# The shared quantity calculator (Views/Shared/_QuantityCalculator.cshtml) for the previews. Dot-sourced by
# build.ps1 (the homepage) and product-page.ps1 (product pages), after category-page.ps1, whose Razor helpers
# it uses.
#
#   Format-QuantityCalculator  renders the partial with the given type chosen ("gravel", "mulch", "topsoil",
#                              "sand", or $null for the first)
#
# The markup comes from the .cshtml as it is, and the render fails if any Razor is left over.
# Keep this file ASCII: Windows PowerShell 5.1 reads .ps1 files without a byte order mark as ANSI.

function Format-QuantityCalculator([string]$templatePath, [string]$type) {
  $src = [IO.File]::ReadAllText($templatePath)
  $src = [regex]::Replace($src, '[ \t]*@\*[\s\S]*?\*@[ \t]*\r?\n?', '')   # Razor comments
  $types = @([regex]::Matches($src, 'new \{ Value = "([^"]+)", Label = "([^"]+)", Colour = "([^"]+)" \}') | ForEach-Object { [pscustomobject]@{ Value = $_.Groups[1].Value; Label = $_.Groups[2].Value; Colour = $_.Groups[3].Value } })
  if (-not $types) { throw "Couldn't read the types from _QuantityCalculator.cshtml" }

  $start = $src.IndexOf('<link href="/css/gm-calc.css')
  if ($start -lt 0) { throw "Couldn't find the gm-calc.css link in _QuantityCalculator.cshtml" }
  $h = $src.Substring($start)
  $h = Set-RazorBlock $h '@foreach \(var type in types\)\s*\{' { param($b)
    ($types | ForEach-Object {
      $t = $_
      $o = $b.Inner
      foreach ($pair in @(
          @('@(type.Value == Model.Type ? "selected" : "")', $(if ($t.Value -eq $type) { 'selected' } else { '' })),
          @('@type.Value', [Net.WebUtility]::HtmlEncode($t.Value)),
          @('@type.Colour', [Net.WebUtility]::HtmlEncode($t.Colour)),
          @('@type.Label', [Net.WebUtility]::HtmlEncode($t.Label)))) {
        if (-not $o.Contains($pair[0])) { throw "Couldn't find $($pair[0]) in _QuantityCalculator.cshtml" }
        $o = $o.Replace($pair[0], $pair[1])
      }
      $o
    }) -join ''
  }
  $m = [regex]::Match($h, '(?<![\w.])@(?!media\b|keyframes\b|font-face\b|import\b|supports\b)[A-Za-z(*{]|(?m)^\s*(?:(?:if|foreach|for|while)\s*\(|else\s*(?:\{|$))')
  if ($m.Success) { throw "_QuantityCalculator still contains Razor near: " + $h.Substring([Math]::Max(0, $m.Index - 80), [Math]::Min(160, $h.Length - [Math]::Max(0, $m.Index - 80))) }
  $h
}
