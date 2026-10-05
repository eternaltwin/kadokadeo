<x-filament-widgets::widget>
    <x-filament::section>
        <x-filament::button color="danger" icon="heroicon-o-trash" wire:click="resetScores" wire:confirm="Toutes les parties et tous les scores seront supprimés. Continuer ?" wire:loading.attr="disabled"
            wire:target="resetScores">
            Réinitialiser scores / parties
        </x-filament::button>
        <x-filament::button color="info" icon="heroicon-o-plus" wire:click="prepareNewPeriod" wire:loading.attr="disabled" wire:target="prepareNewPeriod">
            Préparer une nouvelle période
        </x-filament::button>
        <x-filament::button color="info" icon="heroicon-o-arrow-path" wire:click="migrate" wire:loading.attr="disabled" wire:target="migrate">
            Migrate
        </x-filament::button>
        <x-filament::button color="info" icon="heroicon-o-arrow-uturn-left" wire:click="migrateRollback" wire:loading.attr="disabled" wire:target="migrateRollback">
            Migrate:rollback
        </x-filament::button>
        <x-filament::button color="danger" icon="heroicon-o-trash" wire:click="deleteAchievements" wire:loading.attr="disabled" wire:target="deleteAchievements"
            wire:confirm="This deletes all achievements. Continue?">
            Delete all achievements / re-seed
        </x-filament::button>
    </x-filament::section>
</x-filament-widgets::widget>
