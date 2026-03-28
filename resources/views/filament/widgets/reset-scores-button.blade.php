<x-filament-widgets::widget>
    <x-filament::section>
            <x-filament::button
                color="danger"
                icon="heroicon-o-trash"
                wire:click="resetScores"
                wire:confirm="This deletes all runs and scores. Continue?"
                wire:loading.attr="disabled"
                wire:target="resetScores"
            >
                Reset scores / runs
            </x-filament::button>
    </x-filament::section>
</x-filament-widgets::widget>
