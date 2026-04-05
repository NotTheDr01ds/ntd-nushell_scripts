# Installation

## Using [Nubrew](https://github.com/nubrew/nubrew)

```nushell
http get https://raw.githubusercontent.com/NotTheDr01ds/ntd-nushell_scripts/refs/heads/main/startup-config/last-result-display-hook/nubrew.nuon | nubrew install
```

# Configuration

## The `display-output` Hook

The main feature relies on a Nushell `display-output` hook.
It works by capturing the Nushell output into a key-value store where the most recent 5 results are kept.

Nushell only allows "one" `display-output` hook, but it is possible
to chain together multiple closures in a pipeline. To install the
`last-result-display-hook`
along with the `default-display-hook` (provided):

```nushell
use last-result-display-hook

$env.config.hooks.display_output = {
  do (ls-display-hook)
  | do (default-display-hook)
}
```

Additional hooks, such as [this one to handle different content types](https://github.com/NotTheDr01ds/ntd-nushell_scripts/tree/main/startup-config/metadata-display-hook)
can be inserted before or after. For example:

```nushell
use metadata-display-hook *
use last-result-display-hook *

$env.config.hooks.display_output = {
  do (content-type-display-hook)
  | do (last-result-display-hook)
  | do (default-display-hook)
}
```

## The Pre-exec Hook

This feature also uses a `pre-execution` hook that stores the current commandline.
This allows the `last-result-display-hook` (above) to only modify the last result
when it is being changed. Simply inspecting a result will not result in changes
to the last-result stack.

To install this hook:

```nushell
$env.config.hooks.pre-execution ++= [(last-result-pre-exec-hook)]
```

## Persisting

Add the configuration above to any `.nu` file in `$nu.default-config-dir/autoload` to have
it loaded at startup.

Note that the `default-display-hook` included in this package enables file icons in `ls` and requires
a [Nerd Font](https://www.nerdfonts.com) such as [CaskaydiaCove](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip)
or similar which provides the required glyphs.

# Usage

* The results of most Nushell commands will be stored.
* External command results are not typically stored, but can be forced (see below).
* The `_` command is used to retrieve the last result.
* The `_` commmand also accepts a numeric argument for older results (e.g., `_ 2` to retrieve the output from the two commands back).
* The 5 most recent results are stored.
* Nulls and empty strings are not stored.
* The output of the `_` command itself is not stored, so that previous result positions don't change.
* Capturing can be temporarily disabled with:

  ```nushell
  kv set -t last_result is_capturing false
  ```

* Side-note: The first command captured in any Nushell session is usually the `banner` command,
  since it executes at the end of the startup and outputs the results.

## Examples

Edit a file given its position in the `ls` results:

```nushell
# Change to your user-autoload directory
$nu.default-config-dir | path join 'autoload' | cd $in
ls
# => ╭────┬───────────────────────────────────────────┬──────┬────────┬──────────────╮
# => │  # │                   name                    │ type │  size  │   modified   │
# => ├────┼───────────────────────────────────────────┼──────┼────────┼──────────────┤
# => │  0 │ 00.nubrew-set-lib-path.nu                 │ file │  116 B │ 6 months ago │
# => │  1 │ Commonly used Standard Library imports.nu │ file │  402 B │ a week ago   │
# => │  2 │ Configure History.nu                      │ file │  339 B │ a month ago  │
# => │  3 │ Configure display hooks.nu                │ file │  512 B │ an hour ago  │
# => │  4 │ Load keychain and keys.nu                 │ file │  246 B │ 3 months ago │
# => │  5 │ Load theme.nu                             │ file │   79 B │ 3 months ago │
# => │  6 │ buffer_editor.nu                          │ file │   33 B │ a year ago   │
# => │  7 │ ide-completions.nu                        │ file │   20 B │ 3 months ago │
# => │  8 │ inactive                                  │ dir  │ 4.0 kB │ 3 months ago │
# => │  9 │ keybindings                               │ dir  │ 4.0 kB │ a year ago   │
# => │ 10 │ keybindings.nu                            │ file │  317 B │ a week ago   │
# => │ 11 │ prompt.nu                                 │ file │ 3.5 kB │ a year ago   │
# => │ 12 │ seUtils.nu                                │ file │   58 B │ a year ago   │
# => ╰────┴───────────────────────────────────────────┴──────┴────────┴──────────────╯

hx (_ | get name.5)
# => Edits the "Load theme.nu" file
# Note, since hx is an external command, it does not modify the last-result stack, so
# after exiting Helix, you can immediately edit another file with:
hx (_ | get name.2)
```

Work with REST APIs:

```nushell
http get https://api.github.com/repos/nushell/nushell/releases
# => A very large table with Github details on the 30 most recent Nushell releases
_ | columns
# => The list of column names in the table
_ 1 | select name
# => A much more readable table with just the release names
# Let's put the full table back on the "top" of the last-result stack
# First, confirm that `_ 2` is the correct position
_ 2
# => The full table - Confirmed
# Note that this doesn't change the stack. Confirm by running `_ 2` again.
_ 2
# => Same full table
# Move it back to the `_` position
_ 2 | $in
# => You'll see the table output
# Confirm it is in the top position once again
_
# => Yes, that's the full table
_ | select name published_at
# => Releases and dates
_ | update published_at { into datetime }
# => Same table, but updated with Nushell datetime types
_ | rename Name Published
# => Columns renamed
```

Format data for clipboard:

```nushell
# Get a value plus 10%
1_430_235 * 0.110
# => 157325.85

# Copy it to the clipboard
_ | clip copy

# Format an ls table with comment prefix and copy it
ls
# => ╭───┬─────────────┬──────┬────────┬──────────────╮
# => │ # │    name     │ type │  size  │   modified   │
# => ├───┼─────────────┼──────┼────────┼──────────────┤
# => │ 0 │ README.md   │ file │ 2.6 kB │ 2 hours ago  │
# => │ 1 │ mod.nu      │ file │ 3.2 kB │ 2 hours ago  │
# => │ 2 │ nubrew.nuon │ file │  222 B │ 3 months ago │
# => ╰───┴─────────────┴──────┴────────┴──────────────╯

# Need to remove the ANSI codes before modifying
_ | ansi strip
# => # ╭───┬───────────────────╮
# => # │ 0 │ {record 4 fields} │
# => # │ 1 │ {record 4 fields} │
# => # │ 2 │ {record 4 fields} │
# => # ╰───┴───────────────────╯

# Oops - That's not right. We need to expand the table before removing the ANSI codes
_ 1 | table -e | ansi strip
# => ╭───┬─────────────┬──────┬────────┬──────────────╮
# => │ # │    name     │ type │  size  │   modified   │
# => ├───┼─────────────┼──────┼────────┼──────────────┤
# => │ 0 │ README.md   │ file │ 2.6 kB │ 2 hours ago  │
# => │ 1 │ mod.nu      │ file │ 3.2 kB │ 2 hours ago  │
# => │ 2 │ nubrew.nuon │ file │  222 B │ 3 months ago │
# => ╰───┴─────────────┴──────┴────────┴──────────────╯

# Add a prefix
use std/clip prefix
_ | prefix '# => '
# => # => ╭───┬─────────────┬──────┬────────┬──────────────╮
# => # => │ # │    name     │ type │  size  │   modified   │
# => # => ├───┼─────────────┼──────┼────────┼──────────────┤
# => # => │ 0 │ README.md   │ file │ 2.6 kB │ 2 hours ago  │
# => # => │ 1 │ mod.nu      │ file │ 3.2 kB │ 2 hours ago  │
# => # => │ 2 │ nubrew.nuon │ file │  222 B │ 3 months ago │
# => # => ╰───┴─────────────┴──────┴────────┴──────────────╯
_ | clip copy
```
