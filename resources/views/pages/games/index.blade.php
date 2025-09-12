@extends('layouts.default')

@section('title', 'KadoKadeo - Jeux')

@section('page')
    <nav id="tabNav">
        <ul>
            <li{{ !request()->category ? ' id=tabNavActive' : '' }}>
                <a href="{{ route('games.index') }}">Tous les jeux</a>
                </li>
                @foreach ($categories as $category)
                    <li{{ request()->category == $category->name ? ' id=tabNavActive' : '' }}>
                        <a href="{{ route('games.index', ['category' => $category->name]) }}">{{ $category->name }}</a>
                        </li>
                @endforeach
                <li @if (Route::is('games.daily')) id=tabNavActive @endif>
                    <a href="{{ route('games.daily') }}">Jeu du jour</a>
                </li>
        </ul>
    </nav>

    <div id="gamesBoxes">
        @foreach ($games as $game)
            <a class="gameBox" href="{{ route('games.show', ['game' => $game->id]) }}" title="Jouer à {{ $game->name }}">
                <div class="gameBoxBackground"></div>
                <div class="gameBoxImg"><img src="{{ $game->image_path }}" alt="{{ $game->name }}"></div>
                <div class="gameBoxStar"><img src="/gfx/starGreenMedium.gif" alt="green"></div>
                <h3 class="gameBoxTitle">{{ $game->name }}</h3>
            </a>
        @endforeach
    </div>
@endsection
