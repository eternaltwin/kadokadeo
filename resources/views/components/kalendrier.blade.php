<nav id="kalendrier">
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
