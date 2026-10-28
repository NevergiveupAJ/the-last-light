# Map layout

Built by `scripts/world_builder.gd`. Coordinates are metres, X = east, -Z = north, Y = up. The map runs from z = +23 (south fence) to z = -122 (north fence), x = -68 to +68.

```
 z=-122 ───────────────── north fence ─────────────────
          EXIT TRIGGER (z -116)
 z=-110 ════════ fence ════[ GATE x -3..3 ]════ fence ═══   control box at x +4.6
            ┌── TUNNELS pit (x -50..-22, z -92..-72, floor -4 m) ──┐
            │  north room  (Fuse C, x -48)                         │ ramp from x -22 (east)
            │  corridor z -84..-80 ── LOWER DOOR (west end)         │ down to x -34
            │  south room  (radio recording)                        │
            └───────────────────────────────────────────────────────┘
        RESEARCH FACILITY  x -12..12, z -71..-53, door south (x 0)
          front hall  ─ door x -6 ─ west lab (lab note) ─ door ─ east server room (Fuse B)
                                                   GENERATOR STATION x 22..34, z -33..-23
                                                   door west, Fuse A + audio log
   CABINS (-26,-6) (-38,-18) (-24,-30), doors east
   battery / medkit / bandage / photograph / flare
        FOREST ENTRANCE: truck, sign, crate with map (2.6, 12)
 z=+17   PLAYER START (0, 17), facing north on the road
 z=+23 ───────────────── south fence ─────────────────
```
- The Hollow starts at (26, -48) and patrols 10 points (one is inside the tunnels).
- The final chase spawn is (30, -78), about 40 m from the gate, which opens in 6 s.
- Navigation is baked at startup: cell 0.4 m, agent radius 0.5 m, height 2.4 m, max slope 40°.
