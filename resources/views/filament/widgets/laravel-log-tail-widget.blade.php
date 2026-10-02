<x-filament-widgets::widget>
    <x-filament::section
        heading="Logs Laravel"
        description="Rafraîchis toutes les 10 secondes (façon tail -f)"
        wire:poll.10s="refreshLogs"
    >
        <div style="margin-bottom: 8px; font-size: 12px; color: #6b7280;">
            Dernier rafraîchissement : {{ $updatedAt }}
        </div>

        @if (!$logFileExists)
            <div style="font-size: 14px; color: #6b7280;">
                Fichier de log introuvable : <code>storage/logs/laravel.log</code>.
            </div>
        @elseif (empty($logLines))
            <div style="font-size: 14px; color: #6b7280;">
                Le fichier de log est vide.
            </div>
        @else
            <pre style="max-height: 32rem; overflow: auto; border-radius: 10px; background: #0b1220; color: #f3f4f6; padding: 12px; font-size: 12px; line-height: 1.5; margin: 0; white-space: pre;">{{ implode(PHP_EOL, $logLines) }}</pre>
        @endif
    </x-filament::section>
</x-filament-widgets::widget>
