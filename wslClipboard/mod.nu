export def wslClip [ ] {
  pwsh.exe -c $"Set-Clipboard @'
($in)
'@"

}

export def wslClipTable [ ] {

  pwsh.exe -c $"Set-Clipboard @'
($in | table | ansi strip)
'@"

}