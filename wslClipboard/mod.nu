export def wslClip [ ] {
  let text = match ($in | describe | str replace -r '<.*' '') {
    table => {$in | table -e}
    record => {$in | table -e}
    list => {$in | table -e}
    _ => {$in}
  }
  let tmpFile = (mktemp -t)
  $text | ansi strip | save --append $tmpFile
  pwsh.exe -c $"Set-Clipboard \(Get-Content (wslpath -w $tmpFile))"
  rm $tmpFile
}