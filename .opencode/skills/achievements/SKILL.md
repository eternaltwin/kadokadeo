---
name: achievements
description: Expliquer et implementer les achievements d'un jeu KadoKadeo a partir des stats envoyees par le jeu et d'une capture Excel.
---

Tu travailles sur un projet Laravel + Haxe KadoKadeo.

## Objectif

Creer ou modifier les regles serveur d'achievements pour un jeu, puis ajouter les achievements correspondants dans le seeder.

Les sources Haxe des jeux sont dans `resources/hx/games/`.
Les rules serveur sont dans `app/Achievements/Rules/Games/`.
Les achievements seedes sont dans `database/seeders/AchievementsSeeder.php`.

## Entrees attendues

Le travail se fait generalement en deux temps:

1. L'utilisateur donne le jeu, les variables de stats envoyees en fin de partie, leur contenu et les validations attendues.
2. L'utilisateur envoie une capture Excel listant les succes a creer: cle, titre, description, seuils, recompenses ou autres infos visibles.

Si une information est ambigue, manquante ou contradictoire, demander confirmation avant d'implementer. Ne pas deviner une regle metier.

## Principes importants

- Chaque jeu envoie des stats en fin de partie; les achievements ne doivent faire confiance qu'aux stats validees cote serveur.
- La rule principale du jeu doit verifier uniquement les variables demandees par l'utilisateur.
- Ne pas recalculer le score ou la coherence complete de la partie sauf demande explicite: certains scores sont trop complexes a recalculer.
- Les rules specifiques d'achievement doivent suivre les conventions existantes du dossier du jeu.
- Dans les descriptions du seeder, formatter les grands nombres avec des points comme separateurs: `1.000`, `25.000`, `1.000.000`.
- Ne pas modifier les fichiers generes Haxe/JS pour les achievements serveur sauf si l'utilisateur demande explicitement d'ajouter de nouvelles stats cote jeu.

## Workflow recommande

1. Identifier le jeu

- Trouver le dossier Haxe: `resources/hx/games/<game>`.
- Trouver ou creer le dossier de rules: `app/Achievements/Rules/Games/<GameName>/`.
- Verifier le mapping `game_key` utilise dans `AchievementsSeeder.php` avec les exemples existants.

2. Analyser les rules existantes

- Lire la rule principale du jeu si elle existe, par exemple `KSlashRule.php`.
- Lire quelques rules specifiques du meme jeu pour respecter le style de validation et de calcul de progression.
- Lire une section proche dans `database/seeders/AchievementsSeeder.php` pour conserver le style du seeder.

3. Implementer ou modifier la rule principale

- La fonction `validate` doit retourner `true` si les stats necessaires sont considerees valides, sinon `false`.
- Recuperer les stats avec `data_get`, par exemple:

```php
$bads = data_get($event->stats, 'bads', []);
```

- Valider uniquement ce qui a ete specifie par l'utilisateur: types, bornes, valeurs autorisees, structure de tableaux, compteurs non negatifs, etc.
- Refuser les stats invalides ou inattendues quand elles concernent les variables utilisees par les achievements.
- Ne pas ajouter de validation speculative basee sur le score, la duree ou des mecanismes internes non demandes.

4. Creer les rules d'achievements

- Creer une classe par achievement dans `app/Achievements/Rules/Games/<GameName>/` si le repo suit deja ce modele pour le jeu.
- Nommer les classes selon les conventions existantes: `<GameName><AchievementName>Rule`.
- Utiliser les stats deja validees par la rule principale.
- Retourner la valeur/progression attendue selon les patterns existants du projet.
- Pour les achievements cumulatifs, suivre les exemples existants avec `AchievementProgressScope::LIFETIME` dans le seeder.
- Pour les achievements en une partie, suivre aussi les exemples existants: le scope reste souvent `LIFETIME`, mais la rule retourne une progression issue d'une seule run.

5. Ajouter les achievements au seeder

- Ajouter ou completer la methode `create<GameName>Achievements()`.
- Ajouter l'appel a cette methode dans `run()` si le jeu n'a pas encore de section.
- Recuperer le jeu via son `game_key`:

```php
$game = $this->games->where('game_key', '<game_key>')->first();
if (!$game) {
    return;
}
```

- Creer les achievements et leurs levels en suivant exactement le style existant:

```php
$achievement = $game->achievements()->create(['game_id' => $game->id, 'key' => '<key>', 'category' => AchievementCategory::GAME, 'progress_scope' => AchievementProgressScope::LIFETIME]);
$achievement->levels()->create(['level' => 1, 'target' => 1000, 'reward' => 100, 'title' => '<titre>', 'description' => '<description avec 1.000 si besoin>']);
```

- Utiliser les titres, descriptions, targets et rewards fournis dans la capture Excel.
- Si une valeur de la capture est illisible ou incertaine, demander confirmation.

## Points d'attention

- Les noms de dossiers rules utilisent le casing PHP existant (`KSlash`, `F1Champion`, `Opalus2`, etc.).
- Les dossiers Haxe utilisent un nom minuscule (`kslash`, `f1champion`, `opalus2`).
- Les classes PHP doivent avoir le bon namespace `App\Achievements\Rules\Games\<GameName>`.
- Ne pas creer de compatibilite retroactive inutile.
- Ne pas renommer des keys d'achievements existantes sans demande explicite.
- Ne pas modifier les achievements communs (`stars`, `paradise_league`) sauf demande explicite.

## Verification

La verification minimale attendue est de controler que les fichiers PHP modifies sont syntaxiquement valides:

```sh
php -l app/Achievements/Rules/Games/<GameName>/<Rule>.php
php -l database/seeders/AchievementsSeeder.php
```

Si `php` n'est pas disponible localement, indiquer que la verification syntaxique n'a pas pu etre lancee.
