export def "str unindent" [] {
  let text = $in
  let length = ($text | lines | length)

  # Drop first and last line if empty
  let lines = (
    $text
    | lines
    | wrap text
    | enumerate
    | flatten
    | filter {|line|
        match [
          $line.index
          ($line.text | str trim)
        ] {
          [0 ''] => false
          [($length - 1) ''] => false
          _ => true
        }

      }
  )

  let minimumIndent = (
    $lines | insert indent {|line|
      if ($line.text | str trim | is-empty) {
        null
      } else {
        $line.text
        | parse -r '^(?<indent>\s+)'
        | get indent.0?
        | default '' |
        str length
      }
    }
    | sort-by indent
    | first
    | get indent
  )

  let removeSpaces = ('' | fill -c ' ' -w $minimumIndent)

  $lines
  | update text {|line|
      $line.text 
      | str replace -r $'^($removeSpaces)' ''
    }
  | get text
  | to text

}

