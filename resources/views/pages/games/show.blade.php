@extends('layouts.default')

@section('title', 'KadoKadeo - Jeux')

@php
// dd($game->controls->first()->pivot->description);
@endphp

@section('page')
    <div class="withRightAside">
	    <h1 class="center">{{ $game->name }}</h1>
        @if (config('kado.games_per_day') > 0)
            <p>Il vous reste {{ Auth::user()->kado_games }} parties à jouer aujourd'hui</p>
        @endif 

        <div id="gameInterface">
            <!-- TO DO : Personnaliser la barre de chargement -->
            <div id="status" style="position:absolute;top:180px; left: 90px;">
                <progress id="status-progress"></progress>
                <div id="status-notice"></div>
            </div>
            <canvas id="gameCanvas" width="300" height="320">
                <p>Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin de jouer.</p>
            </canvas>

            <nav id="gameUpperButtons">
                <ul>
                    <li><a href="#" title="titre"><img src="/gfx/iconGameZoom.gif" alt="iconGameZoom.gif" width="15" height="15"> Zoom</a></li>
                    <li><a href="#" title="titre"><img src="/gfx/iconGameDisliked.gif" alt="iconGameDisliked.gif"> Favori</a></a></li>
                </ul>
            </nav>

            <div class="gameSide">
                <nav class="gameNav">
                    <ul>
                        <li class="showed"><a href="#" title="Présentation" id="gameNavRules"><img src="/gfx/iconGameRules.png" alt="iconGameRules.png"> Règles</a></li>
                        <li><a href="#" title="Mon score / Mes paliers" id="gameNavStars"><img src="/gfx/iconGameStars.png" alt="iconGameStars.png"> Paliers</a></li>
                        <li><a href="#" title="Classement général" id="gameNavRanking"><img src="/gfx/iconGameRanking.png" alt="iconGameRanking.png"> Classement</a></li>
                    </ul>
                </nav>

                <article id="gameRules">
                    <p>Au secours, c'est l'inondation ! Aidez Krakra, la petite tâche de crasse, à s'évader de la salle de bain du temple aztèque Tenochtitlan. Attention aux mines ancestrales du grand Quetzal !</p>
                    <hr>
                    <table class="gameCommands">
                        <tr>
                            <th style="width: 70px;">Commande</th>
                            <th>Fonction</th>
                        </tr>
                        <tr>
                            <td><img src="/gfx/gameCommandLeftClic.png" title="Clic gauche" alt="Clic gauche"></td>
                            <td>Sauter</td>
                        </tr>
                    </table>
                </article>

                <article id="gameStars" class="hidden">
                    <p>Scores</p>
                </article>

                <article id="gameRanking" class="hidden">
                    <p>Classement</p>
                </article>
            </div>
        </div>
    </div>

    <script src="/gamesdata/godot.js"></script>
    @php
        $gameName = \Illuminate\Support\Str::slug($game->name, '_');
    @endphp
    <script>
        const GODOT_CONFIG = {
            "args": [],
            "canvasResizePolicy": 0,
            "ensureCrossOriginIsolationHeaders": true,
            "executable": "/gamesdata/godot",
            "mainPack": "/gamesdata/{{ $gameName }}.pck",
            "experimentalVK": false,
            "fileSizes": {
                "/gamesdata/{{ $gameName }}.pck": 1798592,
                "/gamesdata/godot.wasm": 31000000
            },
            "focusCanvas": false,
            "gdextensionLibs": []
        };
        const GODOT_THREADS_ENABLED = false;
        const engine = new Engine(GODOT_CONFIG);

        (function() {
            const statusOverlay = document.getElementById('status');
            const statusProgress = document.getElementById('status-progress');
            const statusNotice = document.getElementById('status-notice');

            let initializing = true;
            let statusMode = '';

            function setStatusMode(mode) {
                if (statusMode === mode || !initializing) {
                    return;
                }
                if (mode === 'hidden') {
                    statusOverlay.remove();
                    initializing = false;
                    return;
                }
                statusOverlay.style.visibility = 'visible';
                statusProgress.style.display = mode === 'progress' ? 'block' : 'none';
                statusNotice.style.display = mode === 'notice' ? 'block' : 'none';
                statusMode = mode;
            }

            function setStatusNotice(text) {
                while (statusNotice.lastChild) {
                    statusNotice.removeChild(statusNotice.lastChild);
                }
                const lines = text.split('\n');
                lines.forEach((line) => {
                    statusNotice.appendChild(document.createTextNode(line));
                    statusNotice.appendChild(document.createElement('br'));
                });
            }

            function displayFailureNotice(err) {
                console.error(err);
                if (err instanceof Error) {
                    setStatusNotice(err.message);
                } else if (typeof err === 'string') {
                    setStatusNotice(err);
                } else {
                    setStatusNotice('An unknown error occurred.');
                }
                setStatusMode('notice');
                initializing = false;
            }

            const missing = Engine.getMissingFeatures({
                threads: GODOT_THREADS_ENABLED,
            });

            if (missing.length !== 0) {
                if (GODOT_CONFIG['serviceWorker'] && GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] &&
                    'serviceWorker' in navigator) {
                    let serviceWorkerRegistrationPromise;
                    try {
                        serviceWorkerRegistrationPromise = navigator.serviceWorker.getRegistration();
                    } catch (err) {
                        serviceWorkerRegistrationPromise = Promise.reject(new Error(
                            'Service worker registration failed.'));
                    }
                    // There's a chance that installing the service worker would fix the issue
                    Promise.race([
                        serviceWorkerRegistrationPromise.then((registration) => {
                            if (registration != null) {
                                return Promise.reject(new Error('Service worker already exists.'));
                            }
                            return registration;
                        }).then(() => engine.installServiceWorker()),
                        // For some reason, `getRegistration()` can stall
                        new Promise((resolve) => {
                            setTimeout(() => resolve(), 2000);
                        }),
                    ]).then(() => {
                        // Reload if there was no error.
                        window.location.reload();
                    }).catch((err) => {
                        console.error('Error while registering service worker:', err);
                    });
                } else {
                    // Display the message as usual
                    const missingMsg =
                        'Error\nThe following features required to run Godot projects on the Web are missing:\n';
                    displayFailureNotice(missingMsg + missing.join('\n'));
                }
            } else {
                setStatusMode('progress');
                engine.startGame({
                    'onProgress': function(current, total) {
                        if (current > 0 && total > 0) {
                            statusProgress.value = current;
                            statusProgress.max = total;
                        } else {
                            statusProgress.removeAttribute('value');
                            statusProgress.removeAttribute('max');
                        }
                    },
                }).then(() => {
                    setStatusMode('hidden');
                }, displayFailureNotice);
            }
        }());
    </script>
@endsection