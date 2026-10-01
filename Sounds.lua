--------------------------------------------------------------------------------
-- Goofy Ahh Forever - Sounds.lua
--
-- The game cannot list a folder, so every sound has to be named here.
--
-- The .ogg files ship with the addon and are free licensed (see CREDITS.md).
-- The .mp3 names below ship empty on purpose: those are the meme clips, which
-- are not mine to hand out. Drop your own in Sounds/ with these names and they
-- start working. A name with no file behind it is noticed the first time it
-- fails to play and skipped from then on.
--------------------------------------------------------------------------------
local ADDON, ns = ...

ns.SOUNDS = {
    -- Included, free licensed
    { name = "Applause", file = "applause.ogg" },
    { name = "Boing", file = "boing.ogg" },
    { name = "Buzzer", file = "buzzer.ogg" },
    { name = "Cartoon laugh", file = "cartoonlaugh.ogg" },
    { name = "Drum roll", file = "drumroll.ogg" },
    { name = "Explosion", file = "explosion.ogg" },
    { name = "Gong", file = "gong.ogg" },
    { name = "Moo", file = "moo.ogg" },
    { name = "Cartoon punch", file = "punch.ogg" },
    { name = "Sad trombone", file = "sadtrombone.ogg" },
    { name = "Scream", file = "scream.ogg" },
    { name = "Whoopee cushion", file = "whoopee.ogg" },
    { name = "Whoosh", file = "whoosh.ogg" },

    -- Bring your own: name the file like this and it works
    { name = "Vine boom", file = "vineboom.mp3" },
    { name = "Bruh", file = "bruh.mp3" },
    { name = "Metal pipe", file = "metalpipe.mp3" },
    { name = "Emotional damage", file = "emotionaldamage.mp3" },
    { name = "Augh", file = "augh.mp3" },
    { name = "Bonk", file = "bonk.mp3" },
    { name = "Huh cat", file = "huhcat.mp3" },
    { name = "Violin screech", file = "violin.mp3" },
    { name = "Windows error", file = "windowserror.mp3" },
    { name = "Fart", file = "fart.mp3" },
    { name = "Goofy laugh", file = "goofylaugh.mp3" },
    { name = "Sneeze boom", file = "sneezeboom.mp3" },
}
