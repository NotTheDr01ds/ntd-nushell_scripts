use oh-my.nu *
$env.TRANSIENT_PROMPT_COMMAND = { (git_prompt).left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| date now | format date "%d-%a %r" }
$env.PROMPT_MULTILINE_INDICATOR = '::: '
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = ""
$env.TRANSIENT_PROMPT_INDICATOR = " "
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = " "
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = " "
#$env.TRANSIENT_PROMPT_INDICATOR = ">>>>>>>>> "
#$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ">>>>>>>>> "
#$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ">>>>>>>>> "
$env.TRANSIENT_PROMPT_INDICATOR_RIGHT = ""
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = ""

$env.old_TRANSIENT_PROMPT_COMMAND = {
  try {
    stor create -t kv -c { k: str, v: str } | ignore 
    stor insert -t kv -d { k: 'prev_prompt_dir', v: "xo.dummy-dir.xo"}
  }
  let prev_prompt_dir = (
  )
  let prev_prompt_dir = (
    stor open
    | wrap temp | get temp
    | get kv
    | where k == 'prev_prompt_dir'
    | last 
    | get v
  )

  let changed_dir = ((pwd) | path expand) != ($prev_prompt_dir | path expand)

  #let success = match $env.LAST_EXIT_CODE {
    #0 => true
    #_ => false
  #}

  #let background = match $success {
  #  true => {{|| ansi gradient --bgstart '0x0000ff' --bgend '0x00ffff' --fgstart '0x000000' --fgend '0x000000' }}
  #  false => {{|| ansi gradient --bgstart '0x800000' --bgend '0xff8000' --fgstart '0x000000' --fgend '0x000000' }}
  #  #false => {{|| ansi gradient --bgstart '0xff0000' --bgend '0xFFB0B0' --fgstart '0x000000' --fgend '0x000000' }}
  #}

  if $changed_dir {
    (
      stor update
        -t kv
        -u { k: 'prev_prompt_dir', v: (pwd) }
        -w "k = 'prev_prompt_dir'"
    )

    let in_home = try {
      '~' | path join (pwd | path relative-to ~)
      true
    } catch {
      false
    }

    let home_relative = try {
      '~' | path join (pwd | path relative-to ~) | str replace -r $"(char path_sep)\\$" ""
    } catch {
      pwd
    }

    let paths = ($home_relative | path split)

    let dir = if ($paths | length) > 3 {
      [ $paths.0, '...', ...($paths | range (-2)..)] | path join
    } else {
      $paths | path join
    }

    #let term_width = (term size).columns
    #let inner_background = {|| ansi gradient --bgstart '0x00ffff' --bgend '0x0000ff' --fgstart '0x000000' --fgend '0x000000' }
    #let outer_background = {|| ansi gradient --bgstart '0x0000ff' --bgend '0x00ffff' --fgstart '0x000000' --fgend '0x000000' }
    #let inner_text = (
      #$dir
      #| do $inner_background
      #| $"(ansi '#00ffff')(ansi reset)($in)(ansi '#0000ff')(ansi reset)(char lf)(char lf)"
    #)
    #let outer_text = (
      #'' | fill --width ($term_width - 2) -c ' '
      #| do $outer_background
      #| $"(ansi '#0000ff')(ansi reset)($in)(ansi '#00ffff')(ansi reset)(char lf)(char lf)"
    #)

    #let inner_start = ($inner_text | str length -g) // 2
    #let left_text = $outer_text | str substring 0..<($inner_start)
    #let right_start = $inner_start + ($inner_text | str length -g)
    #let right_text = $outer_text | str substring $right_start..($outer_text | str length -g)
    #$"($left_text)($inner_text)($right_text)"

    let width = (
      (term size).columns
      | [($in - 2), 60]
      | math min
    )
    let background = {|| ansi gradient --bgstart '0x0000ff' --bgend '0x00ffff' --fgstart '0x000000' --fgend '0x000000' }
    $dir | fill --width $width  -c ' ' --alignment center
    | do $background
    | $"(ansi '#0000ff')(ansi reset)($in)(ansi '#00ffff')(ansi reset)(char lf)(char lf)"

  } else {
    "\n"
  }
}

