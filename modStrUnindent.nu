export def "str unindent" [] {
  let text = $in
  let length = ($text | lines | length)

  let lines = $text | lines

  # Determine if first and/or last lines are empty and should be dropped
  let doNothing = {||}
  let ifSkipFirst = match ($lines | first | str trim) {
    "" => {{skip}}
    _ => {$doNothing}
  }
  let ifDropLast = match ($lines | last | str trim) {
    "" => {{drop}}
    _ => {$doNothing}
  }

  # Execute the conditional skip/drop logic
  let lines = (
    $lines
    | do $ifSkipFirst
    | do $ifDropLast
  )
  | # Convert list to table
  | wrap text

  let minimumIndent = (
    # Add a column to each row with the number of leading spaces
    $lines | insert indent {|line|
      if ($line.text | str trim | is-empty) {
        # If the line contains only whitespace, don't consider it
        null
      } else {
        $line.text
        | parse -r '^(?<indent> +)'
        | get indent.0?
        | default ''
        | str length
      }
    }
    | # And return the minimum
    | get indent
    | math min
  )

  let spaces = ('' | fill -c ' ' -w $minimumIndent)

  $lines
  | update text {|line|
      $line.text 
      | str replace -r $'^($spaces)' ''
    }
  | get text
  | to text

}

