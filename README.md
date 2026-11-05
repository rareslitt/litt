# Litt — Steal an Egg playtest

An original, small Roblox egg-stealing tycoon inspired by the supplied gameplay
and visual references. Built entirely from parts and code: no paid models,
external assets, credentials, or plugins other than Rojo are required.

## Open it on Windows

1. In GitHub Desktop, fetch the repository and select the `egg-heist-prototype` branch.
2. Stop any running Studio playtest. Open PowerShell **inside this repository**.
3. Stop an older Rojo server with Ctrl+C, then run:

   ```powershell
   rojo serve default.project.json
   ```

4. Open a new Baseplate in Roblox Studio. Connect the Rojo 7 plugin to
   `localhost:34872` and accept the proposed sync.
5. Press Play (F5). **The map is generated when Play starts**, not in edit mode.
   Output should say `[Litt] Egg Heist prototype ready.` followed by the gameplay hint.
6. Stop with Shift+F5 before changing files or syncing a new version.

The server generates only its own `Workspace.EggHeistWorld` model. It does not
remove your other world objects. Use a fresh place for a clean preview.

## First playtest

- You start with $250 and your own fenced pen. Look for the numbered pen in the HUD.
- Walk to the tan central egg trail. Hold **E** at a $100 Meadow Egg to buy it.
- Carry it to the colored delivery pad in your own pen. It hatches in 12 seconds.
- Hatched, equipped pets build up income. Walk onto the green pad to collect it.
- The left **Shop** button buys speed upgrades; **Index** shows the five rarities.
- The right **Eggs** panel shows growth and offers Grow All for earned cash.
- The **Pets** panel equips/unequips pets. Unequipped pets stop earning.
- **Tools** provides Home, Sell Last Egg and a solo Practice toggle. Home cannot
  teleport you while carrying. **Q** or Return restores a stolen egg to its owner;
  newly bought eggs are refunded instead.
- A practice rival is enabled automatically when you are alone. Hold E at one of
  its pets, then walk it back to your delivery pad to test a steal.
- Use the red base button to lock your pen for 30 seconds (60-second recharge,
  measured from activation). Owners can enter their own locked pens.

## Multiplayer checks in Studio

Use Studio's local multiplayer testing controls to start a server with two
players. The exact menu labels vary by Studio version.

1. Confirm each player receives a different pen and the practice pen disappears.
2. Buy, deliver and hatch an egg with player A.
3. With player B, steal it from A's unlocked pen. Confirm A stops earning from it
   during the theft. Carry it home and confirm ownership and income move to B.
4. Repeat, but let A chase B and hold E at B to recover the carried pet.
5. Lock A's pen. Confirm B cannot steal or enter; A can still enter.
6. Reset a carrying character and confirm the egg returns (or a purchase refunds).

There are six pens and six slots per pen. Additional players wait for a free pen.
**This is a session-only prototype: cash, eggs and upgrades reset when the server
closes.** No DataStore, Robux purchases or copied game assets are included.

## Files

- `src/server/World.luau`: canyon, studded grass, wooden pens, money tree, shops.
- `src/server/init.server.luau`: server-owned economy, growth, stealing and locks.
- `src/server/EggVisual.luau`: procedural eggs and five pet silhouettes.
- `src/client/init.client.luau`: colorful HUD and inventory/shop panels.
- `src/shared/Config.luau`: prices, income, rarities, capacity and timers.
- `src/shared/Rules.luau`: pure rules exercised by command-line tests.

## Developer checks

With Rojo 7.7.1 and the Luau CLI installed:

```sh
luau tests/rules.spec.luau
rojo build default.project.json -o Litt.rbxlx
```

Compile individual sources using `luau-compile --null path/to/file.luau`.
The CLI rules tests and Rojo build do not replace Studio multiplayer, physics,
visual and mobile testing. Rojo sync is from files into Studio; it does not export
Studio world edits back to source. Coordinate code changes through GitHub and
keep a single Rojo sync writer when collaborating in a shared place.
