{{-- the checks of the anti cheat turned off (App\Filament\AntiCheatNotices), at the top of every page of the admin panel --}}
@if ($notices)
    <x-filament::callout
        color="warning"
        icon="heroicon-o-exclamation-triangle"
        heading="Anti-triche incomplet"
        style="margin-bottom: 1.5rem"
    >
        <x-slot name="description">
            <ul style="list-style: disc; padding-inline-start: 1.25rem">
                @foreach ($notices as $notice)
                    <li>{{ $notice }}</li>
                @endforeach
            </ul>
        </x-slot>
    </x-filament::callout>
@endif
