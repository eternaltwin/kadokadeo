---
name: scale
description: (Legacy) Multiplier tous les calculs de taille, position et deplacement par un facteur de scale pour adapter le jeu a un ratio plus grand. Pour un nouveau portage, utiliser flash-port (racine a x2).
---

Tu travailles sur un projet Haxe KadoKadeo.

> **Legacy.** Pour un nouveau portage, ne pas utiliser ce skill : garder les coordonnées d'origine et mettre le
> conteneur racine à x2 (voir `.opencode/skills/flash-port/references/code.md`, section « Scale »). Ce skill ne sert
> plus qu'à comprendre ou corriger les anciens portages qui utilisent `KadoKadeoManager.S()` / `I()`.

## Objectif

Les jeux originaux sont en 300x300. Le but est de les rendre compatible en 600x600.

## Méthode

Pour les valeurs Int qui sont scalées, utilise la fonction `KadoKadeoManager.I(Int)`. Pour les floats, utilise `KadoKadeoManager.S(Float)`.

S'il n'y est pas, ajoute l'import `import kado.KadoKadeoManager;` dans le fichier import.hx.

## Valeurs à multiplier

Il faut multiplier toutes les valeurs de position, taille, deplacement... en utilisant les fonctions `I` et `S` dans tous les fichiers du dossier où la taille d'un élément a besoin d'êrte scalée.

- position (x, y...)
- taille (rayon, width, height...)
- deplacement (vx, vy, speed...)

## Valeurs à ne pas multiplier

- angles (rotation, direction...)
- valeurs de logique (hp, score, timers...)
- scales (\_scalex, \_scaley...)
- valeurs de gameplay (dégats)
- valeurs de configuration (nombre d'ennemis, fréquence d'apparition...)
- types de projectiles, numéros de frames...
