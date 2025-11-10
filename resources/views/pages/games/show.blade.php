@extends('layouts.default')

@section('title', 'KadoKadeo - Jeux')

@php
// dd($game->controls->first()->pivot->description);
@endphp

@section('page')
    <script>
        class SwitchTab {
            /* arrayTab is an array with the ID of each tab that can be clicked ; arrayPages are the pages ID, in the same order that can be hidden or showed when clicking on the tab */
            constructor(arrayTab, arrayPages) {
                try {
                    if (arrayTab.length == arrayPages.length) {
                        this.arrayTab = arrayTab;
                        this.arrayPages = arrayPages;
                        for (let i = 0; i < arrayTab.length; i++) {
                            let elemTab = document.getElementById(arrayTab[i]);
                            let elemPage = document.getElementById(arrayPages[i]);
                            if (elemTab === null || elemPage === null) {
                                throw 'err';
                            } else {
                                elemTab.addEventListener("click", () => {
                                    this.MakingSwitches(i);
                                });
                            }
                        }
                    } else {
                        throw 'err';
                    }
                } catch(err) {
                    this.arrayTab = [];
                    this.arrayPages = [];
                }
            }

            /* Making visible the page associated to the clicked tab ; making hidden the other pages ; iClicked is the clicked ID in arrayTab and arrayPages */
            MakingSwitches(iClicked) {
                for (let i = 0; i < this.arrayTab.length; i++) {
                    document.getElementById(this.arrayTab[i]).classList.remove("showed");
                    document.getElementById(this.arrayPages[i]).classList.add("hidden");
                }
                document.getElementById(this.arrayTab[iClicked]).classList.add("showed");
                document.getElementById(this.arrayPages[iClicked]).classList.remove("hidden");
            }
        }
    </script>
    <script>
        function ZoomManager() {
            let divZoom = document.querySelector("div[id^='gameZoom']");
            if (divZoom !== null) {
                let gameCanvas = document.getElementById("gameCanvas");
                let divZoomAttribute = divZoom.getAttribute("id");
                if (divZoomAttribute == "gameZoomOut") {
                    divZoom.id = "gameZoomIn";
                    gameCanvas.setAttribute("width", "600");
                    gameCanvas.setAttribute("height", "640");
                } else {
                    divZoom.id = "gameZoomOut";
                    gameCanvas.setAttribute("width", "300");
                    gameCanvas.setAttribute("height", "320");
                }
            }
        }
    </script>
    <div class="withRightAside">
	    <h1 class="center">{{ $game->name }}</h1>
        @if (config('kado.games_per_day') > 0)
            <p>Il vous reste {{ Auth::user()->kado_games }} parties à jouer aujourd'hui</p>
        @endif
        <div id="gameZoomOut">
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
                        <li><a href="#" title="Zoom / dézoom" onclick="ZoomManager()"><img src="/gfx/iconGameZoom.gif" alt="iconGameZoom.gif" width="15" height="15"> Zoom</a></li>
                        <li><a href="#" title="Ajouter/retirer des jeux favoris"><img src="/gfx/iconGameDisliked.gif" alt="iconGameDisliked.gif"> Favori</a></a></li>
                    </ul>
                </nav>

                <div class="gameSide">
                    <nav class="gameNav">
                        <ul>
                            <li class="showed" id="gameNavRules"><a href="#" title="Présentation"><img src="/gfx/iconGameRules.png" alt="iconGameRules.png"> Règles</a></li>
                            <li id="gameNavStars"><a href="#" title="Mon score / Mes paliers"><img src="/gfx/iconGameStars.png" alt="iconGameStars.png"> Paliers</a></li>
                            <li id="gameNavRanking"><a href="#" title="Classement général"><img src="/gfx/iconGameRanking.png" alt="iconGameRanking.png"> Classement</a></li>
                        </ul>
                    </nav>

                    <article id="gameRules">
                        <p>{{ $game->description ?? '[WIP description]' }}</p>
                        <hr>
                        <table class="gameCommands noBorder noBackground">
                            <thead>
                                <tr>
                                    <th style="width: 70px;" scope="col">Commande</th>
                                    <th scope="col">Fonction</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td scope="row"><img src="/gfx/gameCommandLeftClic.png" title="Clic gauche" alt="Clic gauche"></td>
                                    <td>Sauter</td>
                                </tr>
                            </tbody>
                        </table>
                    </article>

                    <article id="gameStars" class="hidden">
                        <table class="noBorder whiteFirst">
                            <thead>
                                <tr class="noBackground">
                                    <th scope="col">Record période</th>
                                    <th scope="col">Mon record</th>
                                    <th scope="col">Record du monde</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td scope="row">{!! typoFromImg($personalBestForPeriod,2) !!}</th>
                                    <td>123456</th>
                                    <td>123456</th>
                                </tr>
                            </tbody>
                        </table>

                        <h3>Objectifs</h3>
                        <table class="gameGoals noBorder">
                            <thead>
                                <tr class="noBackground">
                                    <th scope="col">Paliers</th>
                                    <th scope="col">Valeur</th>
                                </tr>
                            </thead>
                            <tbody class="twoColoured">
                                <tr>
                                    <td scope="row">Img</th>
                                    <td>123456</th>
                                </tr>
                                <tr>
                                    <td scope="row">Img</th>
                                    <td>123456</th>
                                </tr>
                                <tr>
                                    <td scope="row">Img</th>
                                    <td>123456</th>
                                </tr>
                            </tbody>
                        </table>
                    </article>

                    <article id="gameRanking" class="hidden">
                        <table style="width: 100%;">
                            <tr>
                                <th>Position</th>
                                <th>Joueur</th>
                                <th>Score</th>
                                <th>Temps</th>
                            </tr>
                            @foreach ($scores as $index => $score)
                            <tr>
                                <td>{{ $index + 1 }}</td>
                                <td>{{ $score->user->display_name }}</td>
                                <td>{{ formatScore($score->score) }}</td>
                                <td>
                                    @if ($score->has_replay)
                                    <a href="{{ route('runs.show', $score->id) }}">
                                        {{ formatTime($score->play_time_seconds) }}
                                    </a>
                                    @else
                                    {{ formatTime($score->play_time_seconds) }}
                                    @endif
                                </td>
                            </tr>
                            @endforeach
                        </table>
                    </article>
                </div>
            </div>
            <p id="gameZoomClose"><a href="#" title="Désactiver le zoom" onclick="ZoomManager()">Désactiver le zoom <span>❌</span></p>
        </div>
    </div>

    <!-- Definition of the sections to show or hide when clicking on the button. See javascript buttonSwitch class. -->
    <script>
    const check1 = new SwitchTab(
        ['gameNavRules', 'gameNavStars', 'gameNavRanking'],
        ['gameRules', 'gameStars', 'gameRanking']
    );
    </script>

    <script src="/gamesdata/godot.js"></script>
    <script>
        const GODOT_CONFIG = {
            "args": [
                '--server_url={{ config('app.url') }}',
            ],
            "canvasResizePolicy": 0,
            "ensureCrossOriginIsolationHeaders": true,
            "executable": "/gamesdata/godot",
            "mainPack": "{{ $game->gamedata['file'] }}",
            "experimentalVK": false,
            "fileSizes": {
                "{{ $game->gamedata['file'] }}": {{ $game->gamedata['size'] }},
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
