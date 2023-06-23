<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

// This class manages the non fatal errors and exceptions, called in index.php router
final class ErrorManager {

    // When an error occurs, we throw an exception
	public static function catchError($errno, $errstr,$error_file,$error_line) {
        throw new \Exception("EVNI (Erreur Volante Non Identifiée)");
	}

    public static function displayException(\Exception $e) {
        $errorMessage = $e->getMessage();
        include("../src/Views/Error.php");
	}
}
