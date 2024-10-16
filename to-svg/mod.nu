# Public

export def tokenize_line [] {
  let line = $in
  
  # Find the indices of all ansi
  # formatting codes in the text
  let ansi_indices = (
    $line | str indices-of "\\e\\[.*?m"
    | upsert type { "ansi" }
    | rename -c { result: "content"}
    | update content { str replace --regex "\\e\\[(.*)m" "$1"}
  )

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
  let first_ansi_escape_start = (
    $ansi_indices | first | get begin
  )
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
  let last_ansi_escape_end = (
    $ansi_indices | last | get end
  )
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

# Private

export def "str indices-of" [pattern:string] string->list<int> {
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

def preface [] {
  $'
  <svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">
    <text x="10" y="40" font-family="monospace" font-size="14" fill="black" xml:space="preserve">
  '
}
def close [] {
  $'
    </text>
  </svg>
  '
}

def close_spans [level:int] {

}

def parse_rgb_color [] {
  str replace --all --regex $"(ansi esc)\\[38;2;\(.*?\);\(.*?\);\(.*?\)m\(.*?\)(ansi esc)\\[0m" '<tspan fill="rgb($1,$2,$3)">$4</tspan>'
}
def parse_ansi_color [] {
}

# existing_state: color or attributes from previous
# lines that have not yet been reset.
def process_ansi_in_line [preexisting_state = {}] {
  def create_result [html, unclosed_span_count] {
    { html: $html, unclosed_span_count: $unclosed_span_count }
  }

  def close_spans [ results ] {

  }

  let span_generator = {||
  }

  let line = $in



  print $spans

  let result_text = $spans | reduce -f (create_result "" 0) {|span,result|
    mut unclosed_span_count = 0;
    let escapes = ($span.escape? | default "")
    let codes = ($escapes | split row ';')
    let text = ($span.text? | default "")

    let add_html = match $codes {
      # ANSI reset - Close all unclosed tspans
      [ 0 ] => { close_spans $unclosed_span_count }
    }
    #print (create_result $text 0)
    create_result ($result.html + $text) 0
  }

  $result_text

}

export def "to svg" [] {
  let input = ($in | table -e | lines)

  let first_line = $'
        <tspan x="10" dy="00">($input.0)</tspan>
  '

  let remaining = (
    $input
    | skip
    | reduce -f '' {|it,acc|
        $acc ++ $'
              <tspan x="10" dy="18">($it)</tspan>
        '
    }
  )


  (preface) + $first_line + $remaining + (close)
  | lines
  | each { process_ansi_in_line }
}