use ./mod-str-indices.nu "str indices-of"

def parse [filename: string] {
  let filename = ($filename | path expand)
  let code = (open $filename --raw)
  print $code

  let parsed = (nu --ide-ast $filename | from json)
  | reject type
  | flatten
  | sort-by start
  | move start --before end

  let prev_end = $parsed.end | prepend 0 | drop | wrap prev_end

  let nonAstTokens = (
    $parsed
    | merge $prev_end
    | insert gap {|r| $r.start - $r.prev_end}
    | where gap > 0
    | each {|r|
        { start: $r.prev_end, end: ($r.prev_end + $r.gap) }
      }
    | insert content {|r| $code | str substring ($r.start)..($r.end)}
    | insert shape {|r|
        match $r.content {
          $pattern if $pattern =~ '^\s*\n\s*$' => 'linebreak'
          $pattern if $pattern =~ '^\s*#' => 'comment'
          $pattern if $pattern =~ '^\s+$' => 'whitespace'
          $pattern if $pattern =~ '^\s+\=\s+$' => 'assignment_operator'
          $pattern if $pattern =~ '^\s*;\s*$' => 'multicommand_line'
        }
      }
  )

  let parsed = $parsed
  | append $nonAstTokens
  | sort-by start
  | reduce -f [] {|token,tokens|
      let previousNestingLevel = match ($tokens | length) {
        0 => 0
        _ => ($tokens | last | get nestingLevel)
      }

      let tokenNestingLevel = (
        match $token.shape {
          $shape if $shape in [ 
            shape_block
            shape_list
            shape_closure
            shape_record
          ] => {
            match ($token.content) {
              $t if ($t | str trim | str substring 0..1) in [ '(', '[', '{'] => ($previousNestingLevel + 1)
              $t if ($t | str trim | str substring (-1)..) in [ ')', ']', '}'] => ($previousNestingLevel - 1)
              _ => $previousNestingLevel

            }
          }
          _ => $previousNestingLevel
        }
      )

      $tokens | append {...$token, nestingLevel: $tokenNestingLevel }
    }

  $parsed
  | insert hasNewline {|token| $token.content =~ "\n"}

}

export def nu-format [filename] {
  let parsed = (parse $filename)
  $parsed
  
}