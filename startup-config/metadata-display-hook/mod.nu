const mime_to_lang = {
  application/json: json
  application/xml: xml
  application/yaml: yaml
  text/csv: csv
  text/tab-separated-values: tsv
  text/x-toml: toml
  text/markdown: markdown
  text/x-rust: rust
}

const ext_to_lang = {
  py: python
  cpp: 'C++'
}

export def content-type-display-hook [] {
  {
    metadata access {|meta|
      match $meta.content_type? {
        null => { }

        "application/x-nuscript" | "application/x-nuon" | "text/x-nushell" => {
          let tempfile = (mktemp -t)
          $in | nu-highlight | save -f $tempfile
          bat -pf $tempfile
          rm $tempfile
        }

        $mimetype if $mimetype in $mime_to_lang => {
          let tempfile = (mktemp -t)
          $in | save -f $tempfile
          bat -pf --language=($mime_to_lang | get $mimetype) $tempfile
          rm $tempfile
        }

        "text/plain" => {
          let ext = ($meta.source | path parse | get extension)
          $in | if $ext in $ext_to_lang {
            let tempfile = (mktemp -t)
            $in | save -f $tempfile
            bat -pf --language=($ext_to_lang | get $ext) $tempfile
            rm $tempfile
          }
            
        }

        _ => {}
      }
    }
  }
}

export def ls-display-hook [] {
  {
    metadata access {|meta|
      if ($meta.source? == 'ls') {
        match (view span $meta.span.start $meta.span.end) {
          $x if $x in [ ls l ] => {
            if ($in | describe) =~ '^table<' {
              match (view span $meta.span.start $meta.span.end) {
                ls => { sort-by type? | table --icons }
                l => { sort-by type? | grid -ic }
                _ => { table --icons }
              }
            } else { }
          }
          # Captures `where` (and other filters) case.
          # Output will be sent to next display-hook
          # Output won't be sorted in this case.
          _ => { }
        }
      } else { }
    }
  }
}

export def default-display-hook [] {
  {
    if (term size).columns >= 100 { table --icons -e } else { table --icons }
  }
}

export alias l = ls

export-env {
  $env.config.hooks.display_output = {
    do (ls-display-hook)
    | do (content-type-display-hook)
    | do (default-display-hook)
  }
}
