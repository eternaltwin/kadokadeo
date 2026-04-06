---
name: mt-to-haxe
description: Transformer du code legacy .mt vers .hx en respectant les conventions de code Haxe.
---

Tu travailles sur un projet Haxe.

## Objectif

Transformer du code legacy proche de Haxe vers une version modernisée respectant les conventions suivantes :

- syntaxe stricte (points-virgules, types)
- structures idiomatiques (boucles, classes)
- intégration avec les librairies cibles

---

## ⚠️ Niveaux de transformation

### 🟢 Niveau 1 — Safe (textuel, sans logique)

Transformations simples, sans impact sur la structure du code.

### 🟡 Niveau 2 — Syntaxique

Transformations nécessitant une compréhension de la structure du code.

### 🔴 Niveau 3 — Contextuel (dangereux)

Transformations dépendantes du comportement du code. À appliquer uniquement si les conditions sont clairement remplies.

---

# Règles de transformation

---

## 🟢 Supprimer le fichier Manager s'il existe

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

## 🟢 Ajout du nom du package en haut de chaque fichier du dossier

Ajouter `package <NomDuDossier>;` en haut des fichiers s'il n'est pas déjà présent

Si le dosser s'appelle interwheel, il faut ajouter `package interwheel;` en haut de tous les fichiers du dossier.

## 🟢 Ajout des points-virgules

Ajouter un `;` à la fin de chaque instruction.

### Exemple

Avant :

```
var x = 10
```

Après :

```
var x = 10;
```

---

## 🟢 Conversion des types

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

## 🟡 Transformation des boucles for

### Objectif

Remplacer les boucles for par :
• soit un for ... in
• soit un while si l'index d'itération est modifié dans la boucle

---

### 🟢 Cas 1 — Intervalle simple

Avant :

```
for( var x=0; x<Cs.GRID_MAX; x++ ){
```

Après :

```
for (x in 0...Cs.GRID_MAX) {
```

---

### 🟢 Cas 2 — Parcours de tableau

Avant :

```
for( var i=0; i<dList.length; i++ ){
	var pos = dList[i]
}
```

Après :

```
for (pos in dList) {
}
```

---

### 🔴 Cas 3 — Modification de l’index

Si l’index (i) est modifié dans la boucle → utiliser un while.

Avant :

```
for( var i=0; i<fList.length; i++ ){
	var p = fList[i]
	if(p.y>Cs.mch+Cs.SIZE){
		p.kill();
		fList.splice(i--,1)
	}
}
```

Après :

```
var i = 0;
while(i<fList.length){
	var p = fList[i]
	if(p.y>Cs.mch+Cs.SIZE){
		p.kill();
		fList.splice(i--,1)
	}
	i++;
}
```

---

## 🔴 Transformation des structures {>ASprite,...} en classes

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

var grid:Array<Array<GridSprite>>
```

---

## 🟢 Remplacement de fonctions utilitaires

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

## 🔴 Transformation de la classe Game

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
public function new(kkm:kado.KadoKadeoManager, root:ASprite, ?isReplay:Bool = false) {
```

---

### DepthManager

Si un DepthManager est instancié :
• lui passer root en paramètre

---

## 🟡 8. Classe Cs

### Objectif

Rendre tous les membres publics.

### Exemple

Avant :

```
static var mcw = 300;
```

Après :

```
public static var mcw = 300;
```

---

## 🟢 Switch / case

### Objectif

Avoir du code compatible Haxe

### Règles

#### Retirer les `break` de premier niveau

Avant:

```
case 1: // DESTROY
    var prc = (1-timer/Cs.TIME_EXPLODE)*100
    break;
```

Après:

```
case 1: // DESTROY
    var prc = (1-timer/Cs.TIME_EXPLODE)*100
```

#### Si le corps du case est vide, retirer le case :

Avant:

```
switch (step) {
    case 0: // CHOICE
        break;
    case 1: // DESTROY
    // ...
}
```

Après:

```
switch (step) {
    case 1: // DESTROY
    // ...
}
```

#### Remplacer `default:` par `case _:`

Avant:

```
switch (step) {
    default:
        var i = 0;
}
```

Après:

```
switch (step) {
    case _:
        var i = 0;
}
```

#### Changer l'imbrication de case par un case compatible haxe (0 | 1 ...):

Avant:

```
switch (step) {
    case 1:
    case 2:
    case 3:
        var i = 0;
        // ...
    case 4:
        var x = 0;
        // ...
}
```

Après:

```
switch (step) {
    case 1 | 2 | 3:
        var i = 0;
        // ...
    case 4:
        var x = 0;
        // ...
}
```

---

## 🟡 Changer la visibilité des membres de classe par "public" lorsqu'ils sont utilisés dans les autres classes

### Objectif

Ne pas avoir de problème de compilation en accédant à un attribut ou méthode de classe privé

### Règles

#### 🟡 Ajouter `public` aux membres de classe utilisés dans les autres classes

#### 🟡 Ajouter `public` aux méthodes de classe utilisées dans les autres classes

#### 🟡 Ajouter `override` aux méthodes qui ont une méthode surchargée

### Exemples

#### Attribut privé devenant public

```
class Game implements GameInterface {
    var dm:DepthManager;
    // ...
}
```

Si le dm est utilisé dans une autre classe (exemple avec blob :)

```
class Blob {
    public function new(mc) {
        Cs.game.dm.attach(mc);
    }
}
```

Changer l'attribut de la classe Game en `public`:

```
class Game implements GameInterface {
    public var dm:DepthManager;
    // ...
}
```

#### Méthode privée devant public

Avant :

```
class Blob {
    function new(mc) {
        Cs.game.dm.attach(mc);
    }
}
```

Et dans Game:

```
var blob = new Blob(new ASprite())
```

Après :

```
class Blob {
    public function new(mc) {
        Cs.game.dm.attach(mc);
    }
}
```

## 🟢 Enlever les commentaires inutiles

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

## 🟢 Remplacer les literals int() et string() par Std.int() et Std.string()

## 🔴 Remplacer les break de second niveau dans les switch/case

### Objectif

Garder une logique de break claire et éviter les confusions avec les break de premier niveau.

### Règles

Pour enlever le break de second niveau, il faut :

- Identifier les break de second niveau (un break dans une condition de case)
- Refactorer la logique pour éviter d'avoir besoin de ce break (ex: en utilisant des if/else)
- S'assurer que la logique métier est préservée et que le code reste lisible.

## 🟡 Renommage des clés d'objet contenant des `$`

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

## 🟡 Gestion des inputs clavier

Remplacer les `Key.` par l'import `common_haxe_avm1.KeyboardManager`.
S'il existe, retirer le `Key.init()`

## 🟢 Sprite.spriteList

Remplacer les itérations sur `Sprite.spriteList` par un appel à `Sprite.updateAll()`.

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

---

# 🧪 Stratégie d’application

1. Appliquer d’abord les règles 🟢 (safe)
2. Puis les règles 🟡 (syntaxiques)
3. Enfin les règles 🔴 (contextuelles, avec prudence)

---

# 🚫 Cas à éviter

    •	Boucles complexes non reconnues
    •	Structures ambiguës
    •	Code dépendant d’effets de bord non clairs

Dans ces cas : ne pas modifier.
