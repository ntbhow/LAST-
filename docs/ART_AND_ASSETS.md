# Art / asset provenance

DUSTLINE has original map layout, equipment names, vector illustrations and
procedural sounds created for this project. No surviv.io assets or trademarks
are included. Game code and authored assets are covered by the root MIT LICENSE.

## Visual system

* Olive terrain #647052, foliage #3e573e, charcoal #19231f, ivory #e4e6d6,
  sand accent #d8b879. Equipment accents use restrained desaturated colors.
* Top-down scouts: independent feet, torso, straps, pouches, gloved arms,
  optional pack, helmet, armor and distinct gun silhouettes. Moving feet follow
  travel direction; the upper body follows aim and accumulated weapon recoil.
* Cached vector terrain has grass marks, dirt flecks, road edges, markings,
  floorboards and named areas. Props have offset contact shadows, facets,
  roof seams, timber bracing and metal fixtures. Crates show cracks and HP.
* UI uses Godot's bundled fallback font (Noto Sans) and restrained rectangular
  panels, 1 px borders, sand active markers, small labels and large key stats.
* All graphics are authored in scripts/art.gd, terrain.gd, obstacle.gd,
  roofs.gd and ui.gd, plus the original assets/icon.svg. They are not downloaded
  raster images. This is a coherent vector art build, not a hand-painted asset pack.
* Audio is original PCM synthesis in scripts/audio.gd, deterministic from
  fixed seeds. Each gun has a distinct pitch/envelope; footsteps, reload,
  pickup, hit, wood, metal, healing, zone, melee and explosion have separate cues.
  Ambient music is an original looping tonal bed, not a recorded soundtrack.

## Runtime licenses

Godot 4.5.1 is distributed under MIT. See GODOT-LICENSE.txt and
THIRD_PARTY_NOTICES.json (extracted from that exact engine at build time).
Those notices include the bundled font and engine dependencies.

Engine / export templates source:
https://github.com/godotengine/godot/releases/tag/4.5.1-stable

No paid service, account, backend, network gameplay or external font download
is required to run the game.
