<script setup>
const leagueStore = useLeagueStore()
const stars = [
  { name: 'étoile verte', image: '/gfx/starGreenMedium.gif' },
  { name: 'étoile orange', image: '/gfx/starOrangeMedium.gif' },
  { name: 'étoile rouge', image: '/gfx/starRedMedium.gif' },
]

// the clans: texts of the help of KadoKado (2007), of its FAQ "Le tournoi des clans" and of the news of the missions (2010)
const clanBonuses = [
  { name: 'Mission suivante', icon: '/gfx/clan/opt/optSkipMission.gif', description: 'Annule la mission en cours et génère une nouvelle mission. Si la mission est difficile et que le clan n\'arrive pas à la finir, vous pouvez utiliser cette option pour passer à la mission suivante sans perdre de points. Cependant les étapes que vous avez réussies dans cette mission ne vous rapporteront pas de point non plus.' },
  { name: 'Double points', icon: '/gfx/clan/opt/optDoublePoints.gif', description: 'La prochaine mission rapportera deux fois plus de points à votre clan si vous la terminez.' },
  { name: 'Jeu caca', icon: '/gfx/clan/opt/optBlacklistGame.gif', description: 'Sélectionne un jeu qui ne sera jamais présent dans les futures missions de la période. L\'option est prise en compte à partir de la mission suivante seulement.' },
  { name: 'Jeu cool', icon: '/gfx/clan/opt/optSelectGame.gif', description: 'Sélectionne un jeu qui sera obligatoirement présent dans toutes les futures missions de la période.' },
  { name: 'Plus de temps', icon: '/gfx/clan/opt/optMoreTime.gif', description: 'Augmente la durée de la mission en cours pour pouvoir la finir : 6 heures sont ajoutées.' },
  { name: 'Passe étape', icon: '/gfx/clan/opt/optSkipStep.gif', description: 'Supprime une étape au choix de votre mission.' },
  { name: 'Double attaque', icon: '/gfx/clan/opt/optDoubleAttack.gif', description: 'Permet à un joueur de lancer une seconde attaque en parallèle.' },
  { name: 'Défense 120%', icon: '/gfx/clan/opt/optSuperDefense.gif', description: 'Augmente un score de défense à 120%. Par exemple, un score de 10.000 points sur une défense comptera pour 12.000 points. Le score réalisé avec ce bonus ne compte que pour la défense, pas pour les records ou le classement du joueur.' },
]
// kado.clans.rewards (config/kado.php)
const clanRewards = [
  { ranks: '1er', points: 150000 },
  { ranks: '2e', points: 100000 },
  { ranks: '3e à 5e', points: 75000 },
  { ranks: '6e à 10e', points: 25000 },
  { ranks: '11e à 25e', points: 12500 },
  { ranks: '26e à 50e', points: 7500 },
  { ranks: '51e à 100e', points: 5000 },
  { ranks: '101e à 200e', points: 2500 },
  { ranks: '201e à 500e', points: 1250 },
]

// const colors = {
//   'kado-orange': 'bg-kado-orange',
//   'kado-yellow': 'bg-kado-yellow',
//   'kado-cream': 'bg-kado-cream',
//   'kado-cyan-50': 'bg-kado-cyan-50',
//   'kado-cyan-100': 'bg-kado-cyan-100',
//   'kado-cyan-200': 'bg-kado-cyan-200',
//   'kado-cyan-300': 'bg-kado-cyan-300',
//   'kado-cyan-400': 'bg-kado-cyan-400',
//   'kado-cyan-500': 'bg-kado-cyan-500',
//   'kado-cyan-muted': 'bg-kado-cyan-muted',
//   'kado-cyan-600': 'bg-kado-cyan-600',
//   'kado-cyan-650': 'bg-kado-cyan-650',
//   'kado-cyan-700': 'bg-kado-cyan-700',
//   'kado-cyan-750': 'bg-kado-cyan-750',
//   'kado-cyan-800': 'bg-kado-cyan-800',
//   'kado-cyan-900': 'bg-kado-cyan-900',
//   'kado-cyan-950': 'bg-kado-cyan-950',
//   'kado-slate-400': 'bg-kado-slate-400',
//   'kado-green-50': 'bg-kado-green-50',
//   'kado-green-100': 'bg-kado-green-100',
//   'kado-green-500': 'bg-kado-green-500',
//   'kado-green-600': 'bg-kado-green-600',
//   'kado-play-400': 'bg-kado-play-400',
//   'kado-play-500': 'bg-kado-play-500',
//   'kado-play-700': 'bg-kado-play-700',
//   'kado-play-900': 'bg-kado-play-900',
//   'kado-pink-50': 'bg-kado-pink-50',
//   'kado-pink-400': 'bg-kado-pink-400',
//   'kado-pink-600': 'bg-kado-pink-600',
//   'kado-pink-900': 'bg-kado-pink-900',
// }
</script>

