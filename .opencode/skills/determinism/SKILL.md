---
name: determinism
description: Rendre déterministes tous les usages non visuels du hasard dans le dossier fourni en paramètre.
---

Tu travailles sur un projet Haxe.

Objectif :
rendre déterministes tous les usages non visuels du hasard dans le dossier fourni en paramètre.

Principe :

- tout random qui influence la logique du jeu doit être seedé
- tout random purement visuel doit rester inchangé

Utiliser la classe `Cs` comme point d’entrée du random seedé.
Ajouter ces helpers dans `Cs` s’ils n’existent pas déjà :

```hx
public static inline function rand():Float {
    return KadoKadeoManager.kkm.seed.rand();
}

public static inline function random(max:Int):Int {
    if (max <= 0)
        return 0;
    return KadoKadeoManager.kkm.seed.random(max);
}
```

Transformations attendues :

- `Math.random()` → `Cs.rand()`
- `Std.random(max)` → `Cs.random(max)`

Remplacer aussi les calculs aléatoires dérivés quand c’est pertinent :

- `Math.random() * n` → `Cs.rand() * n`
- `Std.int(Math.random() * max)` → `Cs.random(max)` si l’équivalence est correcte

À remplacer :

- gameplay
- IA
- combat
- spawn
- loot
- génération
- timers logiques
- choix de comportement
- événements influençant l’état de la partie

Pour les effets visuels seulements, préférer ne pas remplacer, si les éléments n’ont pas d’impact sur la logique du jeu :

- particules
- variations d’animation
- offsets décoratifs
- effets graphiques
- rotation/alpha/scale purement cosmétiques

Contraintes :

- ne pas faire de remplacement global aveugle
- analyser le contexte
- en cas de doute, distinguer visuel vs logique
- conserver un diff minimal
- ne pas casser la syntaxe Haxe
- ne pas dupliquer les helpers dans `Cs`

En cas de doute, privilégier le déterminisme du gameplay : remplacer toute occurrence qui semble influer même indirectement sur l’état de la partie.
