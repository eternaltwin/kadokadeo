<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

final class Home {
	public static function view() {
		include("../src/Views/Home.php");
	}
}
