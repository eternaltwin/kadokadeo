<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8" />
    <title>@yield('title', 'KadoKadéo')</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <script type="text/javascript">
        window.Kado = {
            public_key: '{{ str_replace("\n", "\\n", app(App\Services\RunService::class)->getPublicKey()) }}',
        }
        window.evts = new EventTarget();
        // window.evts.addEventListener('score', console.log);
        // window.evts.addEventListener('gameFinished', console.log);
    </script>

    @if (file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot')))
        @vite(['resources/css/app.css', 'resources/js/main.js'])
    @endif
</head>

<body>
    @include('components.validation-errors')
    <div id="app"></div>
</body>

</html>
