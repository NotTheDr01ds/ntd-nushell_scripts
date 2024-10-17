use std/util repeat

# Temporarily exported for testing
# Remove when done
export def tokenize_line [] {
  let line = $in
  
  # Find the indices of all ansi
  # formatting codes in the text
  let ansi_indices = (
    $line | str indices-of "\\e\\[.*?m"
    | upsert type { "ansi" }
    | rename -c { result: "content"}
    | update content { str replace --regex "\\e\\[(.*)m" "$1"}
    | update content { split row ";" | each { into int } }
  )

  # Return early if there were no tokens, only text
  if $ansi_indices == [] {
    return [{
      type: "text"
      content: $line
    }]
  }

  # Identify the indices of all gaps
  # between the ansi formatting codes
  let gaps = (
    $ansi_indices.end
    | zip ($ansi_indices.begin | skip)
    | each {|gap_set|
        {
          begin: $gap_set.0
          end: $gap_set.1
        }
      }
  )

  # If there's a text token before the first
  # ansi token, we need to include it
  let first_ansi_escape_start = try {
    $ansi_indices | first | get begin
  } catch { 0 }
  let opening_text = (
    if $first_ansi_escape_start > 0 {
      [{
        content: ($line | str substring 0..($first_ansi_escape_start - 1))
        begin: 0
        end: $first_ansi_escape_start
        #end: ($first_ansi_escape_start - 1)
        type: "text"
      }]
    } else {
      []
    }
  )

  # And if there's text after the last
  # ansi token, we need to include it
  let last_ansi_escape_end = try {
    $ansi_indices | last | get end
  } catch { $line | str length }
  let closing_text = (
    if ($last_ansi_escape_end < ($line | str length)) {
      [{
        content: ($line | str substring ($last_ansi_escape_end)..($line | str length))
        begin: $last_ansi_escape_end
        end: ($line | str length)
        type: "text"
      }]
    } else {
      []
    }
  )

  # Create a secondary table
  # with the text content that
  # comes "in the gaps" between
  # the ansi codes.
  let text_indices = (
    $gaps | each {|gap|
    let content = (
      $line | str substring ($gap.begin)..<($gap.end)
    )

    # Text content record matching the
    # ansi-record fields
    {
      content: $content
      begin: $gap.begin
      end: $gap.end
      type: "text"
    }
  }) ++ $opening_text ++ $closing_text

  # Combine the two tables
  [
    ...$ansi_indices
    ...$text_indices
  ]
  | sort-by begin
  | where content != ""

}

# Removes common indent from a multi-line string based on the number of spaces on the last line.
# 
# A.k.a. Unindent
#
# Example - Two leading spaces are removed from all lines:
#
# > let s = "
#      Heading
#        Indented Line
#        Another Indented Line
#
#      Another Heading
#      "
# > $a | str dedent
#
# Heading
#   Indented Line
#   Another Indented Line
#
# Another Heading
export def dedent []: string -> string {
    let string = $in

    if ($string | describe) != "string" {
        let span = (view files | last)
        error make {
            msg: 'Requires multi-line string as pipeline input'
            label: {
                text: "err::pipeline_input"
                span: {
                    start: $span.start
                    end: $span.end
                }
            }
        }
    }

    if ($string !~ '^\s*\n') {
        return (error make --unspanned {
            msg: $'($string)\nFirst line must be empty'
        })
    }

    if ($string !~ '\n\s*$') {
        return (error make {
            msg: 'Last line must contain only whitespace indicating the dedent'
        })
     }

    # Get number of spaces on the last line
    let indent = $string
        | str replace -r '(?s).*\n( *)$' '$1'
        | str length

    # Skip the first and last lines
    let lines = (
        $string
        | str replace -r '(?s)^[^\n]*\n(.*)\n[^\n]*$' '$1'
          # Use `split` instead of `lines`, since `lines` will
          # drop legitimate trailing empty lines
        | split row "\n"
        | enumerate
        | rename lineNumber text
    )

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
      # Remove the trailing newline which indicated
      # indent level
    | str replace -r '(?s)(.*)\n$' '$1'
}

def "str indices-of" [pattern:string] string->list<int> {
  let searchString = $in
  let parsePattern = [ '(?P<matches>', $pattern, ')' ] | str join
  let matches = ($searchString | parse -r $parsePattern | get matches)

  $matches | reduce -f [] {|match,results|
    let startSearchFrom = (
      if $results == [] { 0 } else { $results | last | get end }
    )

    let begin = ($searchString | str index-of $match --range ($startSearchFrom)..)
    let end = $begin + ($match | str length)
    
    $results | append {
      result: $match
      begin: $begin
      end: $end
    }
  }
}

export def "encode html-entities" []: [string -> string] {
    { tag: "s", content: [$in] }
    | to xml
    | str replace -r '(?ms)<s>(.*)</s>' '$1'
}

