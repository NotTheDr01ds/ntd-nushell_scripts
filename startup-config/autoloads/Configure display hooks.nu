use metadata-display-hook *
use last-result-display-hook *

$env.config.hooks.display_output = {
  do (metadata-display-hook)
  | do (last-result-display-hook)
  | do (default-display-hook)
}

# Optionally, uncomment to disable capturing the last-result until reenabled
# use std-rfc/kv *
# kv set LAST_RESULT false
