# Architecture

Godot 4.5.1 / GDScript / GL Compatibility. Physics 60 Hz.

| Module | Responsibility |
|---|---|
| main.gd | Match lifecycle, seeded map/spawn, navigation grid, ownership transfers |
| actor.gd / actor_visual.gd | Shared movement, health, actions, procedural animation |
| weapon.gd | Fire/reload state, recoil pattern, bloom, center-to-muzzle guard |
| projectiles.gd | Fixed 768-slot pool; independent flight state and swept collision |
| inventory.gd | Two gun slots, magazines, reserve ammo, load capacity, supplies and gear |
| catalog.gd / data/*.json | Weapon definitions and weighted crate/ground loot tables |
| bot.gd | Perception, delayed aim, memory, scavenging/combat/cover/heal/zone states |
| zone.gd | Hold/shrink phases, interpolated center/radius, stage-scaled damage |
| obstacle.gd / loot.gd | Collision, destructible props and tangible dropped items |
| grenade.gd | Moving/bouncing fuse and LOS-gated radial damage |
| terrain.gd / roofs.gd / art.gd | Cached terrain, fading roofs, original vector asset language |
| ui.gd | Functional Controls plus lightweight drawn HUD/map/inventory |
| effects.gd / audio.gd | Capped particles/rings; pooled spatial SFX and ambient music |
| settings.gd | ConfigFile persistence and bus/display settings |

Physics layer 1 = world/cover; layer 2 = combatants. Combatants collide with
world only, so they cannot trap one another in doorways. Projectile queries
use mask 3 and exclude their owner's RID. Bot sight uses mask 1. Long guns
spawn at their own muzzle distance (67 px); pistol 47 px, SMG 55 px.

Actors and weapons operate in world coordinates; UI and cosmetic camera shake
never define collision. A shot samples current recoil + independent random
spread, then moves every physics tick. Damage and ownership are resolved by
the local match coordinator. Swapping a gun returns the old item; consuming
loot removes its single world owner, then materializes any replacement or
leftover. Healing reserves an item and refunds it on cancellation.

Navigation is a 32 px AStarGrid2D inflated for the actor radius. Door gaps are
100 px. A crate breaking updates only surrounding cells. Bot planning is
staggered rather than scanning/repathing every physics tick. No enemy
positions are used to aim unless LOS is currently valid; a last-seen point is
remembered for 2.3s. Pickup search has a local radius. Combat accuracy,
reaction delay and prediction change with difficulty, not damage rules.

Replay replaces the entire world subtree, arrays, projectile pool, effects,
zone, feed and timers. Settings and menu survive. UI pauses use SceneTree pause;
inventory and map do not. Game simulation nodes are pausable; menu/audio nodes
remain responsive. Art is drawn per operator in an independent rotated child,
so lower-body travel can differ from aim.

Future multiplayer should replace local input/AI action sources with command
providers and authoritative tick updates. This version does not implement
transport, snapshots, deterministic lockstep, lag compensation or prediction.
