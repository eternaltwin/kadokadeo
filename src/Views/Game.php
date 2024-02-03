<?php
    $gameName = 'Kanji';
	$title = 'KadoKadeo - Jouer - '.$gameName;
?>

<?php ob_start(); ?>
<div class="withRightAside">
	<h1 class="center"><?= $gameName; ?></h1>
    <div class="gameInterface">
		<canvas id="gameCanvas" width="300" height="320">
			<p>Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin de jouer.</p>
		</canvas>
		<script src="//cdn.jsdelivr.net/npm/phaser@3.60.0/dist/phaser.min.js"></script>
        <script src="/games/extendedClasses.js"></script>
		<script src="/games/11/gameParameters.js"></script>
        <script src="/games/gameGlobal.js"></script>
        <script src="/games/gameStart.js"></script>
        <script src="/games/11/game.js"></script>
        <script src="/games/gameEnd.js"></script>
        <script src="/games/gameLauncher.js"></script>
        <!--<script>
class buttonSwitch {
    constructor(arrayButton, arraySwitch) {
        try {
            if (arrayButton.length == arraySwitch.length) {
                this.arrayButton = arrayButton;
                this.arraySwitch = arraySwitch;
                for (let i = 0; i < arrayButton.length; i++) {
                    const elemButton = document.getElementById(arrayButton[i]);
                    let elemSwitch = document.getElementById(arraySwitch[i]);
                    if (elemButton === null || elemSwitch === null) {
                        throw 'err';
                    } else {
                    /* Faire addeventlistener pour chaque Button avec une fonction qui renvoie à la méthode statique à créer dans la classe pour l'objet */
                    }
                }
            } else {
                throw 'err';
            }
        } catch(err) {
            this.arrayButton = [];
            this.arraySwitch = [];
        }
        console.log(this.arrayButton);
        console.log(this.arraySwitch);
    }
}
        </script>-->

		<div class="gameSide">
			<nav class="gameNav">
				<ul>
					<li class="showed"><a href="#" title="Présentation" id="gameNavRules"><img src="/images/iconGameRules.png" alt="iconGameRules.png"> Règles</a></span></li>
					<li><a href="#" title="Mon score / Mes paliers" id="gameNavStars"><img src="/images/iconGameStars.png" alt="iconGameStars.png"> Paliers</a></li>
					<li><a href="#" title="Classement général" id="gameNavRanking"><img src="/images/iconGameRanking.png" alt="iconGameRanking.png"> Classement</a></li>
				</ul>
			</nav>

			<article id="gameRules">
				<p>Découvrez les mystères de ce jeu d'origine chinoise : vous devez faire correspondre symboles, formes et couleurs pour ramasser le plus de points.</p>
				<hr>
				<table class="gameCommands">
					<tr>
						<th class="col1">Commande</th>
						<th>Fonction</th>
					</tr>
					<tr>
						<td class="col1"><img src="/images/gameCommandLeftClic.png" title="Clic gauche" alt="Clic gauche"></td>
						<td>Sélectionner une pièce</td>
					</tr>
				</table>
			</article>

            <article id="gameStars" class="hidden">
				<p>Scores</p>
				<hr>
				<table class="gameCommands">
					<tr>
						<th class="col1">Commande</th>
						<th>Fonction</th>
					</tr>
					<tr>
						<td class="col1"><img src="/images/gameCommandLeftClic.png" title="Clic gauche" alt="Clic gauche"></td>
						<td>Sélectionner une pièce</td>
					</tr>
				</table>
			</article>

            <article id="gameRanking" class="hidden">
				<p>Classement</p>
				<hr>
				<table class="gameCommands">
					<tr>
						<th class="col1">Commande</th>
						<th>Fonction</th>
					</tr>
					<tr>
						<td class="col1"><img src="/images/gameCommandLeftClic.png" title="Clic gauche" alt="Clic gauche"></td>
						<td>Sélectionner une pièce</td>
					</tr>
				</table>
			</article>
		</div>
	</div>
</div>

<!-- Definition of the sections to show or hide when clicking on the button. See javascript buttonSwitch class. -->
<!--<script>
const check1 = new buttonSwitch(
    ['gameNavRules', 'gameNavStars', 'gameNavRanking'],
    ['gameRules', 'gameStars', 'gameRanking']
);
</script>-->

<?php $mainContent = ob_get_clean(); ?>

<?php require('Layouts/LoggedLayout.php'); ?>
