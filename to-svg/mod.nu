use std/util repeat

const default_state = {
  text-color: null
  text-background: null
  bold: false
  italics: false
  underline: false
  strikethrough: false
  reverse: false
  dimmed: false
  blink: false
  hidden: false

  background_indices: []
  tspans: []
}

# Temporarily exported for testing
# Remove when done
def tokenize_line [] {
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

def svg-boilerplate [
  --width (-w): string
  --height(-h): string
  --fg-color (-f): string
  --bg-color (-b): string
  --line-height: int
  --font-size: int
] {

  {
    tag: "svg"
    attributes: {
      width: $"($width)"
      height: $"($height)"
      xmlns: "http://www.w3.org/2000/svg"
    }
    content: [
      {
        tag: style
        content: [ "
tspan {
  white-space: pre;
}
" ]
      }
      {
        tag: "rect"
        attributes: {
          width: "100%"
          height: "100%"
          fill: $"($bg_color)"
        }

      }
      {
        tag: "text"
        attributes: {
          x: "10"
          y: "20"
          font-family: "monospace"
          font-size: $"($font_size)"
          fill: $"($fg_color)"
          #'xml:space': "preserve"
        }
      }
    ]
  }
}

def "into list" [] {
  each {||}
}

def sgr-ranges [] {
  [
    ...(30..37 | into list)
    ...(90..97 | into list)
    ...(40..47 | into list)
    ...(100..107 | into list)
  ]
}

def attribute-ranges [] {
  [
    ...(1..9 | into list)
    ...(21..29 | into list) # Reset individual attributes
  ]
}

def basic-colors [] {
  [
    # Standard (Start at 30 for foreground, 40 for background)
    [0, 0, 0]         # Black
    [205, 0, 0]       # Red/Maroon
    [0, 205, 0]       # Green
    [205, 205, 0]     # Yellow/Olive
    [0, 0, 238]       # Blue/Navy
    [205, 0, 205]     # Magenta/Purple
    [0, 205, 205]     # Cyan/Teal
    [229, 229, 229]   # White/Silver
    # Bright Colors (Standrd index + 60)
    [127, 127, 127]   # Bright Black (Gray)
    [255, 0, 0]       # Bright Red/Red
    [0, 255, 0]       # Bright Green/Lime
    [255, 255, 0]     # Bright Yellow/Yellow
    [92, 92, 255]     # Bright Blue/Blue
    [255, 0, 255]     # Bright Magenta/Fuchsia
    [0, 255, 255]     # Bright Cyan/Aqua
    [255, 255, 255]    # Bright White/White
  ]
}

# Returns a state record where the color is set to foreground
# or background RGB value
def set-color [color, --background, --color-type: string] {
  let attr = match $background {
    true => "text-background"
    false => "text-color"
  }
  
  match $color_type {
    sgr => {
      match $color {
        $std_fg if $std_fg in 30..37 => {
          text-color: ((basic-colors) | get ($std_fg - 30))
        }
        $bright_fg if $bright_fg in 90..97 => {
          text-color: ((basic-colors) | get ($bright_fg - 82))
        }
        $std_bg if $std_bg in 40..47 => {
          text-background: ((basic-colors) | get ($std_bg - 40))
        }
        $bright_bg if $bright_bg in 100..107 => {
          text-background: ((basic-colors) | get ($bright_bg - 92))
        }
      }
    }

    xterm => {
      match $color {
        # Primary and Bright Colors
        0..15 => ((basic-colors) | get $color)

        # RGB Color Cube
        16..231 => {
          let cube_index = $color - 16
          # Calculated Red, Green, Blue values
          [
            ($cube_index // 36 * 51)
            ($cube_index mod 36 // 6 * 51)
            ($cube_index mod 36 mod 6 * 51 )
          ]
        }

        # Grayscale
        232..255 => {
          let gray = ($color - 232) * 10 + 8
          [ $gray, $gray, $gray ]
        }
      }
      | {
        $attr: $in
      }
    }

    _ => {
      match $color {
        [ $r $g $b ] => { $attr: $color }
      }
    }
  }
}

def create-tspan [text] {
  let state = $in

  let fill = match $state.text-color {
    [ $r, $g, $b ] => {
      $"rgb\(($r),($g),($b)\)"
    }
  }

  let font_weight = match $state.bold {
    true => 'bold'
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
        | $'($in | str trim)'
      }
    }
  )

  let font_style = match $state.italics {
    true => 'italic'
  }

  let opacity = match $state.dimmed {
    true => '0.5'
  }

  let opacity = match $state.hidden {
    true => '0'
  }

  let attributes = {
    fill: $fill
    font-weight: $font_weight
    text-decoration: $text_decoration
    font-style: $font_style
    opacity: $opacity
  }
  | transpose attr value
  | where value != null and value != ""
  | transpose -dr 
  | if $in == [] {{}} else $in

  # Add an animate tag when blink is set.
  let content = ([ $text ] ++ (
    match $state.blink {
      true => {
        tag: "animate"
        attributes: {
          attributeName: "opacity"
          values: "1;0.33;1"
          dur: "1.5s"
          repeatCount: "indefinite"
        }
      }
      false => {
        []
      }
    }
  ))

  let res = {
    tag: 'tspan'
    attributes: $attributes
    content: $content
  } 
  $res
}

def attribute-state [attr_id] {
  match $attr_id {
    1 => { bold: true }
    2 => { dimmed: true }
    3 => { italics: true }
    4 => { underline: true }
    5 => { blink: true }
    7 => { reverse: true }
    8 => { hidden: true }
    9 => { strikethrough: true }
    21 => { bold: false }
    22 => { dimmed: false }
    23 => { italics: false }
    24 => { underline: false }
    25 => { blink: false }
    27 => { reverse: false }
    28 => { hidden: false }
    29 => { strikethrough: false }
    _ => {{}}
  } 
}

# Input: A list of ANSI formatting
# codes from a token.content
# Output: Attribute state
def process-attributes [attrs: list] {
  let state = ($in | default {})
  mut remaining = []

  # Each match arm returns a subset of a state
  # that is *merged* with the current state to
  # produce a new state
  # "subset" example: { text_color: [ 0, 0, 0 ]}
  # 
  # In each match arm, we need to capture codes that
  # remain after the match so that they can be 
  # recursed
  let new_state = ($state | merge (
    match $attrs {
      # ANSI Reset
      [ 0 ..$rest ] => {
        # Reset everything to defaults except for the tspan collector
        $remaining = $rest
        $default_state | reject tspans
      }

      # Set color via RGB
      [ 38 2 $r $g $b ..$rest ] => {
        $remaining = $rest
        set-color [ $r $g $b ]
      }

      # Set a background color via RGB
      # TODO
      [ 48 2 $r $g $b ..$rest ] => {
        $remaining = $rest
        {}
      }
      
      # Attribute alone
      [$attr ..$rest] if ($attr in (attribute-ranges)) => {
        $remaining = $rest
        attribute-state $attr
      }

      # Attribute + SGR color
      # Commenting out, since this will be handled via recursion instead
      #[ $attr $sgr_color ] if ($attr in 1..9) and ($sgr_color in (sgr-ranges)) => {
      #  (attribute-state $attr)
      #  | merge (set-color --color-type sgr $sgr_color)
      #}

      # SGR color
      [ $sgr_color ..$rest] if ($sgr_color in (sgr-ranges)) => {
        $remaining = $rest
        set-color --color-type sgr $sgr_color
      } 

      # Commented since this should be recursed now
      # Attribute followed by an RGB color
      #[ $attr 38 2 $r $g $b ] if ($attr in 1..9) => {
        #(attribute-state $attr)
        #| merge (set-color [$r, $g, $b])
      #}

      # xterm colors
      [ 38 5 $xcolor  ..$rest ] => {
        $remaining = $rest
        (set-color $xcolor --color-type xterm)
      }

      # Recursed now
      # Attr + xterm Color
      #[ $attr 38 5 $xcolor ] if ($attr in 1..9) => {
        #(attribute-state $attr)
        #| merge (set-color $xcolor --color-type xterm)
      #}

      # Default foreground
      [ 39 ..$rest] => {
        $remaining = $rest
        { text-color: null }
      }

      # Default background
      [ 49 ..$rest ] => {
        $remaining = $rest
        { text-background: null }
      }

      # Otherwise, no state change for
      # unimplemented attributes
      # Note: We need to capture these so that
      # we can at least recurse the next set if
      # present
      [ $unknown ..$rest ] => {
        $remaining = $rest
        print ("No match found for: \n" + ($unknown | table -e ))

        {
        }
      }
      _ => {
        print "ERROR"
        error make --unspanned { msg: "Should never fail a match"}
      }
    }
  ))

  # Return
  match $remaining {
    # Return the new state if there's nothing left to process
    null => $new_state
    # Or merge the recursion otherwise
    $rest => {
      $new_state | process-attributes $rest
    }
    _ => { print "Error - Fell through" }
  }
}

# existing_state: color or attributes from previous
# lines that have not yet been reset.
def process_line_tokens [preexisting_state?] {
  let tokens = ($in | tokenize_line)
  let starting_line_state = ($preexisting_state | default $default_state)

  # Initial state
  # Currently new state for each line
  # But needs to preserve existing state
  # from previous line(s)

  # Reduce tokens to a state.
  # Each token results in a new state.
  # Changes are merged into cumultative state.
  $tokens | reduce -f $starting_line_state {|token,state|
    $state | merge (
      match $token.type {
        # ANSI formatting escapes just change the state of the 
        # attributes needed for the tspan
        'ansi' => {
          process-attributes $token.content
        }

        # When we find a text token, we
        # create a new tspan based on the
        # ANSI attributes in the current state
        'text' => {
          {
            tspans: ($state.tspans ++ ($state | create-tspan $token.content))
          }
        }
      }
    )
  }
}

export def "to svg" [
  --width (-w): string = "800"
  --height(-h): string
  --fg-color (-f): string       # Foreground color, using "#rrggbb" values
  --bg-color (-b): string      # Background color, using #rrggbb" values
  --line-height: int = 16
  --font-size: int = 14
] {
  # Warning: Don't use $in here - It eats the metadata and won't
  # properly handle lscolors.  Because we can't collect $in, 
  # this assignment *must* be the first line in the command
  let line_states = (
    table -e
    | lines
    #| each { tee { table -e | encode utf-8 | print $in }}
    #| each { process_line_tokens }
    | reduce -f [] {|line,line_states|
        let previous_line_state = match ($line_states | length) {
          # First line gets default state
          0 => $default_state
          # Subsequent lines take on state of the previous line
          # minus the content (tspans)
          _ => ($line_states | last | merge { tspans: [] })
        }
        let line_state = ($line | process_line_tokens $previous_line_state)
        $line_states ++ $line_state
      }
  )

  let fg_color = (
    $fg_color
    | default $env.config?.color_config?.foreground?
    | default "#a5a2a2"
  )
  let bg_color = (
    $bg_color
    | default $env.config?.color_config?.background?
    | default "#090300"
  )

  let xml_tspans = (
    $line_states
    | enumerate | flatten
    | each {|line|
        let dy = match $line.index {
          0 => "0"
          _ => ($line_height | into string)
        }

        # If the line is empty, insert a zero-width
        # space so that the tspan doesn't get collapsed
        # by `dy`
        let tspans = match $line.tspans.content {
          [[ "" ]] => {
            #$line.tspans | upsert content { [ '&#8203;' ] }
            $line.tspans | upsert content { [ ("<tspan>&#8203;</tspan>" | from xml) ] }
          }
          _ => $line.tspans
        }

        {
          tag: 'tspan'
          attributes: {
            x: "10"
            dy: $dy
          }
          content: [
            ...$tspans
          ]
        }
      }
  )

  let num_lines = ($xml_tspans | length)
  let height = (
    $height
    | default ($num_lines * $line_height + 20)
  )


  let svg_boilerplate = (
    svg-boilerplate
      --width $width
      --height $height
      --fg-color $fg_color
      --bg-color $bg_color
      --line-height $line_height
      --font-size $font_size
  )
  
  $svg_boilerplate
  | upsert content.2.content $xml_tspans
  | to xml
}
