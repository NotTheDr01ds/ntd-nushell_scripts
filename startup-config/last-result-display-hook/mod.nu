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
    let last_result = (metadata access {|meta| do {} ($meta | kv set -t last_result _meta_tmp) } | stream limit)
    let capturing = try { if (kv get -t last_result LAST_RESULT | default true) { true } else { false } } catch { false }
    if $capturing {
      try { kv get -t last_result _3 | kv set -t last_result _4 }
      try { kv get -t last_result _2 | kv set -t last_result _3 }
      try { kv get -t last_result _1 | kv set -t last_result _2 }
      try { kv get -t last_result _  | kv set -t last_result _1 }
      try { kv set -t last_result _ $last_result }
      try { kv get -t last_result _meta3 | kv set -t last_result _meta4 }
      try { kv get -t last_result _meta2 | kv set -t last_result _meta3 }
      try { kv get -t last_result _meta | kv set -t last_result _meta2 }
      try { kv get -t last_result _meta_tmp | kv set -t last_result _meta }
    }
  }
}}

export def "_" [n?: int] {
  kv get -t last_result $"_($n)" | metadata set-from (kv get -t last_result $"_meta($n)")
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