<template>
  <div class="p-2">
    <h1 class="text-center">Aide</h1>

    <h3>Les niveaux</h3>
    <p>A chaque passage de niveau, vous obtenez des points Kado supplémentaires, qui augmenteront de plus en plus au fur et à mesure que votre niveau progressera :</p>
    <table>
      <thead>
        <tr>
          <th>Niveau</th>
          <th>Nombre de joueurs qualifiés</th>
          <th>Etoile minimum requise</th>
          <th>Points Kado</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="league in leagueStore.leagues" :key="league.level">
          <td class="!text-left">
            <div class="flex items-center space-x-2">
              <img :src="`/gfx/leagues/${league.level}.png`" :alt="league.name">
              <div>{{ league.name }}</div>
            </div>
          </td>
          <td class="!text-left">
            <span v-if="league.promotion_ratio">
              {{ league.promotion_ratio }}% des joueurs jusqu'à {{ league.promotion_max_slots }} max
            </span>
            <span v-else>
              {{ league.promotion_max_slots }}
            </span>
          </td>
          <td>
            <img v-if="league.promotion_min_stars !== null" :src="stars[league.promotion_min_stars].image" :alt="stars[league.promotion_min_stars].name">
          </td>
          <td>
            <div class="flex space-x-1 items-center justify-end">
              <div>{{ formatScore(league.promotion_reward) }}</div>
              <img src="/gfx/skpoint.gif" alt="Kado" class="w-5 h-5">
            </div>
          </td>
        </tr>
      </tbody>
    </table>

    <p>Il n'y a pas de nombre de joueur minimum pour le passage d'un niveau à un autre. Par contre, il vous faudra avoir des étoiles minimum pour pouvoir être promu selon le niveau où vous vous trouvez.</p>
    <p>Par exemple, pour le niveau Bronze, vous devrez avoir au moins l'étoile orange pour vous qualifier.</p>

    <p>Si un joueur est seul dans son niveau, il ne pourra monter que s'il y a des joueurs dans le niveau suivant. Sinon, il faudra au moins 2 joueurs pour prétendre à monter.</p>

    <h3 id="clans">Les clans</h3>
    <p>
      Un Clan est un groupe de joueurs (maximum 50) qui se rassemblent pour combattre ensemble contre d'autres clans.
      Vous pouvez soit rejoindre un Clan existant en envoyant votre candidature depuis sa page, soit créer votre propre
      Clan à partir de la rubrique <RouterLink :to="{ name: 'clans.index' }">Clans</RouterLink>.
    </p>
    <p>
      Chaque Clan a deux scores et deux positions : une dans le classement des attaques et une dans le classement des
      missions. Vous pouvez participer à l'un ou l'autre de ces classements, ou aux deux !
    </p>

    <h3>Les attaques</h3>
    <p>
      <img src="/assets/img/gfx/icons/atk.gif" alt="Attaque" />
      Pour gagner des points, un Clan doit effectuer une attaque sur un autre Clan. Pour cela, une fois que vous faites
      partie d'un Clan, allez sur la page d'un Clan adverse et cliquez sur « Attaquer ce clan ». Choisissez un jeu et
      effectuez une partie.
    </p>
    <p>
      Votre score à ce jeu deviendra une attaque contre le Clan adverse. Pour repousser cette attaque, ce Clan devra
      défendre, et donc effectuer un score supérieur au vôtre. Une attaque repoussée est annulée.
    </p>
    <p>
      Si au bout de 12 heures l'attaque n'a pas été repoussée, votre Clan remporte une victoire qui lui rapporte jusqu'à
      10 points ! Dans le même temps, le Clan adverse perd le même nombre de points (le score d'un Clan ne descend jamais
      en dessous de zéro). Attaquez des clans ayant un score proche du vôtre pour gagner le plus de points : les clans
      trop éloignés sont protégés de vos attaques.
    </p>
    <p>
      Vous ne pouvez avoir qu'une attaque en cours à la fois. Vous pouvez annuler votre attaque depuis la page Statut de
      votre clan.
    </p>

    <h3>Les défenses</h3>
    <p>
      <img src="/assets/img/gfx/icons/def.gif" alt="Défense" />
      Les attaques lancées par votre Clan et celles menées contre lui sont indiquées dans l'onglet Statut de votre clan.
      Pour défendre, cliquez sur « Défendre » à côté d'une attaque et battez son score sur le même jeu.
    </p>
    <p>
      Sachez enfin que tant que vous avez une attaque en cours vous ne pouvez pas défendre ! Il faudra donc savoir
      coordonner les différents membres du Clan entre attaquants et défenseurs. Pour progresser dans le classement des
      Clans, il faudra à la fois remporter des attaques mais aussi défendre efficacement contre les attaques des clans
      ennemis.
    </p>

    <h3>Les missions</h3>
    <p>
      Pendant toute la période, votre Clan reçoit des missions : une mission comporte plusieurs étapes, chacune étant un
      score à atteindre sur un jeu. Votre Clan dispose de 24 heures pour réussir toutes les étapes. C'est un vrai travail
      de groupe : chaque membre peut réussir les étapes sur les jeux où il est le meilleur !
    </p>
    <p>
      Chaque étape réussie rapporte un point à votre Clan. Si vous réussissez toutes les étapes de la mission dans le temps
      imparti, vos points sont doublés. En revanche, si vous ne réussissez pas toutes les étapes à temps, vous perdez les
      points correspondants.
    </p>
    <p>
      Une fois une mission terminée, une autre vous est proposée. Chaque mission est plus difficile que la précédente,
      avec des scores plus élevés et un plus grand nombre d'étapes. Combien de missions votre Clan réussira-t-il ?
    </p>

    <h3>Les options</h3>
    <p>
      Les options sont des bonus que votre Clan peut obtenir lorsque vous réussissez certaines missions. Elles sont
      attribuées aléatoirement : plus vous effectuez de missions, plus vous avez de chances d'en remporter. Vous pouvez
      avoir plusieurs fois la même option en stock, mais les options sont remises à zéro à la fin de la période.
    </p>
    <p>
      C'est le chef de clan qui décide de l'utilisation des options. Les options Double attaque et Défense 120% peuvent
      être données à des joueurs du clan pour qu'ils les utilisent eux-mêmes. Vous pouvez voir les options disponibles en
      bas de la page Mission de votre clan.
    </p>
    <table>
      <tbody>
        <tr v-for="bonus in clanBonuses" :key="bonus.name">
          <td><img :src="bonus.icon" :alt="bonus.name" class="max-w-none"></td>
          <td class="!text-left">
            <strong>{{ bonus.name }}</strong> : {{ bonus.description }}
          </td>
        </tr>
      </tbody>
    </table>

    <h3>Le classement des clans</h3>
    <p>
      Le tournoi des clans dure une période. A la fin de chaque période, les classements sont remis à zéro et les clans les
      mieux classés remportent des points Kado, dans chacun des deux classements. Les points sont répartis de manière égale
      entre tous les membres du clan. Alors n'oubliez pas : « l'union fait la force » !
    </p>
    <table>
      <thead>
        <tr>
          <th>Classement</th>
          <th>Points Kado</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="reward in clanRewards" :key="reward.ranks">
          <td class="!text-left">{{ reward.ranks }}</td>
          <td>
            <div class="flex space-x-1 items-center justify-end">
              <div>{{ formatScore(reward.points) }}</div>
              <img src="/gfx/skpoint.gif" alt="Kado" class="w-5 h-5">
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    <p>
      Les attaques et les défenses sont des parties comme les autres : elles comptent dans vos parties du jour, vos
      étoiles et vos classements. Il s'agit donc d'un mode de jeu vous permettant de jouer vos parties tout en vous amusant
      encore davantage !
    </p>

    <!-- <div class="grid grid-cols-2">
      <div v-for="(colorClass, colorName) in colors" :key="colorName" class="h-10 flex items-center relative">
        <div :class="['h-10 w-full', colorClass]"></div>
        <div class="text-shadow-lg text-shadow-white text-black absolute place-self-center left-1/2 -translate-x-1/2">{{ colorName }}</div>
      </div>
    </div> -->
  </div>
</template>
