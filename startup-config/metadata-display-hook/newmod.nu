const mime_to_lang = {
  application/json: json
  application/xml: xml
  application/yaml: yaml
  text/csv: csv
  text/tab-separated-values: tsv
  text/x-toml: toml
  text/markdown: markdown
}

def classify []: record -> record {
  let md = $in
  let head = try { view span $md.span.start $md.span.end }
  match $md.content_type? {
    null => {{}}
    "application/x-nuscript" | "application/x-nuon" | "text/x-nushell" => { nu: true }
    $mimetype if $mimetype in $mime_to_lang => { bat: ($mime_to_lang | get $mimetype) }
    _ => {{}}
  }
  | insert head $head
  | insert source $md.source?
}

export def main [] {
  {
    metadata access {|meta| 
      do {|class|
        print ($class | table -e)
        match $class {
          { bat: $lang } => {
            let tempfile = (mktemp -t)
            $in | save -f $tempfile
            bat -pf --language=($lang) $tempfile
            rm $tempfile
          }

          { nu: true } => {
            let tempfile = (mktemp -t)
            $in | nu-highlight | save -f $tempfile
            bat -pf $tempfile
            rm $tempfile
          }

        
          { source: ls, head: ls } => { sort-by type name }
          { source: ls, head: l } => { sort-by type name | grid -ic }
          
          _ => {||}

        }
      } ($meta | classify)
    }
  }
}

export def default-display-hook [] {
  {
    if (term size).columns >= 100 { table -e } else { table }
  }
}
