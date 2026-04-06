---
name: determinism
description: Rendre déterministes tous les usages non visuels du hasard dans le dossier fourni en paramètre.
---

Tu travailles sur un projet Haxe.

Objectif :
rendre déterministes tous les usages du hasard dans le dossier fourni en paramètre.

Principe :

- tout random qui influence la logique du jeu doit être seedé
- tout random purement visuel doit aussi être seedé

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

Contraintes :

- ne pas faire de remplacement global aveugle
- analyser le contexte
- conserver un diff minimal
- ne pas casser la syntaxe Haxe
- ne pas dupliquer les helpers dans `Cs`
