# raymarched-sundial

This is a small demo of a sundial in a desert, intended to be run in [Shadertoy](https://www.shadertoy.com). 

## Building
In order to run in shadertoy, run `python3 make.py cat` and copy the contents
of main.glsl into shadertoy. Likewise, copy the shadertoy script into main.glsl
and run `python3 make.py uncat` in order to save changes.

To load the demos' textures into Shadertoy, use the bookmarklet under `scripts/bookmarklet.js`. Its unminified source is also provided, for those understandably sheepish about obfuscated JavaScript. Note that custom textures are not saved by Shadertoy, so you will have to do this every time you open the page.
