@php
    $days = app(\App\Services\PeriodService::class)->getDayCount();
@endphp
<nav id="kalendrier">
    <div class="absolute top-10 left-5 w-36 grid grid-cols-7 font-bold text-lg leading-6 text-red-300">
        @for ($i = 0; $i < $days; $i++)
            <div>x</div>
        @endfor
        <div class="text-green-400">X</div>
    </div>
    <ul>
        <li id="kalUser">
            <a href="#" title="Préférences du compte">
                {{ auth()->user()->display_name }}
            </a>
            <form method="post" action="{{ route('logout') }}" style="display: inline">
                @csrf
                (<button title="Déconnexion">x</button>)
            </form>
        </li>
    </ul>
</nav>
