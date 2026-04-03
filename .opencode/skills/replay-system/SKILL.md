---
name: replay-system
description: Integrer le systeme de replay dans un jeu Haxe (inputs clavier + evenements gameplay) a partir d'un dossier cible.
---

Tu travailles sur un projet Haxe KadoKadeo.

## Objectif

A partir d'un dossier de jeu fourni en parametre (ex: `resources/hx/games/monjeu`), integrer le systeme de replay pour rendre une partie rejouable de maniere deterministe.

Le moteur replay est dans `resources/hx/lib/kado/ReplayManager.hx`.
L'orchestration globale (start/stop/frame + envoi replay) est deja geree par `resources/hx/lib/kado/KadoKadeoManager.hx`.

## Entree attendue

- Le point d'entrée du jeu est souvent la classe `Game.hx`
- ne pas traiter `synapses` ni `xianxiang` comme reference d'implementation replay

## Principes importants (a respecter absolument)

- Ne pas gerer manuellement le cycle de vie replay dans le jeu:
    - pas de `replay.start()`, `replay.stop()`, `replay.beginFrame()`, `replay.endFrame()` cote jeu
    - c'est `KadoKadeoManager` qui le fait deja
- Initialiser le replay dans le constructeur du jeu avec `KadoKadeoManager.kkm.replay.init(...)`
- Consommer les evenements replay au debut de `update()` quand `recordEvents = true`
- Respecter la temporalite des events: `recordEvent(...)` (sans `frameIndex`) est applique a la frame suivante; ne pas appliquer immediatement en live une action qui, en replay, passera par `consumeEvents()`
- Eviter les doubles enregistrements en mode replay (`isReplay == true`) pour les evenements souris/hover/click
- Conserver la logique gameplay identique entre session live et session replay (memes chemins de code)
- Pour les controles clavier, utiliser `common_haxe_avm1.KeyboardManager` (et pas la classe `Key` legacy)
- Si le jeu est base sur une grille, preferer enregistrer/rejouer la coordonnee de cellule (`x`, `y`) plutot que brancher un handler de clic sur chaque case

## Strategie d'integration

Choisir le mode en fonction des controles du jeu:

1. Inputs clavier uniquement
    - `recordInputs: true`, `recordEvents: false`
    - fournir `recordedKeys` (`UInt16Array`)
    - exemples: `resources/hx/games/atlanteine/Game.hx`, `resources/hx/games/kslash/Game.hx`

2. Evenements gameplay uniquement (souris, selection de case, clic contextuel...)
    - `recordInputs: false`, `recordEvents: true`
    - enregistrer des evenements metier via `recordEvent(...)`
    - rejouer via `consumeEvents()` + `applyReplayEvent(...)`
    - exemple: `resources/hx/games/chocomouche/Game.hx`

3. Mix clavier + evenements
    - `recordInputs: true`, `recordEvents: true`
    - exemples: `resources/hx/games/interwheel/Game.hx`, `resources/hx/games/kaskade2/Game.hx`, `resources/hx/games/opalus2/Game.hx`

## Etapes d'implementation (ordre recommande)

1. Analyser les entrees gameplay

- Lister ce qui influence l'etat de partie:
    - touches clavier
    - clic press/release
    - hover si le hover modifie la selection/target effective
- Ignorer le purement visuel.
- Pour les touches, recenser les usages `Key.isDown(...)`/`Key` et les migrer vers `KeyboardManager.isDown(...)` avant l'integration replay.
- Si des keycodes sont utilisés en dur, les remplacer par des constantes `KeyboardManager.<KEY>` en modifiant le KeyboardManager pour les definir si necessaire.
- Pour les grilles, definir une conversion souris -> cellule (`getMouseCell`, `screenToGrid`, etc.) et centraliser l'action metier via cette cellule.

2. Initialiser replay dans `new(...)`

- Ajouter (ou completer) `replay.init`:

