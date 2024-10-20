# Nushell `to svg` command

Converts ANSI terminal output to SVG

## Installation

This is a Nushell module, currently in a monorepo with other Nushell code that you probably don't want to install.  To install just this module, you can do a sparse checkout of the directory.

1. Change to the directory where you want to install.  This can be a directory on your `$env.NU_LIB_DIRS` search path or any other directory.

   ```nu
   cd $env.NU_LIB_DIRS.0
   ```

2. Do a sparse-checkout of this module:

```nu
let package_dir = 'ntd'
mkdir $package_dir
git -C $package_dir init
git -C $package_dir remote add origin https://github.com/NotTheDr01ds/ntd-nushell_scripts.git
git -C $package_dir sparse-checkout set --no-cone --sparse-index to-svg
git -C $package_dir fetch --depth 1 --filter=blob:none origin main
git -C $package_dir checkout main
```

## Usage

1. Import the module:

   ```nu
   # Assuming the use of the "ntd" package/directory name above
   use ntd/to-svg *
   ```

2. Pass output of a command into `to svg`. E.g.:

   Note: Before passing `ls` to `to svg`, turn off the "clickable links" feature.

   ```nu
   $env.config.ls.clickable_links = false
   ls | to svg | save ls.svg
   ```

   The input can come from an external command as well:

   ```nu
   eza -l | lolcat -f | to svg | save eza.svg
   ```

   ```nu
   tmux clear-history
   # Do several things
   tmux capture-pane -peS - | to svg | save tmux.svg
   ```

## Features and Limitations

* Handles ANSI formatting for:
  * Foreground colors
  * Attributes:
    * Bold
    * Underline
    * Italic
    * Dimmed
    * Hidden
    * Blink

* Calculates the SVG height automatically.  Can be overridden with `--height` parameter

* Other parameters for:

  ```nu
  --fg-color
  --bg-color
  --font-size   (limited testing)
  --line-height (limited testing)
  ```

Does not currently support:

* Non-formatting terminal escapes like title-changes, cursor positioning, etc.  TODO: Attempt to strip those escapes from the input
* Text-background colors - This is planned
* Reverse - Planned
* ANSI formatting across line-breaks - Planned
* Calculating width from font size
* Less commonly used formatting codes such as font changes, Fraktur Script, overline, encircled, etc.