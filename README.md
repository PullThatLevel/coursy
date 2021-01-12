# Coursy
Coursy, the little converter that could.

A tiny template meant to help with the porting of course based modfiles to modern .xml/.lua whilst being fully compatible with most modern and old versions of StepMania.

# Installation
1. Add the "lua" folder to the root of the modfile
2. Add `#FGCHANGES:0.000=lua=1.000=0=0=1;` to the .sm and .ssc file, and don't forget to make it selectable if it should be!
3. Port all mods in the course (.crs) file to the table format seen in mods.lua and mods.xml
4. Insert the mod table inside of mods.lua and mods.xml, **leave every other file intact!**
5. If you're going to tweak the offset for resyncing and/or removing the ITG bias, modify the variable MOD_OFFSET with the difference between the original offset and the new offset (for example: if the original offset was -0.100 and you changed it to -0.050, make MOD_OFFSET be 0.050)

And that's all! The template takes care of the rest and all mods should work as intended. To facilitate step 3 there is also an Awk script included which does the extraction for you, this file is obviously not needed for the file to work and you can delete it before release.

*(note: if the file you're porting already uses FGCHANGES you'll need to merge this template with the already existing code.)*

# Known issues
* Due to SM5's modding system being different than the rest, the SM5 version of the template will probably not replicate mods 100% accurately.
* The SM5 version currently does not account for MMods
* There is virtually no error checking on the modstrings, expect Lua errors or crashes on malformed strings.
* The timer system used in the SM3.95/oITG/nITG version is functional and respects rate mods but can be extremely slow if you skip forwards in the song within the editor.

~ PullThatLevel (2021+)
