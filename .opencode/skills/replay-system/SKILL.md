---
name: replay-system
description: Integrer le systeme de replay dans un jeu Haxe (clavier + souris polled + evenements gameplay) a partir d'un dossier cible.
---

Tu travailles sur un projet Haxe KadoKadeo.

## Objectif

A partir d'un dossier de jeu fourni en parametre (ex: `resources/hx/games/monjeu`), integrer le systeme de replay pour rendre une partie rejouable de maniere deterministe.

Le moteur replay est dans `resources/hx/lib/kado/ReplayManager.hx`.
L'orchestration globale (start/stop/frame + envoi replay) est deja geree par `resources/hx/lib/kado/KadoKadeoManager.hx`.

## Entree attendue

- Le point d'entrée du jeu est souvent la classe `Game.hx`

## Principes importants (a respecter absolument)

- Ne pas gerer manuellement le cycle de vie replay dans le jeu:
    - pas de `replay.start()`, `replay.stop()`, `replay.beginFrame()`, `replay.endFrame()` cote jeu
    - c'est `KadoKadeoManager` qui le fait deja
- Initialiser le replay dans le constructeur du jeu avec `KadoKadeoManager.kkm.replay.init(...)`
- Preferer le polling clavier/souris (`KeyboardManager` + `MouseManager`) pour les inputs joueur
- Ne garder `recordEvents` que pour des evenements gameplay non derivables d'un input polled (spawn scriptes, triggers metier, etc.)
- Quand `recordEvents = true`, consommer les evenements replay au debut de `update()`
- Respecter la temporalite des events: `recordEvent(...)` (sans `frameIndex`) est applique a la frame suivante; ne pas appliquer immediatement en live une action qui, en replay, passera par `consumeEvents()`
- Eviter les doubles enregistrements en mode replay (`isReplay == true`) pour les evenements metier
- Conserver la logique gameplay identique entre session live et session replay (memes chemins de code)
- Pour les controles clavier, utiliser `common_haxe_avm1.KeyboardManager` (et pas la classe `Key` legacy)
- Pour les controles souris, utiliser `common_haxe_avm1.MouseManager` (`getX/getY`, `isButtonDown`, `isButtonJustPressed`, `isButtonJustReleased`)
- Si le jeu est base sur une grille, calculer la cellule depuis `MouseManager.getX/getY` dans `update()` (hover derive de la position)

## Strategie d'integration

Choisir le mode en fonction des controles du jeu:

1. Inputs clavier uniquement
    - `recordInputs: true`, `recordEvents: false`
    - fournir `recordedKeys` (`UInt16Array`)
    - exemples: `resources/hx/games/atlanteine/Game.hx`, `resources/hx/games/kslash/Game.hx`

2. Inputs souris polls (sans position)
    - `recordInputs: false`, `recordEvents: false`
    - `recordMousePosition: false`
    - `recordedMouseButtons: UInt16Array([...])`
    - lecture en jeu via `MouseManager.isButtonDown/isButtonJustPressed/...`
    - exemple: `resources/hx/games/interwheel/Game.hx`

3. Inputs souris polls (avec position)
    - `recordInputs: false` (ou `true` si clavier aussi), `recordEvents: false`
    - `recordMousePosition: true`
    - `recordedMouseButtons: UInt16Array([...])`
    - lecture en jeu via `MouseManager.getX/getY` + boutons
    - exemples: `resources/hx/games/kaskade2/Game.hx`, `resources/hx/games/zipzap/Game.hx`

4. Evenements gameplay metier uniquement (hors inputs polled)
    - `recordInputs: false`, `recordEvents: true`
    - enregistrer des evenements metier via `recordEvent(...)`
    - rejouer via `consumeEvents()` + `applyReplayEvent(...)`
    - exemple: `resources/hx/games/synapses/Game.hx`

5. Mix clavier + evenements metier
    - `recordInputs: true`, `recordEvents: true`
    - ajouter `recordMousePosition` / `recordedMouseButtons` seulement si la souris influence le gameplay
    - exemple: `resources/hx/games/opalus2/Game.hx`

## Etapes d'implementation (ordre recommande)

1. Analyser les entrees gameplay

- Lister ce qui influence l'etat de partie:
    - touches clavier
    - boutons souris press/release
    - position souris si elle influence la selection/target
    - hover si le hover modifie la selection/target effective
- Ignorer le purement visuel.
- Pour les touches, recenser les usages `Key.isDown(...)`/`Key` et les migrer vers `KeyboardManager.isDown(...)` avant l'integration replay.
- Si des keycodes sont utilisés en dur, les remplacer par des constantes `KeyboardManager.<KEY>` en modifiant le KeyboardManager pour les definir si necessaire.
- Pour la souris, migrer les handlers ad-hoc (`onPress`, `onRelease`, `recordEvent({k:...})`) vers la lecture polled dans `update()`.
- Pour les grilles, definir une conversion souris -> cellule (`getMouseCell`, `screenToGrid`, etc.) et centraliser l'action metier via cette cellule.

