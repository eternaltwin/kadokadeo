---
name: scale
description: Multiplier tous les calculs de taille, position et deplacement par un facteur de scale pour adapter le jeu a un ratio plus grand.
---

Tu travailles sur un projet Haxe KadoKadeo.

## Objectif

Les jeux originaux sont en 300x300. Le but est de les rendre compatible en 900x900.

Il faut que tu ajoutes une constante dans le fichier Cs.hx :

```
public static var NEW_GEN_SCALE = 3;
```

Puis que tu multiplies toutes les valeurs de position, taille, deplacement... par ce facteur de scale dans tous les fichiers du dossier.

## Valeurs à multiplier

- position
- taille (rayon, width, height...)
- deplacement (vx, vy, speed...)

## Valeurs à ne pas multiplier

- angles (rotation, direction...)
- valeurs de logique (hp, score, timers...)
- valeurs de gameplay (dégats)
- valeurs de configuration (nombre d'ennemis, fréquence d'apparition...)
- types de projectiles, numéros de frames...
