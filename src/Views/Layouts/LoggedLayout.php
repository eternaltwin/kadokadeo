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
                <li><a href="#" title="Français"><img src="/images/langFrench.gif" alt="french" title="Français"></a></li>
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
                <li id="topBarKadoPoints"><span>0</span></li>
                <li id="topBarGreenStar"><span>0</span></li>
                <li id="topBarOrangeStar"><span>0</span></li>
                <li id="topBarRedStar"><span>0</span></li>
            </ul>
        </aside>
	</header>
    <main id="container">
        <section id="bodySection">
	        <?= $mainContent ?>
        </section>

        <aside id="containerSide">
            <nav class="sideBoxGreen">
                <h2>Menu</h2>
                <ul id="menuSide">
                    <li class="news"><a href="#" title="Nouveautés">Nouveautés</a></li>
                    <li class="scores"><a href="#" title="Mes scores">Mes scores</a></li>
                    <li class="account"><a href="user/settings" title="Mon compte">Mon compte</a></li>
                    <li class="help"><a href="#" title="Aide">Aide</a></li>
                </ul>
            </nav>
            <aside class="sideBoxBlue">
                <h2>Top 3 clans</h2>
                <ul>
                    <li class="center italic">Non disponible...</li>
                </ul>
            </aside>
            <aside class="sideBoxPink">
                <h2>Nos autres jeux</h2>
                <ul>
                    <li class="center" style="margin-bottom:5px;">
                        <a href="https://eternal-twin.net" title="Projet EternalTwin" class="bold">Projet EternalTwin</a><br>
                        <a href="https://discord.gg/ERc3svy" title="Discord EternalTwin">Nous rejoindre sur Discord</a>
                    </li>
                    <li><a href="https://eternalfest.net" title="Eternalfest">Eternalfest</a></li>
                    <li><a href="https://emush.eternaltwin.org" title="eMush">eMush</a></li>
                    <li><a href="https://neoparc.eternal-twin.net" title="Neoparc">Neoparc</a></li>
                    <li><a href="https://myhordes.eu" title="MyHordes">MyHordes</a></li>
                    <li><a href="https://directquiz.org" title="Directquiz">Directquiz</a></li>
                    <li><a href="https://brute.eternaltwin.org" title="La Brute">La Brute</a></li>
                    <li><a href="https://epopotamo.eternaltwin.org" title="ePopotamo">ePopotamo</a></li>
                    <li><a href="https://dinorpg.eternaltwin.org" title="DinoRPG">DinoRPG</a></li>
                    <li><a href="https://kingdom.eternaltwin.org" title="EternalKingdom">EternalKingdom</a></li>
                </ul>
            </aside>
        </aside>
    </main>
    
</body>
</html>