```hx
var replayKeys = new UInt16Array(N);
// replayKeys[i] = common_haxe_avm1.KeyboardManager.<KEY>;

KadoKadeoManager.kkm.replay.init({
	recordedKeys: replayKeys, // ou new UInt16Array(0) si pas de clavier
	recordInputs: true,       // ou false
	recordEvents: true,       // ou false
});
```

3. Ajouter le mode replay cote jeu

- Conserver `?isReplay:Bool = false` dans le constructeur.
- Stocker eventuellement `isReplayMode` si necessaire pour bloquer les enregistrements live en replay.

4. Brancher la consommation d'evenements (si `recordEvents = true`)

- En tete de `update(delta)`:

```hx
for (event in KadoKadeoManager.kkm.replay.consumeEvents()) {
	applyReplayEvent(event);
}
```

- Implementer `applyReplayEvent(event:Dynamic)`:
    - valider `event != null`
    - lire `k`, eventuellement `x`, `y`
    - rejouer l'action metier exacte (hover, select, press/release...)
- Important: pour les actions event-driven (hover/clic), faire converger live et replay vers le meme point d'application (idealement via `applyReplayEvent` ou une fonction metier commune), afin de conserver le meme decalage d'une frame.

5. Enregistrer les evenements metier

- Au moment ou l'action utilisateur est validee:

```hx
KadoKadeoManager.kkm.replay.recordEvent({k: 2, x: cell.x, y: cell.y});
```

- Si le jeu utilise une grille, ne pas enregistrer un clic "objet" (listener par case). Preferer:
    - calculer d'abord la cellule cible depuis la souris
    - enregistrer cette cellule (`x`, `y`)
    - executer la logique via une fonction unique (`selectFromCell`, `onClickCell`, etc.)

- Convention frequemment utilisee:
    - `k: 0` hover/move
    - `k: 2` click/confirm
    - (adapter selon le jeu)

6. Eviter les doublons en replay

- Dans les handlers live (`onPress`, `updateHover`, etc.), ne pas `recordEvent` si `isReplayMode`.
- Conserver un code unique de gameplay autant que possible (ex: `selectFromCell`, `onClick`, `setMousePressed`) appele a la fois par live et replay.

7. Validation

- Pour compiler, utiliser la commande `make compile-games`
- Lancer une partie live et verifier l'absence de regression.
- Verifier qu'un replay rejoue:
    - memes actions
    - meme score final
    - meme fin de partie
- En debug, `KadoKadeoManager` trace `Replay data` a la fin.

## Details techniques utiles sur ReplayManager

- `recordInput` enregistre des transitions de touche (down/up), pas un etat complet a chaque frame.
- `recordEvent` sans `frameIndex` met en file d'attente pour la frame suivante (comportement normal du manager).
- Consequence pratique: si une action est enregistree en event, eviter de l'appliquer "tout de suite" en live dans un chemin de code different, sinon live et replay peuvent diverger (timing, trajectoires, score).
- Le format d'evenement `{k, x, y}` est un exemple et est a adapter suivant le jeu / le contexte.

## Patterns de reference (repo actuel)

- Inputs clavier seuls:
    - `resources/hx/games/atlanteine/Game.hx`
    - `resources/hx/games/kslash/Game.hx`
- Evenements seuls:
    - `resources/hx/games/chocomouche/Game.hx`
- Inputs + events:
    - `resources/hx/games/interwheel/Game.hx`
    - `resources/hx/games/kaskade2/Game.hx`
    - `resources/hx/games/opalus2/Game.hx`

## Checklist finale

- [ ] `replay.init(...)` present dans le constructeur
- [ ] `recordedKeys` defini correctement (ou vide)
- [ ] `consumeEvents()` appele en debut de `update()` si `recordEvents = true`
- [ ] `applyReplayEvent(...)` rejoue toutes les actions determinantes
- [ ] `recordEvent(...)` branche sur les actions live determinantes
- [ ] garde-fou anti double-enregistrement en replay
- [ ] score/fin de partie identiques entre live et replay
