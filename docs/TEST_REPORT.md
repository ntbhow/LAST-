# Verification — 2026-11-04

Engine actually executed: **Godot 4.5.1.stable.official.f62fdbde1** on Windows.
Renderer actually observed: OpenGL 3.3, NVIDIA GeForce RTX 4060 Laptop GPU,
driver 566.24. This report distinguishes executable tests from inspection.

## Automated logic / physics: 52 passed, 0 failed

Run `tools/run.ps1 -Tests`. Machine-readable evidence is `tests/results.json`.
Tests instantiate the real match, use Godot's physics space and production
inventory/weapon/bot/zone code, then replace the world through the actual
replay path. Collision bodies remain registered while test stepping is manual.

Verified cases include:

* 21 operators and unobstructed spawn positions; normalized diagonal input.
* Magazine and reserve conservation, gun replacement/drop, partial ammo pickup,
  capacity/pack restrictions, and fractional armor durability on drop/pickup.
* Projectile speed × delta with delayed target damage and owner exclusion.
* 18,000 px/s projectile blocked by a 3 px wall; center-to-muzzle wall guard.
* Actual moving target test: old-position aim misses; an intercept shot hits.
* Independent recoil/bloom, recovery and movement spread; reload cancellation,
  blocked firing during reload, empty magazine and exact ammo transfer.
* Shotgun creates seven separate projectiles; lifetime/range reclaim pool slots.
* Grenade falloff damages an exposed target; a wall blocks splash damage.
* Crate drops exactly once even when damaged twice in one frame; safe drop
  placement; same-frame double pickup rejected.
* Healing item reservation, interruption/refund and completion; stage-scaled
  zone damage; health/death and victory/placement transitions.
* Bot LOS blocked by cover; A* route exits a building through its doorway;
  valid path clearance; bot physically travels toward the next safe circle.
* ConfigFile saves and reloads sensitivity + cosmetic choice.
* Pause/resume, functional inventory controls, three cosmetic choices and
  six live settings sliders.
* Replay resets actors, projectiles, loot, feed, zone, rank and time.

Latest headless suite exits 0 with no script errors or leak warnings.
The diagonal check validates the normalized movement vector mathematically;
it is not a physical keyboard distance benchmark.

## Completed match runs

| Run | Mode | Total duration | Last alive | Shots | Pickups | Broken crates |
|---|---|---:|---:|---:|---:|---:|
| Seed 44621 | Headless, speed 8, full-match soak | 254.57 game seconds | 1 | 616 | 132 | 5 |
| Seed 44622 | GPU-rendered 1080p, speed 1, full-match soak | 350.94 seconds (5:51) | 1 | 504 | 111 | 3 |

See `tests/match_report_44621.json` and `tests/match_report_44622.json`.
Both used the same production rules with AI controlling the scout. In the
1x run the scout died in 13th place, then the QA camera observed the remaining
combatants until the winner. This is a complete automated round, not a claim
that a human tester manually won a complete match.

The initial AI iteration exposed an unarmed combat-priority problem. It was
fixed before these two recorded runs. The final art pass adjusts muzzle
alignment and culls distant operator drawing; physics regression tests were
rerun afterwards. Gameplay duration varies by seed; early elimination is
possible and some bot encounters resolve too quickly.

## Performance baseline

The 1x 1080p round measured after a 3-second warmup:

* Mean frame time **17.264 ms** ≈ **57.9 FPS**.
* p95 frame time **20.370 ms**.
* Slowest sampled frame **134.660 ms**.

These are real elapsed frame intervals, not a GPU-only timing. Export, other
test processes and desktop work ran concurrently. They precede the final
distant/dead-operator redraw optimization; no improved numeric result is
claimed without another measurement. Headless speed-8 frame figures are not
presented as a game FPS benchmark. Sustained 60 FPS on an ordinary laptop or
integrated GPU remains unverified.

## Visual / exported application checks

* Real rendered PNGs were inspected for menu, gameplay and inventory.
* Confirmed PNG pixel dimensions at 1280×720 and exact 1920×1080. The first
  windowed 1080p attempt had an OS-constrained client area of 1886×1061; it was
  replaced using a borderless 1920×1080 QA window.
* No clipped HUD/controls observed at the two target resolutions. The final
  720p inventory capture shows both loaded gun slots and consumables.
* Export completed using the official Windows x64 release template with PCK
  embedded. The packed EXE headless smoke run returned **exit code 0**.
* The real exported DUSTLINE window was opened and observed in active gameplay,
  showing health, loot, live bot combat, kill feed and remaining operators.
* Native UI automation encountered concurrent user input, so it did not force
  additional pause/settings actions on that live window. Those flows are
  verified by the automated suite, not claimed as completed native click tests.

QA screenshot captures use a staged equipped loadout to make UI/weapon assets
visible. Normal deployment still starts with a knife and one bandage.

## Not verified / remaining priorities

1. P1: longer human playtests for aiming feel, difficulty progression and
   early-game bot lethality; ordinary-hardware profiling and frame pacing.
2. P2: listening tests on speakers/headphones, wider resolution/DPI matrix,
   fullscreen/alt-tab across multiple monitors, accessibility and controller.
3. P2: authored sprite/audio production pass beyond the current original
   procedural vector and synthesized sound implementation.
4. No networking, multiplayer authority, anti-cheat, installer, signing or
   auto-update; those were outside this offline first version.
