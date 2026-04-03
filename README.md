# Gredwitch Autonomous Emplacements

Fully autonomous bot-mode for all gredwitch emplacements (MG, Cannon, Mortar).  
No players, no NPC interaction. A hidden "ghost" Combine Soldier is spawned as the shooter proxy.

## How it works

- On `Initialize`, a `npc_combine_s` is spawned invisible/nocollide/frozen at the gun position.
- `gred_emp_base`'s Think normally checks `shooter:IsPlayer()` and `shooter:KeyDown()` on every tick.  
  We override the minimum functions so all those calls safely pass through the ghost soldier proxy.
- The emplacement scans for enemies itself and sets its own angle targeting.
- The ghost soldier never moves or acts — it is purely a valid entity handle.

## Requirements

- [Gredwitch Emplacement Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=2539539112)
