<?php
    $gameName = "Xian-Xiang";
	$title = "KadoKadeo - Jouer - ".$gameName;
?>

<?php ob_start(); ?>
<main id="container" class="withSidePadding">
	<section class="gameSection">
		<h1 class="center fullWidth"><?= $gameName; ?></h1>
		<div class="gameInterface">
			<canvas id="gameCanvas" width="300" height="320">
				<p>Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin de jouer.</p>
			</canvas>
			<script src="/games/phaser/dist/phaser.js"></script>
			<script src="/games/Xian-Xiang/xian-xiang.js"></script>
			<div class="gameSide">
				<nav class="gameNav">
					<ul>
						<li><a href="#" title="Présentation">Règles</a></li>
						<li><a href="#" title="Mon score / Mes paliers">Score</a></li>
						<li><a href="#" title="Classement général">Classement</a></li>
					</ul>
				</nav>
				<article class="gameInfo">
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
			</div>
		</div>
	</section>

    <aside id="containerSide">
        <nav class="sideBoxGreen">
            <h2>Menu</h2>
            <ul id="menuSide">
                <li class="news"><a href="#" title="Nouveautés">Nouveautés</a></li>
                <li class="scores"><a href="#" title="Mes scores">Mes scores</a></li>
                <li class="account"><a href="#" title="Mon compte">Mon compte</a></li>
                <li class="help"><a href="#" title="Aide">Aide</a></li>
            </ul>
        </nav>
        <aside class="sideBoxBlue">
            <h2>Top 3 clans</h2>
            <ul>
                <li>Clan n°1</li>
                <li>Clan n°2</li>
                <li>Clan n°3</li>
            </ul>
            <p class="center">Classement des clans...</p>
        </aside>
        <aside class="sideBoxPink">
            <h2>Nos autres jeux</h2>
            <ul>
                <li>Jeu n°1</li>
                <li>Jeu n°2</li>
                <li>Jeu n°3</li>
            </ul>
            <p class="center">Classement des clans...</p>
        </aside>
    </aside>
</main>
<?php $mainContent = ob_get_clean(); ?>

<?php require('Layouts/LoggedLayout.php'); ?>
