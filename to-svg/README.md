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
   ls | to svg --width 560 | save ls.svg
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

## Tips

* Use a width that fits your content, with a comfortable margin.  Add 5-10% additional margin for browsers that may use a wider monospace font (e.g., Safari on iOS).
* As mentioned above, turn off clickable links before passing an `ls` command to `to svg`

## Features and Limitations

* Handles ANSI formatting for:
  * Foreground and Background Colors
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
* Reverse - Planned
* Calculating width from font size
* Less commonly used formatting codes such as font changes, Fraktur Script, overline, encircled, etc.

## Design Notes

* **Font sizes:** There is unfortunately no good way to guarantee that the width of the parent SVG element will match the contents across browsers. There is no monospace font that is pre-installed on all platforms, so each browser/platform is going to have a slightly different monospace font.

  While the height of any font can, of course, be specified, different fonts will have different character widths -- Even for monospace fonts.  While we might could use the `ch` (character) size to specify a width that matches the number of characters (plus margin), this is a CSS3 feature that does not work in Safari.

  We might also consider using a web-font for consistency, but (a) embedding it would defeat the size-advantage of SVG, and (b) linking is not supported in Safari in a `<style>` block (but is on other Chromium-browsers).

  Some ANSI->SVG converters deal with this by specifying the exact X and (sometimes) Y location at which to draw either (a) each character of the output, or (b) each span.  Neither of these, IMHO, result in acceptable output. The resulting image typically has gaps between line-drawing characters (very common in Nushell) or poor scaling. An example from the `ansi2` crate can be found [here](https://github.com/NotTheDr01ds/ntd-nushell_scripts/issues/4#issuecomment-2433052165).

  The end-result is that, for example, text that fits comfortably in a certain SVG width on one platform can have a much wider gap on other platforms.  This normally would lead to an unseemly large right-margin.

  **Current `to svg` Solution:**  To display on all platforms as asthetically as possible, the content is "centered" between the margins, based on the width of the longest line.

  That leads us to the next hurdle ...

* **Centering Text:** It is difficult to believe, but SVG seems to have no way of centering a `<text>` tag's contents equally between the margins. The child `<tspan>` tags much each specify an `X` value for each new line, and specifying `x="50%"` will center each line, rather than the parent block.

  (Insert sob story about ChatGPT getting into a loop where it continued to suggest the same three solutions, none of which worked, ad nasuem).  No combination of `transform`, `preserveAspectRation`, `textLength`, or others seems to work as a cross-platform solution.

  For other SVG elements, it is possible to use CSS3 styles to perform the centering, but these styles are not available for the `text` block.

  **Current `to svg` Solution:** Since terminal output is monospace, each line is padded with spaces on the right to the width of the longest line. Because all lines are then equal text-length (and thus pixel-width), assigning an `X="50%"` to every line "centers" them without disrupting their alignment with each other.

* **Background colors:** Again, difficult to believe, but there is no way to specify a background color for a `<tspan>` element.

  Other converters typically handle this by drawing a `<rect>` behind the text using absolute X/Y positioning. This requires that the foreground text be displayed in a known X/Y location.  As mentioned above, this results in text that often has display issues.

  Others use `ch` width, which is not supported in Safari iOS (and possibly others).

  **Current `to svg` Solution:** For any line with text in a background color, we draw a separate `<tspan>` behind the foreground.  This `<tspan>` has the same X value as its foreground, and the foreground is then drawn with a `dy="0"` to place it on the same vertical line as the background.

  The background line simply contains unicode Full-Block characters in each location where a background color should appear, and the `fill`/foreground on those block characters is set to the background color.

* **SVG Background:** The terminal theme (in Nushell or any shell) can be light or dark, and unless a background color is used that matches the temrinal background, it is likely that text may be unreadable on certain backgrounds. This will especially be a problem when a website (such as Github) has both light-and-dark mode support itself.

  Again, this could be solved via the use of styles, but Safari limitations preclude this.

  **Current `to svg` Solution:** A background `rect` is drawn at 100%/100% filled with the background color. This appears to be a universal solution across browsers.

**Note:** Some of the limitations of Safari mentioned above can be overcome by embedding an SVG image using the `<object>` tag or directly inline.  However, Github always wraps SVG images in an `<img>` tag, and since Github is a common target for these images, this is not an acceptable workaround. `to svg` attempts to support Github `<img>` embeds to every extent possible.
