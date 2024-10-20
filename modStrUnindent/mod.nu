# Remove common indent from a multi-line string
export def "str dedent" []: string -> string {
    let string = $in

    if ($string !~ '(?ms)^\s*\n') {
        return (error make {
            msg: 'First line must be empty.'
        })
    }

    if ($string !~ '(?ms)\n\s*$') {
        return (error make {
            msg: 'Last line must contain only whitespace indicating the dedent.'
        })
     }

    # Get number of spaces on the last line
    let indent = $string
        | parse -r '\n( *)$'
        | get 0.capture0
        | str length

    # Skip the first and last lines
    let lines = $string
        | lines
        | skip
        | drop
        | enumerate
        | rename lineNumber text

    let spaces = ('' | fill -c ' ' -w $indent)

    # Has to be done outside the replacement block or the error
    # is converted to text. This is probably a Nushell bug, and
    # this code can be recombined with the next iterator when
    # the Nushell behavior is fixed.
    for line in $lines {
        if ($line.text !~ '^\s*$') and ($line.text | str index-of --range 0..($indent) $spaces) == -1 {
            error make {
                msg: $"Line ($line.lineNumber + 1) must be indented by ($indent) or more spaces."
            }
        }
    }

    $lines
    | each {|line|
        # Don't operate on lines containing only whitespace
        if ($line.text !~ '^\s*$') {
            $line.text | str replace $spaces ''
        } else {
            $line.text
        }
      }
    | to text
}