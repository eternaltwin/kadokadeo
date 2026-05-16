---
name: fix-replays-float
description: Stabiliser les replays qui divergent a cause de floats, trigo, collisions aux seuils, hitboxes graphiques ou etat statique mutable.
---

Tu travailles sur un projet Haxe KadoKadeo.

## Objectif

Corriger les divergences de replay qui apparaissent alors que les inputs et la seed sont identiques, souvent a cause de calculs flottants, collisions au seuil, etats graphiques utilises par le gameplay ou mutations statiques persistantes.

Ne pas chercher a supprimer tous les `Float`. Corriger d'abord les points de decision qui peuvent faire diverger le deroulement d'une partie.

## Quand utiliser ce skill

- Le replay ne reproduit pas exactement la partie live.
- Les scores, morts, collisions, pickups ou spawns divergent parfois.
- Le jeu utilise `Math.sin`, `Math.cos`, `Math.atan2`, `Math.sqrt`, `Math.pow`, des collisions distance/rectangle, ou des `getBounds()` dans la logique gameplay.
- Le jeu a deja un replay init, mais `recordEvents` est souvent `false` et seuls les inputs sont rejoues.

## Principes

- Sur la meme machine, `sin/cos` seuls sont generalement reproductibles si l'etat d'entree est identique.
- Le risque vient surtout de l'accumulation de floats suivie d'une decision stricte: collision, pickup, spawn, changement de niveau, mort, consommation RNG.
- Un decalage d'une frame peut changer l'ordre des collisions ou le nombre d'appels a `Seed.random`, puis toute la partie diverge.
- Les effets visuels peuvent rester flottants et libres tant qu'ils ne consomment pas la RNG gameplay et n'influencent pas la logique.

## Analyse initiale

Inspecter le dossier du jeu cible, en particulier `Game.hx`, les entites mobiles et les classes collision.

Chercher ces patterns:

- `getBounds()` ou dimensions graphiques utilisees pour des collisions gameplay.
- `dx * dx + dy * dy < r`, `r < threshold`, comparaisons `x/y` proches d'un seuil.
- `Math.sqrt`, `Math.atan2`, `Math.cos`, `Math.sin` dans des corrections de position ou collisions.
- `Seed.random(...)` dans des branches qui dependent de collisions/timers/longueurs de listes.
- Mutations de `static var` de configuration pendant une partie.
- Random visuel (`Seed.randomVfx`) qui modifie une logique gameplay, ou random gameplay utilise pour du pur visuel.

## Corrections recommandees

1. Isoler l'etat mutable par partie

- Ne pas muter un `static var` de config depuis une partie si la valeur peut survivre au replay suivant.
- Copier les tableaux de probabilites/config dans l'instance `Game` avant de les modifier.

Exemple:

```hx
var bonusProbas = Cs.BONUS_PROBAS_TBL.copy();
if (Seed.random(1000) == 0) {
	bonusProbas[2] = 3;
}
```

2. Remplacer les hitboxes graphiques par des hitboxes logiques

- Eviter `getBounds()` pour le gameplay.
- Definir des rectangles/cercle logiques stables a partir de constantes.
- Conserver `getBounds()` seulement pour debug/visuel si necessaire.

Exemple:

```hx
function localBox():{left:Float, right:Float, top:Float, bottom:Float} {
	return {left: -20, right: 20, top: -15, bottom: 15};
}
```

3. Quantifier aux points de decision

- Ajouter un helper local dans `Cs.hx` du jeu, avec un pas assez fin pour limiter les regressions.
- Quantifier les valeurs juste avant les collisions, pickups, seuils de timer/position et decisions de spawn.
- Ne pas quantifier tout aveuglement, surtout pas les effets visuels purs.

Exemple:

```hx
public static var COLLISION_QUANT:Int = 100;

public static inline function q(v:Float):Float {
	return Math.round(v * COLLISION_QUANT) / COLLISION_QUANT;
}
```

Usage:

```hx
var dx = Cs.q(a.x - b.x);
var dy = Cs.q(a.y - b.y);
if (dx * dx + dy * dy < ray2) {
	// gameplay
}
```

4. Stabiliser les collisions circulaires

- Garder la comparaison en distance au carre quand possible pour eviter `sqrt`.
- Si une distance reelle est necessaire pour separer deux objets, quantifier la distance et le push.
- Eviter `atan2 + cos + sin` pour convertir un vecteur deja connu. Utiliser directement `dx / distance` et `dy / distance`.

Avant:

```hx
var dist = Math.sqrt(dx * dx + dy * dy);
if (dist < ray * 2) {
	var a = Math.atan2(dy, dx);
	var push = (ray * 2 - dist) / 2;
	x -= push * Math.cos(a);
	y -= push * Math.sin(a);
}
```

Apres:

```hx
var dist = Cs.q(Math.sqrt(dx * dx + dy * dy));
if (dist < ray * 2) {
	var push = Cs.q((ray * 2 - dist) / 2);
	var ca = dist > 0 ? Cs.q(dx / dist * push) : push;
	var sa = dist > 0 ? Cs.q(dy / dist * push) : 0;
	x = Cs.q(x - ca);
	y = Cs.q(y - sa);
}
```

5. Stabiliser les inputs souris polled

- Si la position souris influence la physique ou une collision, quantifier `MouseManager.getX/getY()` avant usage.
- Verifier que `recordMousePosition: true` est active dans `replay.init` si la position souris influence le gameplay.

Exemple:

```hx
hero.ty = Cs.q(MouseManager.getY());
```

6. Separer RNG gameplay et VFX

- Gameplay: `Seed.random`, `Seed.rand`.
- Visuel pur: `Seed.randomVfx`, `Seed.randVfx`.
- Un effet visuel ne doit pas consommer la RNG gameplay si cela peut decaler les spawns ou collisions futures.

## Points d'attention

- Une quantification trop grossiere change le gameplay. Commencer a `100` (`0.01px`) ou plus fin si le jeu est sensible.
- Les corrections de hitbox peuvent changer la difficulte. Preferer des constantes proches des assets existants.
- Ne pas ajouter de compatibilite inutile: corriger le chemin actuel de replay.
- Ne pas regenerer manuellement les fichiers generes; compiler via la commande du projet.
- Dans ce repo, utiliser `make compile-games` pour compiler les jeux et bundles.

## Validation

- Compiler avec `make compile-games`.
- Lancer une partie live courte puis son replay.
- Verifier au minimum:
    - meme score final
    - meme frame/condition de mort ou de fin
    - memes pickups/collisions principales
    - absence de divergence apres plusieurs minutes si possible

## Checklist finale

- [ ] Pas de `getBounds()` dans les collisions gameplay.
- [ ] Pas de mutation persistante de config `static` pendant une partie.
- [ ] Les collisions/pickups au seuil quantifient leurs inputs.
- [ ] Les separations d'objets evitent `atan2 + cos + sin` quand `dx/dy` sont deja disponibles.
- [ ] Les positions souris qui influencent le gameplay sont enregistrees et quantifiees.
- [ ] Les randoms visuels utilisent `Seed.randomVfx` et ne decalent pas la RNG gameplay.
- [ ] `make compile-games` passe.
