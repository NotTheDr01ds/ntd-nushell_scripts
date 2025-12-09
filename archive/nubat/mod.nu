export def --wrapped main [...rest] {
  let pager = (
    $env.PAGER?
    | default ([ (which bat) (which less) ]
    | flatten
    | get 0.command)
  )
  let filename = ($rest | last | into glob)
  let args = match ($pager | path parse).stem {
    less => ($rest | drop | append '-R')
    _ => ($rest | drop)
  }
  open --raw $filename | nu-highlight | ^($pager) ...$args
}
