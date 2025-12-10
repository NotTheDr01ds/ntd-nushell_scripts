use std-rfc/kv *
$env.config.hooks.pre_execution ++= [(kv universal-variable-hook)]

use std/clip
tmux set -s set-clipboard on

overlay new help
overlay use std/help
#use std/help


