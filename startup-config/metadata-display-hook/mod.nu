const mime_to_lang = {
  application/json: json
  application/xml: xml
  application/yaml: yaml
  text/csv: csv
  text/tab-separated-values: tsv
  text/x-toml: toml
  text/markdown: markdown
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

        _ => {}
      }
    }
  }
}

export def ls-display-hook [] {
  {
    metadata access {|meta|
      if $meta.source? == 'ls' {
        let $input = $in
        let command = try { view span $meta.span.start $meta.span.end }
        match $command {
          ls => { $input | try { sort-by type } catch { $input } | table}
          l => { $input | try { sort-by type | grid -ic } catch { $input } | table}
        }
      } else { }
    }
  }
}

export def default-display-hook [] {
  {
    if (term size).columns >= 100 { table -e } else { table }
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
