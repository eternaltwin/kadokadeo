@extends('layouts.default')

@section('title', 'KadoKadeo - Jeux')

@section('page')
    <h1 style="text-align:center">Replay</h1>

    <h2 style="margin: 0">Vous regardez {{ $run->user->display_name }}</h2>
    <h2 style="margin: 0">Score: {{ $run->score }}</h2>
    <h2 style="margin: 0">Jeu: {{ $run->game->name }}</h2>

    <div id="status">
        <progress id="status-progress"></progress>
        <div id="status-notice"></div>
    </div>

    <canvas id="canvas" style="width: 600px; height: 640px; margin: 2rem auto">
        Your browser does not support the canvas tag.
    </canvas>

    <script src="/gamesdata/godot.js"></script>
    <script>
        const GODOT_CONFIG = {
            "args": [
                '--replay={{ $run->replay }}',
                '--seed={{ $run->seed }}',
                '--contract_score={{ $run->contract_score }}',
                '--contract_points={{ $run->contract_points }}',
            ],
            "canvasResizePolicy": 1,
            "ensureCrossOriginIsolationHeaders": true,
            "executable": "/gamesdata/godot",
            "mainPack": "{{ $run->game->gamedata['file'] }}",
            "experimentalVK": false,
            "fileSizes": {
                "{{ $run->game->gamedata['file'] }}": {{ $run->game->gamedata['size'] }},
                "/gamesdata/godot.wasm": 31000000
            },
            "focusCanvas": true,
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
