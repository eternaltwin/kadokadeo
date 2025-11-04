<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8" />
    <title>@yield('title', 'KadoKadéo')</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <script type="text/javascript">
        window.Kado = {
            public_key: '{{ str_replace("\n", "\\n", config('kado.security.public_key')) }}',
        }
    </script>

    @if (file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot')))
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    @endif
</head>

<body>
    <header id="topPage">
        <nav id="languageNav">
            <ul>
                <li>
                    <a href="#" title="Français">
                        <div data-lang="fr" alt="french" title="Français">
                    </a>
                </li>
            </ul>
        </nav>
        <h1><span>KadoKadeo</span></h1>
        @auth
            @include('components.navbar')
            @include('components.kalendrier')
            @include('components.starbar')
        @endauth
    </header>
    @if (!config('kado.security.private_key') || !config('kado.security.public_key'))
        <div class="my-4 flex h-12 bg-red-500 text-white font-bold w-full items-center justify-center">
            La clé publique/privée est manquante dans la
            configuration du serveur. Le site ne peut pas fonctionner sans.
        </div>
    @endif
    <main id="container">

        <section id="bodySection">
            <div class="error w-3/4 !mb-12">
                <div>
                    <p>
                        Kadokadéo est actuellement en alpha. Les scores que vous réaliserez finiront sans doute par être
                        supprimés.
                    </p>
                </div>
            </div>
            @yield('page')
        </section>

        @auth
            @include('components.sidebar')
        @endauth
    </main>
</body>

</html>
