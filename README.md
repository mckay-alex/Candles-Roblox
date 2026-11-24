# 🕯️ Candles

**[▶ Play Candles on Roblox](https://www.roblox.com/games/73928793827808/Candles)**

> Embark on a camping adventure in a group of 12, uncover the secrets within the forest, choices will have to be made, risks will have to be taken… just watch out for the candles. 🎃🕯️

Candles is a multiplayer story game for groups of up to 12 players: a lobby, then a scripted story chapter with NPC enemies, puzzles, group votes, cutscenes and a multi-phase boss fight. This repo holds the Luau source for the game's main systems.

<!-- Add a screenshot or GIF here, e.g. ![Boss fight](docs/boss.gif) -->

---

## Highlights

- **Server-authoritative combat.** The server owns health, damage and boss state. Clients handle visuals and hit detection, and the server sanity-checks every hit they report.
- **Multi-phase boss fight.** Three attack types, a lives system, and phases that escalate with randomized attack counts.
- **Enemy NPC AI.** Patrolling guards, plus attackers that use `PathfindingService` and raycast line-of-sight checks to hunt players.
- **Event-driven story flow.** One `StoryEvent` drives the chapter through modular phases, each loaded only when it starts.
- **Group decisions.** Timed player votes that change how the story goes.
- **Multi-place teleporting.** The party moves from the lobby into the story with retries and failure handling. The story server waits for the whole group to arrive before it starts.
- **Monetization and analytics.** Shop, developer products and receipt processing, plus funnel analytics that track how far players get.

---

## Repo layout

Folders mirror where each script lives in Roblox Studio, so you can tell where code runs from its path.

```
Lobby/                  Starting place: party up, shop, leaderboards
  ServerScriptService/
  StarterGui/
  StarterPlayerScripts/
  Workspace/

Chapter2/               Main story chapter
  ServerScriptService/  Story flow, phases, shop, dev products, teleport data
  ServerStorage/        Boss AI (server)
  ReplicatedStorage/    Shared modules
  StarterGui/           Story UI, voting, shop
  StarterPlayerScripts/ Cutscenes, boss attack visuals, screen effects
```

**Script naming (Roblox Script Sync):** `.server.luau` / `.legacy.luau` = server Script · `.local.luau` = LocalScript · `.luau` = ModuleScript · `init.*` = the script that a folder's modules belong to.

---

## Systems

| System | Server | Client |
|---|---|---|
| Boss fight | `Chapter2/ServerStorage/BossController` (attack selection, phases, lives) + `BossAttacks` | `Chapter2/StarterPlayerScripts/BossAttackClient` (attack visuals and hitboxes) |
| Boss chase | `StoryServerP2/PhaseThreeP2/Chase` (meteor spawning, validates hits) | `StarterPlayerScripts/BossChaseClient` |
| Story flow | `StoryServerP2` (phase controller) → `PhaseOneP2`, `PhaseTwoP2`, `PhaseThreeP2` | `StarterGui/StoryClient`, `StarterGui/ClientEvents` |
| Security guards | `PhaseOneP2/Security` (patrol routes, attacks until the lever puzzle is solved) | |
| Attacker NPCs | `PhaseOneP2/Attack/AttackerController` (pathfinding, line of sight) | |
| Group voting | `PhaseThreeP2/Vote` (timed vote, majority wins, random tiebreak) | `StarterGui/VotingClient` |
| Cutscenes | Triggered by server events | `StarterPlayerScripts/Cutscenes` |
| Teleporting | `Lobby/Workspace/tpSERVER`, `SafeTeleport`, `Chapter2/.../HandleTeleportData` | `Lobby/StarterGui/tpCLIENT` |
| Shop and purchases | `ShopServer`, `ProcessReceiptHandler` / `DevProductServer` | `ShopClient` |
| Death and revive | `OnPlayerAdded/DeathScreenServer` | `StarterPlayerScripts/DeathScreenClient` |
| Zipline | `Chapter2/ServerScriptService/Zipline` | |

---

## How it works

### Client/server split
Damage is never applied on the client. Clients fire a RemoteEvent when they think they've been hit, for example by a boss attack or a meteor. The server then checks that the player is real, that they're reporting their own character, and that they aren't on a hit cooldown, before it calls `TakeDamage`. Visual effects and precise hitboxes run on the client, so they stay responsive without trusting it for game state.

### Boss fight
`BossController` runs the fight on the server. Each round it picks a random living player and an attack (`Spikes`, `Circle` or `Fireball`). It tells every client to play that attack through `RemoteBossEvent`. The boss has 3 lives and goes through three phases, and each phase allows more attacks (randomized ranges) before moving on.

### Story phases
`StoryServerP2` listens on a single `BindableEvent` (`StoryEvent`) and sends each step (`START`, `SECURITY`, `ATTACK`, `OBBY`, `PHASE_TWO`, …) to the matching phase module. Each phase is `require`d only when it begins, and the previous one is released. This keeps each part of the story self-contained.

### Multi-place flow
The lobby teleports the party with `TeleportService:TeleportAsync` through a `SafeTeleport` wrapper that retries on failure, and passes the party size as teleport data. In Chapter 2, `HandleTeleportData` waits until everyone has arrived, or up to 15 seconds, before starting the story. That way nobody misses the intro.

### Analytics
Key story steps are logged with `AnalyticsService:LogOnboardingFunnelStepEvent`, which shows where players drop off.

---

## Notes
- Only gameplay scripts are included. Roblox's default `Animate` scripts and small items (gamepass tools and the like) are left out.
- Some modules, such as `SafeTeleport` and the shop, exist in both places because each Roblox place needs its own copy.
- The game also has a first story chapter (obby and maze), which isn't included here because its systems overlap with Chapter 2.

## Built with
Luau · Roblox Studio · Roblox Script Sync · TeleportService · PathfindingService · AnalyticsService · MarketplaceService
