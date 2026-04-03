# Install

## Using [Nubrew](https://github.com/nubrew/nubrew)

```nushell
http get https://raw.githubusercontent.com/NotTheDr01ds/ntd-nushell_scripts/refs/heads/main/startup-config/theme-3024ntd/nubrew.nuon | nubrew install
```

# Configuring / Using

```nushell
use theme-3024ntd
theme-3024ntd set color_config
theme-3024ntd update terminal
```

To load at startup, add the above to any file in `$nu.default-config-dir/autoload`.
