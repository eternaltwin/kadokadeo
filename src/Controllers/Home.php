<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

final class Home {
	public static function view(): void {
        include("../src/Views/Home.php");
	}
}
