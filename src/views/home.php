<?php $title = "Bienvenue sur KadoKadeo !"; ?>

<?php ob_start(); ?>
<main id="container" class="inColumns">
	<section class="twoCols">
		<h1 class="center">Inscription</h1>
		<p class="center">Si vous n'avez pas encore de compte, inscrivez-vous à l'aide du formulaire ci-dessous.</p>
		<form method="post" action="#" name="formRegister" class="centerMargin halfWidth">
			<div>
				<label for="pseudo">Pseudo : </label><br>
				<input type="text" name="pseudo" id="pseudo" maxlength="20">
			</div>
			<div>
				<label for="password1">Mot de passe : </label><br>
				<input type="password" name="password1" id="password1" maxlength="20">
			</div>
			<div>
				<label for="password2">Mot de passe (vérification) : </label><br>
				<input type="password" name="password2" id="password2" maxlength="20">
			</div>
			<div>
				<label for="emailAddress">Adresse e-mail : </label><br>
				<input type="email" name="emailAddress" id="emailAddress">
			</div>
			<div>
				<input type="submit" value="S'inscrire" class="center">
			</div>
		</form>
	</section>
	<section class="twoCols">
		<h1 class="center">Connexion</h1>
		<p class="center">Si vous avez déjà un compte, vous pouvez directement vous connecter.</p>
		<form method="post" action="#" name="formSignIn" class="centerMargin halfWidth">
			<div>
				<label for="pseudo">Pseudo : </label><br>
				<input type="text" name="pseudo" id="pseudo" maxlength="20">
			</div>
			<div>
				<label for="password">Mot de passe : </label><br>
				<input type="password" name="password" id="password" maxlength="20">
			</div>
			<div>
				<input type="submit" value="Se connecter" class="center">
			</div>
		</form>
	</section>
</main>
<?php $bodyContent = ob_get_clean(); ?>

<?php require('layouts/unloggedLayout.php'); ?>