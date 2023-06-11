<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<title><?= $title ?></title>
	<link rel="stylesheet" href="/style.css" />
</head>
<body>
	<div id="loadFonts">
		<p style="font-family:Junegull-Regular;">.</p>
		<p style="font-family:Jost-Medium;">.</p>
	</div>
	<header id="topPage">
        <nav id="languageNav">
            <ul>
                <li><a href="#" title="Français"><img src="images/langFrench.gif" alt="french" title="Français"></a></li>
            </ul>
        </nav>
		<h1><span>KadoKadeo</span></h1>
		<nav id="topNav">
			<ul>
				<li><a href="#" id="topNavGames"><span>Jeux</span></a></li>
				<li><a href="#" id="topNavSite"><span>Site</span></a></li>
				<li><a href="#" id="topNavShop"><span>Kado</span></a></li>
			</ul>
		</nav>
        <nav id="kalendrier">
            <ul>
                <li id="kalUser">
                    <a href="#" title="Préférences du compte">
                    <?= htmlspecialchars($_SESSION['username']); ?>
                    </a> (<a href="signout" title="Déconnexion">déconnecter</a>)
                </li>
            </ul>
        </nav>
        <aside id="topBarInfo">
            <ul>
                <li id="topBarKadoPoints"><span>1265</span></li>
            </ul>
        </aside>
	</header>
	<?= $mainContent ?>
</body>
</html>