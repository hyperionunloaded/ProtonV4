# ProtonV4

Hosted loader bundle for Proton V4. The executor entry script downloads this repo into the `proton/` workspace folder, same pattern as Vape's `newvape/` loader.

## Executor usage

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hyperionunloaded/ProtonV4/main/loader.lua", true), "proton")()
```

Or with local dev:

```lua
shared.ProtonDeveloper = true
loadstring(readfile("proton/loader.lua"), "proton")()
```

## Workspace layout

```
proton/
  loader.lua          <- entry (downloads + runs main)
  main.lua            <- boots UI + runtime
  lib/boot.lua        <- file-based require shim
  manifest/files.txt  <- module list
  profiles/
    commit.txt        <- cache bust hash
    repo.txt          <- github slug
  ui/proton_ui.lua
  src/proton/...
```

## Rebuild

From the main project:

```
python tools/build_dist.py
```

Then commit and push this folder.

## Teleport

Queue-on-teleport reload is handled automatically like Vape.