def preface [] {
  $'<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg"><text x="10" y="40" font-family="monospace" font-size="14" fill="black" xml:space="preserve">'
}
def close [] {
  $'</text></svg>'
}

def close_spans [] {
  let state = $in
  let close_spans = ('</tspan>' | repeat $state.span_level | str join '')
  $state | merge {
    html: ($state.html + $close_spans)
    span_level: 0
  }
}

# Original main magic to the PoC
def parse_rgb_color [] {
  str replace --all --regex $"(ansi esc)\\[38;2;\(.*?\);\(.*?\);\(.*?\)m\(.*?\)(ansi esc)\\[0m" '<tspan fill="rgb($1,$2,$3)">$4</tspan>'
}

def "state set-color" [
  --rgb: list<int>
  --xterm: int
  --sgb: int
] {


}

def create_tspan [] {
  let state = $in | close_spans

  let fill = match $state.text_color {
    [ $r, $g, $b ] => $"fill=\"rgb\(($r),($g),($b)\)\""
  }

  let font_weight = match $state.bold {
    true => 'font-weight="bold"'
  }

  let text_decoration = (
    match ([ $state.underline $state.strikethrough ] | any {$in == true}) {
      false => ""
      true => {
        [
          (if $state.underline { "underline" } else { "" })
          (if $state.strikethrough { "line-through" } else { "" })
        ]
        | str join ' '
        | $'text-decoration="($in | str trim)"'
      }
    }
  )

  let attr_set = [ $fill, $font_weight, $text_decoration ]
  | where $it != ''
  | where $it != null
  | str join ' '

  # Return the state with the updated HTML
  $state
  | merge (
      match $attr_set {
        '' => {{}}
        _ => {
          html: ($state.html + $'<tspan ($attr_set)>')
          span_level: ($state.span_level + 1)
        }
      }
  )
}

def attribute_state [attr_id] {
  match $attr_id {
    1 => { bold: true }
    2 => { dimmed: true }
    3 => { italics: true }
    4 => { underline: true }
    9 => { strikethrough: true }
    _ => {}
  } 
}

# existing_state: color or attributes from previous
# lines that have not yet been reset.
export def process_line_tokens [preexisting_state = {}] {

  let tokens = ($in | tokenize_line)

  # Initial state
  # Currently new state for each line
  # But needs to preserve existing state
  # from previous line(s)
  let default_state = {
    text_color: null
    text_background: null
    bold: false
    italics: false
    underline: false
    strikethrough: false
    reverse: false
    dimmed: false
    blink: false
    hidden: false

    html: ""
    span_level: 0
  }

  # Reduce tokens to a state.
  # Each token results in a new state.
  # New state is merged into cumultative state.
  # State includes the current HTML text.
  let line_state = ($tokens | reduce -f $default_state {|token,state|
    let new_state = match $token.type {
      'ansi' => {
        match $token.content {
          # ANSI Reset
          [ 0 ] => {
            $state
            | close_spans
            # Reset everything to defaults except the html
            | merge ($default_state | reject html)
          }

          # Set color via RGB
          [ 38 2 $r $g $b ] => {
            {
              text_color: [$r, $g, $b]
            }
          }
          
          # attribute alone
          [ $attr ] if ($attr in 1..9) => {
            attribute_state $attr
          }

          # attribute followed by an RGB color
          [ $attr $r $g $b ] if ($attr in 1..9) => {
            (attribute_state $attr)
            # TODO - Merge color
          }
          # Otherwise, no state change for
          # unimplemented attributes
          _ => {
            print ("No match found for: \n" + ($token.content | table -e ))
            {
            }
          }
        }
      }
      'text' => {
        {
          html: ($state.html + $token.content)
        }
      }
    }

    $state
    | merge (
        match $token.type {
          # If it was a text token,
          # then the state already has
          # the updated HTML from above
          'text' => $new_state

          # Otherwise we need to calculate
          # the new tspan from the attributes
          # and merge the updated HTML in
          'ansi' => { 
            $state | merge $new_state | create_tspan 
          }
          # 'ansi' => { $state | merge $new_state }

          _ => {{}}
        }
      )
    }
  )

  # Right now, returning HTML, but we
  # need to return the full state in case
  # it crosses to the next line
  $line_state | close_spans | get html
}

export def "to svg" [] {
  let input = (
    $in
    | table -e
    | lines
    | each { encode html-entities }
    | each { process_line_tokens }
  )

  let first_line = $'<tspan x="10" dy="00">($input.0)</tspan>'

  let remaining = (
    $input
    | skip
    | reduce -f '' {|it,acc|
        $acc ++ $'<tspan x="10" dy="18">($it)</tspan>'
    }
  ) | default ""

  ((preface) + $first_line + $remaining + (close))
  | to text
}