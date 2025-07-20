@extends('layouts.default')

@section('title', 'KadoKadeo - Mon compte')

@section('page')
    <div class="withRightAside">
        <h1 class="center">Mon compte</h1>
        <h2 style="margin-top:0;">Adresse e-mail</h2>
        <p>La fermeture annoncée de Twinoid et du site officiel de KadoKado a entraîné la mise en place du projet <span
                class="bold">KadoKadeo</span> par l'équipe d'Eternal-Twin.</p>
        <p>Cependant, KadoKadeo n'est pas encore prêt : du travail de développement, réalisé à 100% par des bénévoles
            passionnés, est encore nécessaire.</p>
        <p>Avec la fermeture de Twinoid, la communauté existante risque de se séparer et à part en vous informant via
            Discord, nous n'aurons aucun moyen de vous contacter.</p>
        <p>En renseignant votre adresse e-mail ci-dessous, nous pourrons vous tenir informés des grosses nouveautés sur
            KadoKadeo dans le futur.<br><span class="italic">Votre adresse e-mail ne sera pas rendue publique et nous ne
                l'utiliserons que dans le cadre d'informations concernant KadoKadeo.</span></p>

        @include('components.validation-errors')

        <form method="post" action="{{ route('account.update') }}" name="formSettingsMail" class="centerMargin"
            style="width:50%">
            @csrf
            <div>
                <label for="email">Adresse e-mail : </label><br>
                <input type="email" name="email" id="email" value="{{ auth()->user()->email }}" required>
            </div>
            <div>
                <input type="submit" value="Modifier l'e-mail" class="center">
            </div>
        </form>
    </div>
@endsection
