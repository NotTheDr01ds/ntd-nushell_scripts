use std-rfc/kv *

# return closure rather than calling command from a closure,
# since calling a closure is one call but calling a command inside a closure is two calls
def "stream reduce" [] {
  {|it, acc|
    if $acc == null { return }
    if ($acc | length) >= ($env.NU_LAST_RESULT_LIMIT | default --empty 10_000) { return }
    try { return ([$acc $it] | bytes collect) }
    $acc | append $it
  }
}

def "stream limit" [] {
  let out = try { chunks 1 | reduce (stream reduce) } catch { false }
  if $out != false { return $out }
  $in
}

def "metadata set-from" [metadata?: record] {
  if $metadata.source? != null {
    if $metadata.source == "ls" {
      metadata set --datasource-ls
    } else {
      metadata set --datasource-filepath $metadata.source
    }
  } else {
    do {}
  }
  | if $metadata.content_type? != null {
    metadata set --content-type $metadata.content_type
  } else {
    do {}
  }
}

export def main [] {{
  tee {
    let last_result = (metadata access {|meta| do {} ($meta | kv set _meta_tmp) } | stream limit)
    let capturing = try { if (kv get LAST_RESULT | default true) { true } else { false } } catch { false }
    if $capturing {
      kv get _3 | kv set _4
      kv get _2 | kv set _3
      kv get _1 | kv set _2
      kv get _  | kv set _1
      kv set _ $last_result
      kv get _meta3 | kv set _meta4
      kv get _meta2 | kv set _meta3
      kv get _meta | kv set _meta2
      kv get _meta_tmp | kv set _meta
    }
  }
}}

export def "_" [n?: int] {
  kv get $"_($n)" | metadata set-from (kv get $"_meta($n)")
}

export-env {
  $env.NU_LAST_RESULT_LIMIT = 10_000
#  $env.config.hooks.display_output = {||
#    main | if (term size).columns >= 100 { table -e } else { table }
#  }
}

export const last_result_keybinding = {
  name: last_result,
  modifier: control
  keycode: char_-,
  mode: [emacs vi_normal vi_insert]
  event: [{ edit: InsertString, value: "(_)" }]
}

export def default-display-hook [] {
  {
    if (term size).columns >= 100 { table -e } else { table }
  }
}
