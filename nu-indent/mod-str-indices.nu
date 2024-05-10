export def "str indices-of" [substring:string] string->list<int> {
  let s = $in
  let indicesGenerator = {|startSearchFrom|
    let foundAtIndex = ($s | str index-of $substring --range $startSearchFrom..)
    let startNextSearchFrom = ($foundAtIndex + 1)
    match $foundAtIndex {
      -1 =>  {{}}
      _  => {{out: $foundAtIndex, next: ($foundAtIndex + 1)}}
    }
  }

  generate 0 $indicesGenerator
}