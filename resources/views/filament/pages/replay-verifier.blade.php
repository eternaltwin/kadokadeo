<x-filament-panels::page>
    {{ $this->table }}

    @php
        $statuses = array_filter(\App\Enums\RunVerification::cases(), fn ($s) => $s !== \App\Enums\RunVerification::PENDING);
        $perGame = $this->perGame();
    @endphp
    <x-filament::section heading="Par jeu ({{ \App\Models\ReplayVerification::KEEP_VERIFIED_DAYS }} derniers jours)" collapsible>
        @if ($perGame === [])
            <p class="text-sm">Aucune vérification.</p>
        @else
            <div style="overflow-x: auto;">
                <table class="text-sm" style="width: 100%; border-collapse: collapse;">
                    <thead>
                        <tr>
                            <th style="text-align: left; padding: 0.25rem 0.75rem 0.5rem 0;">Jeu</th>
                            @foreach ($statuses as $status)
                                <th style="text-align: right; padding: 0.25rem 0 0.5rem 0.75rem;">{{ $status->getLabel() }}</th>
                            @endforeach
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($perGame as $row)
                            <tr style="border-top: 1px solid rgb(128 128 128 / 0.2);">
                                <td style="padding: 0.375rem 0.75rem 0.375rem 0;">{{ $row['game'] }}</td>
                                @foreach ($statuses as $status)
                                    @php($n = $row['counts'][$status->value] ?? 0)
                                    <td style="text-align: right; padding: 0.375rem 0 0.375rem 0.75rem;">
                                        @if ($n > 0 && $status !== \App\Enums\RunVerification::VERIFIED)
                                            <x-filament::badge :color="$status->getColor()" style="display: inline-flex;">{{ $n }}</x-filament::badge>
                                        @else
                                            {{ $n ?: '—' }}
                                        @endif
                                    </td>
                                @endforeach
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </x-filament::section>

    <x-filament::section heading="Configuration" collapsible collapsed>
        <dl style="display: grid; grid-template-columns: max-content 1fr; gap: 0.5rem 1.5rem;">
            @foreach ($this->settings() as $label => $value)
                <dt class="text-sm font-medium">{{ $label }}</dt>
                <dd class="text-sm" style="word-break: break-all;">{{ $value }}</dd>
            @endforeach
        </dl>
    </x-filament::section>

    <x-filament::section heading="Diagnostic" description="Un replay complet se teste avec l’action « Revérifier » d’une partie.">
        @if ($report === null)
            <p class="text-sm">Lancez le diagnostic pour savoir si le vérificateur peut tourner sur ce serveur.</p>
        @elseif (isset($report['error']))
            <x-filament::badge color="danger">Échec</x-filament::badge>
            <p class="text-sm" style="margin-top: 0.5rem; word-break: break-all;">{{ $report['error'] }}</p>
        @else
            <dl style="display: grid; grid-template-columns: max-content max-content 1fr; gap: 0.75rem 1rem; align-items: start;">
                @foreach ($this->checks() as $check)
                    <dd>
                        @if ($check['ok'] === null)
                            <x-filament::badge color="gray">Info</x-filament::badge>
                        @elseif ($check['ok'])
                            <x-filament::badge color="success">OK</x-filament::badge>
                        @else
                            <x-filament::badge color="danger">Problème</x-filament::badge>
                        @endif
                    </dd>
                    <dt class="text-sm font-medium">{{ $check['label'] }}</dt>
                    <dd class="text-sm" style="word-break: break-all;">
                        {{ $check['value'] }}
                        @if ($check['hint'])
                            <div class="text-gray-500" style="margin-top: 0.25rem;">{{ $check['hint'] }}</div>
                        @endif
                    </dd>
                @endforeach
            </dl>
        @endif
    </x-filament::section>
</x-filament-panels::page>
