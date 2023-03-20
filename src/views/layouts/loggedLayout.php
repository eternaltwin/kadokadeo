<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<title><?= $title ?></title>
	<link rel="stylesheet" href="style.css" />
</head>
<body>
	<div id="loadFonts">
		<p style="font-family:Junegull-Regular;">.</p>
		<p style="font-family:Jost-Medium;">.</p>
	</div>
	<header id="topPage">
		<h1><span>KadoKadeo</span></h1>
		<nav id="topNav">
			<ul>
				<li><a href="#" id="topNavGames"><span>Jeux</span></a></li>
				<li><a href="#" id="topNavSite"><span>Site</span></a></li>
				<li><a href="#" id="topNavShop"><span>Kado</span></a></li>
			</ul>
		</nav>
	</header>
	<?= $bodyContent ?>
</body>
</html>