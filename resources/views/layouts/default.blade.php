<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8" />
    <title>@yield('title', 'KadoKadéo')</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    @if (file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot')))
        @vite([
            'resources/css/app.css',
            // 'resources/js/app.js',
        ])
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
    <main id="container">
        <section id="bodySection">
            @yield('page')
        </section>

        @auth
            @include('components.sidebar')
        @endauth
    </main>
</body>

</html>
