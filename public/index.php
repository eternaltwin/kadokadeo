<?php declare(strict_types=1);
require_once "../vendor/autoload.php";

use \Kadokadeo\Games\Games;
?>
<!doctype html>
<html lang="en-US">
<head>
    <meta charset="utf-8">
    <title>Kadokadéo</title>
    <base href="/">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="icon" type="image/x-icon" href="/favicon.ico">
	<link rel="stylesheet" href="style.css" />
</head>
<body>
<h1>Kadokadéo</h1>
<ul>
    <?php foreach (Games::getAll() as $game) { ?>
        <li><?php echo htmlspecialchars($game) ?></li>
    <?php } ?>
</ul>
<dl>
    <dt>Request URI:</dt>
    <dd><?php echo htmlspecialchars($_SERVER["REQUEST_URI"] ?? "/")?></dd>
</dl>
</body>
</html>
