@extends('layouts.default')

@section('title', 'KadoKadeo - Jeux')

@section('page')
    <div class="relative">
        <div class="absolute -top-8">
            <ul class="flex items-center space-x-4">
                <li class="w-32 text-center {{ !request()->category ? 'bg-slate-100' : '' }}">
                    <a href="{{ route('games.index') }}">Tous les jeux</a>
                </li>
                @foreach ($categories as $category)
                    <li class="w-32 text-center {{ request()->category == $category->name ? 'bg-slate-100' : '' }}">
                        <a href="{{ route('games.index', ['category' => $category->name]) }}">{{ $category->name }}</a>
                    </li>
                @endforeach
            </ul>
        </div>
        <div class="grid grid-cols-3 gap-4">
            @foreach ($games as $game)
                <div class="">
                    <h3>{{ $game->name }}</h3>
                    <a href="{{ route('games.show', ['game' => $game->id]) }}" class="btn">Jouer</a>
                </div>
            @endforeach
        </div>
    </div>
@endsection
