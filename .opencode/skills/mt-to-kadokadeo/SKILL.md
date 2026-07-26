---
name: mt-to-kadokadeo
description: Transformer du code legacy .hx vers une classe compatible avec l'API KadoKadeo.
---

Tu travailles sur un projet Haxe.

## Objectif

Adapter le code original pour qu'il soit compatible avec l'API KadoKadeo

---

## Créer le fichier import.hx s'il n'existe pas

Avec le contenu suivant :

```
package <nomdudossier>;

using Std;
using Lambda;
using StringTools;
using common_haxe_avm1.PixelHelper;

import common_haxe_avm1.display.ASprite;
```

---

## Ajout du nom du package en haut de chaque fichier du dossier

Ajouter `package <NomDuDossier>;` en haut des fichiers s'il n'est pas déjà présent

Si le dossier s'appelle interwheel, il faut ajouter `package interwheel;` en haut de tous les fichiers du dossier.

---

## Conversion des types

Remplacer les types selon le mapping suivant :

| Ancien    | Nouveau |
| --------- | ------- |
| int       | Int     |
| float     | Float   |
| bool      | Bool    |
| void      | Void    |
| MovieClip | ASprite |
| KKConst   | Int     |

---

## Transformation des structures {>ASprite,...} en classes

### Objectif

Transformer les structures anonymes étendant ASprite en classes nommées.

### Règles

Détecter les structures de type :

{>ASprite, ...}

- Créer une classe :
-   - Nom = nom de la variable + Sprite
-   - Format = PascalCase
- Ajouter la classe :
-   - en haut du fichier
-   - après les imports

---

### Exemple

Avant :

```
var grid:Array<Array<{>ASprite,flDead:bool}>>
```

Après :

```
class GridSprite extends ASprite {
	public var flDead: Bool;
}

// ...

var grid:Array<Array<GridSprite>>
```

---

## Remplacement de fonctions utilitaires

### Mapping

    •	setPercentColor → Col.setPercentColor
    •	mm, hMod, sMod → Num.mm, Num.hMod, Num.sMod

### Source

Ces fonctions proviennent de :

```
mt.bumdum.Lib
```

---

## 🟡 Gestion des imports

Ajouter les imports uniquement si utilisés :

| Élément utilisé | Import à ajouter       |
| --------------- | ---------------------- |
| Timer           | mt.Timer               |
| DepthManager    | mt.DepthManager        |
| KKApi           | common_haxe_avm1.KKApi |

---

## Transformation de la classe Game

### Objectif

Adapter la classe Game à l’API cible.

### Règles

- Le nom exposé dépend du nom du dossier
- Format : Game<NomDuJeu> (PascalCase)
- Si elle existe, renommer la méthode `main()` en `update(delta:Float)`

---

#### Exemple (dossier : interwheel)

Avant :

```
class Game {
```

Après :

```
@:expose('GameInterwheel')
class Game implements kado.GameInterface {
```

---

### Constructeur

Doit être remplacé par :

```
public function new(root:ASprite, ?isReplay:Bool = false) {
```

---

### DepthManager

Si un DepthManager est instancié :
• lui passer root en paramètre

---

## Enlever les commentaires inutiles

### Exemple

Avant:

```
class Bads extends Phys {//}
  //{
}
```

Après:

```
class Bads extends Phys {
}
```

## Renommer les clés d'objet contenant des `$`

Enlever le `$` de la clé et remplacer toute ses utilisations.

Exemple typique :

```
var stats = {
    $b: [],
    $k: 0
}

stats.$b.push(1);
stats.$k++;
```

Devient :

```
var stats = {
    b: [],
    k: 0
}
stats.b.push(1);
stats.k++;
```

## Gestion des inputs clavier

Remplacer les `Key.` par l'import `common_haxe_avm1.KeyboardManager`.
S'il existe, retirer le `Key.init()`

## Sprite.spriteList

Remplacer les itérations sur `Sprite.spriteList` par un appel à `Sprite.updateAll()`.

## KKApi.addScore(), KKApi.gameOver()

Ces fonctions doivent être remplacées par des appels à `KadoKadeoManager.addScore()` et `KadoKadeoManager.gameOver()` respectivement.

---

# ⚠️ Contraintes globales

• Ne jamais casser la logique métier
• Conserver l’indentation
• Ne pas renommer les variables (sauf règles explicites)
• Ne pas transformer si ambigu
• Préférer ne rien faire plutôt qu’une transformation incorrecte

# Important

- Pour compiler, il faut utiliser la commande suivante à la racine du projet :

```
docker exec -u dev -w /www kadokadeo_app haxe \
-L pixijs \
-L crypto \
-L jsImport \
-cp ./resources/hx/lib \
-cp ./resources/hx/games \
-debug \
-js /tmp/<nomdudossier>.js \
<nomdudossier>.Game
```

- Si le jeu ne compile pas pour d'autres raisons, ne pas les corriger et avertir l'utilisateur qu'il faudrait documenter les autres modifications à faire (dans ce skill) pour que le jeu compile.