2. Initialiser replay dans `new(...)`

- Ajouter (ou completer) `replay.init`:

```hx
var replayKeys = new UInt16Array(N);
// replayKeys[i] = common_haxe_avm1.KeyboardManager.<KEY>;
var replayMouseButtons = new UInt16Array(M);
// replayMouseButtons[i] = common_haxe_avm1.MouseManager.BUTTON_LEFT; // etc.

KadoKadeoManager.kkm.replay.init({
	recordedKeys: replayKeys, // ou new UInt16Array(0) si pas de clavier
	recordInputs: true,       // ou false
	recordEvents: false,      // true seulement pour evenements metier
	recordMousePosition: true, // ou false
	recordedMouseButtons: replayMouseButtons,
});
```

3. Migrer le jeu vers les inputs polled

- Clavier: `KeyboardManager.isDown/isJustDown`
- Souris: `MouseManager.getX/getY`, `MouseManager.isButtonDown/isButtonJustPressed/isButtonJustReleased`
- Ne pas brancher la logique gameplay principale sur des callbacks UI souris; la lire dans `update()` pour avoir exactement la meme valeur live/replay.

4. Brancher la consommation d'evenements metier (si `recordEvents = true`)
   **deprecated** : utilisation des événements de souris/clavier directement (inputs polled).

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
- Important: ne pas utiliser `recordEvents` pour des inputs souris standard si `MouseManager` suffit.

5. Enregistrer les evenements metier (optionnel)

- Au moment ou l'action utilisateur est validee:

```hx
KadoKadeoManager.kkm.replay.recordEvent({k: 2, x: cell.x, y: cell.y});
```

- A reserver aux evenements metier non derivables des etats clavier/souris polled.

6. Eviter les doublons en replay

- Si `recordEvents = true`, dans les handlers live (`onPress`, `updateHover`, etc.), ne pas `recordEvent` si `isReplayMode`.
- Conserver un code unique de gameplay autant que possible.

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
- `recordMousePosition` enregistre la position souris (int) seulement quand elle change.
- `recordedMouseButtons` enregistre les transitions down/up des boutons souris suivis.
- Les boutons souris utilises suivent `MouseEvent.button` DOM (`0` gauche, `1` milieu, `2` droit).
- `recordEvent` sans `frameIndex` met en file d'attente pour la frame suivante (comportement normal du manager).
- Consequence pratique: si une action est enregistree en event, eviter de l'appliquer "tout de suite" en live dans un chemin de code different, sinon live et replay peuvent diverger (timing, trajectoires, score).
- Le format d'evenement `{k, x, y}` est un exemple et est a adapter suivant le jeu / le contexte.

## Patterns de reference (repo actuel)

- Inputs clavier seuls:
    - `resources/hx/games/atlanteine/Game.hx`
    - `resources/hx/games/kslash/Game.hx`
- Souris polled:
    - `resources/hx/games/interwheel/Game.hx`
    - `resources/hx/games/kaskade2/Game.hx`
    - `resources/hx/games/zipzap/Game.hx`
- Evenements metier seuls:
    - `resources/hx/games/chocomouche/Game.hx`
- Inputs + evenements metier:
    - `resources/hx/games/opalus2/Game.hx`

## Points d'attention importants

- Lorsque le jeu est en recordEvent et possède une grille où x et y sont inférieurs à 8 (entre 0 et 7), on peut utiliser recordEvent({k: 0-3, x: 0-7, y: 0-7}) pour encoder un event en un seul octet (k<<6 | x<<3 | y). Cela permet de réduire la taille du replay.
- Si le jeu est en recordEvent mais n'est pas dans une grille, utiliser un autre valeur que "k" dans l'objet recordé.

## Checklist finale

- [ ] `replay.init(...)` present dans le constructeur
- [ ] `recordedKeys` defini correctement (ou vide)
- [ ] `recordMousePosition` active si la position souris impacte le gameplay
- [ ] `recordedMouseButtons` defini si des boutons souris sont utilises
- [ ] logique input lue en polling dans `update()` (clavier/souris)
- [ ] `consumeEvents()` / `applyReplayEvent(...)` uniquement si `recordEvents = true`
- [ ] `recordEvent(...)` reserve aux evenements metier non derivables
- [ ] garde-fou anti double-enregistrement en replay (si events metier)
- [ ] score/fin de partie identiques entre live et replay
