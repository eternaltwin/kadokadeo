<?php $title = "KadoKadeOOPS!"; ?>

<?php ob_start(); ?>
<section>
    <h1 class="center">OOPS !</h1>
    <p class="center"><?= $errorMessage; ?></p>
</section>
<?php $mainContent = ob_get_clean(); ?>

<?php include('Layouts/UnloggedLayout.php'); ?>
