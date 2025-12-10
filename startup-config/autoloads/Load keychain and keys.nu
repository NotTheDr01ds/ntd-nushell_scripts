export-env {
  if $nu.is-interactive {
    ^keychain ...($env.SSH_KEYS_TO_AUTOLOAD | path expand)
    ^keychain --query --quiet
    | lines
    | parse "{name}={value}"
    | transpose -r
    | into record
    | load-env
  }
}
