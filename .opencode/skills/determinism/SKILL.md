---
name: determinism
description: Rendre déterministes tous les usages non visuels du hasard dans le dossier fourni en paramètre.
---

Tu travailles sur un projet Haxe.

Objectif :
rendre déterministes tous les usages du hasard dans le dossier fourni en paramètre.

Principe :

- tout random qui influence la logique du jeu doit être seedé
- tout random purement visuel doit aussi être seedé avec un seed différent pour ne pas impacter la logique du jeu

Utiliser la classe `Seed` (`resources/hx/lib/kado/Seed.hx`) comme point d’entrée du random seedé.
Tu peux ajouter l'import `import kado.Seed;` dans le fichier import.hx si ce n'est pas déjà fait.

Helpers `Seed` :

```hx
public static inline function rand():Float;
public static inline function random(max:Int):Int;
public static inline function randVfx():Float;
public static inline function randomVfx(max:Int):Int;
```

Transformations attendues :

- `Math.random()` (logique) → `Seed.rand()`
- `Std.random(max)` (logique) → `Seed.random(max)`
- `Math.random()` (visuel) → `Seed.randVfx()`
- `Std.random(max)` (visuel) → `Seed.randomVfx(max)`

Remplacer aussi les calculs aléatoires dérivés quand c’est pertinent :

- `Math.random() * n` (logique) → `Seed.rand() * n`
- `Math.random() * n` (visuel) → `Seed.randVfx() * n`
- `Std.int(Math.random() * max)` → `Seed.random(max)` ou `Seed.randomVfx(max)` selon le contexte

Contraintes :

- ne pas faire de remplacement global aveugle
- analyser le contexte
- conserver un diff minimal
- ne pas casser la syntaxe Haxe
- utiliser les seed de vfx pour les randoms purement visuels
- utiliser les seed de gameplay pour les randoms qui influencent la logique du jeu
