# Goofy Ahh Forever

Every ability you use makes a meme noise. That is the whole addon.

Built for **World of Warcraft: Forever** (interface 16001).

## It sets itself up

There is nothing to configure before you start. Play normally: the first time
you use an ability it picks up a sound and plays it from then on. Sounds are
dealt from a shuffled bag rather than at random, so you hear all of them before
any repeats.

Open `/goofy` to change anything:

- **Click the sound name** on a row to walk to the next one, hear it, keep it
- **Test** replays it, **X** mutes that ability
- **Mode** switches between one fixed sound per ability and a random one every
  single time
- **Chance** sets how often a cast actually makes noise. At 30% it stays funny
  for much longer
- **Gap per ability** and **Gap between any sounds** keep a spammed button from
  turning into a machine gun
- **Reroll all** reshuffles everything

## It also reacts to

- Dying, dropping below 25% health, levelling up, looting something epic,
  getting a whisper, and entering combat
- What your **target** casts, which is off by default because it is a lot of
  noise, but genuinely useful: a boss starting a big cast makes a sound

## Elsewhere

- A minimap button: left click opens the window, right click mutes everything,
  drag it around the edge
- Keybinds for muting and for opening the window, under "Goofy Ahh Forever" in
  the key bindings screen
- `/goofy on`, `/goofy off`, `/goofy chance 30`, `/goofy random`, `/goofy fixed`,
  `/goofy target`, `/goofy minimap`, `/goofy reroll`, `/goofy list`

## You bring the sounds

None ship with the addon. They are internet meme clips and they are not mine to
hand out.

Drop your own `.mp3` or `.ogg` files into the `Sounds` folder, named after any
entry the addon looks for. `/goofy list` prints them all: the twelve usual
suspects are already in the list under the names people normally save them as
(`vineboom.mp3`, `bruh.mp3`, `metalpipe.mp3` and so on), plus twenty free slots
called `custom1.mp3` through `custom20.mp3`.

A name with no file behind it is noticed the first time it fails to play and
skipped from then on, so the entries you never fill cost you nothing. Run
`/goofy rescan` if you add files later.

## Not possible on this client

No sound on a critical strike or a killing blow. Those live in the combat log,
which this client does not let addons read.
