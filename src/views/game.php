<?php 
	$gameName = "Xian-Xiang";
	$title = "KadoKadeo - Jouer - ".$gameName;
?>

<?php ob_start(); ?>
<main id="container">
	<section class="gameSection">
		<h1 class="center fullWidth"><?php echo $gameName; ?></h1>
		<div class="gameInterface">
			<canvas id="gameCanvas" width="300" height="320">
				<p>Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin de jouer.</p>
			</canvas>
			<script src="../src/games/phaser/dist/phaser.js"></script>
			<script src="../src/games/Xian-Xiang/xian-xiang.js"></script>
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
							<td class="col1"><img src="images/gameCommandLeftClic.png" title="Clic gauche" alt="Clic gauche"></td>
							<td>Sélectionner une pièce</td>
						</tr>
					</table>
				</article>
			</div>
		</div>
	</section>
</main>
<?php $bodyContent = ob_get_clean(); ?>

<?php require('layouts/loggedLayout.php'); ?>