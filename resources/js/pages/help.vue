<script setup>
// the help as on KadoKado (HelpUI of kk.js, 2008): a box of 400px showing one section at a time with its art on the
// left, the table of content in roman numbers, a "Suivant" button, and the sections sliding from one to the next
const leagueStore = useLeagueStore()
const route = useRoute()
const router = useRouter()

const stars = [
  { name: 'étoile verte', image: '/gfx/starGreenMedium.gif' },
  { name: 'étoile orange', image: '/gfx/starOrangeMedium.gif' },
  { name: 'étoile rouge', image: '/gfx/starRedMedium.gif' },
]

const art = (name) => `/assets/img/gfx/art/${name}.jpg`
// level 2: a part of the table of content, level 3: one of its sections
const sections = [
  { id: 'bienvenue', title: 'Bienvenue', level: 2, art: art('general') },
  { id: 'periodes', title: 'Les périodes', level: 2, art: art('periode') },
  { id: 'etoiles', title: 'Les étoiles', level: 2, art: art('star') },
  { id: 'niveaux', title: 'Les niveaux', level: 2, art: art('scoring') },
  { id: 'clans', title: 'Les clans', level: 2, art: art('clan') },
  { id: 'attaques', title: 'Les attaques', level: 3, art: art('clan') },
  { id: 'defenses', title: 'Les défenses', level: 3, art: art('clan') },
  { id: 'missions', title: 'Les missions', level: 3, art: art('clan') },
  { id: 'options', title: 'Les options', level: 3, art: art('clan') },
  { id: 'classement', title: 'Le classement des clans', level: 3, art: art('clan') },
  { id: 'compte', title: 'Mon compte', level: 2, art: art('pks') },
  { id: 'questions', title: 'Questions', level: 2, art: art('gem') },
]
// the table of content: the parts and their sections
const toc = sections.reduce((parts, section, index) => {
  if (section.level === 2) {
    parts.push({ ...section, index, children: [] })
  } else {
    parts[parts.length - 1].children.push({ ...section, index })
  }
  return parts
}, [])

const indexOf = (hash) => Math.max(0, sections.findIndex((s) => `#${s.id}` === hash))
const current = ref(indexOf(route.hash))
watch(() => route.hash, (hash) => {
  current.value = indexOf(hash)
})
// "Les attaques" -> "Attaques"
const shortTitle = (section) => {
  const title = section.title.replace(/^(Les?|La) /, '')
  return title.charAt(0).toUpperCase() + title.slice(1)
}
// the part of a section, and of the section shown
const partOf = (index) => [...toc].reverse().find((part) => part.index <= index)
const openPart = computed(() => partOf(current.value) ?? null)
const go = (index) => {
  router.replace({ hash: `#${sections[index].id}` })
}

const clanBonuses = [
  { name: 'Mission suivante', icon: '/gfx/clan/opt/optSkipMission.gif', description: 'Annule la mission en cours et en génère une nouvelle, sans perdre de points. Les étapes réussies de la mission annulée ne rapportent pas de point non plus.' },
  { name: 'Double points', icon: '/gfx/clan/opt/optDoublePoints.gif', description: 'La prochaine mission rapportera deux fois plus de points si vous la terminez.' },
  { name: 'Jeu caca', icon: '/gfx/clan/opt/optBlacklistGame.gif', description: 'Un jeu qui ne sera jamais présent dans les futures missions de la période.' },
  { name: 'Jeu cool', icon: '/gfx/clan/opt/optSelectGame.gif', description: 'Un jeu qui sera obligatoirement présent dans toutes les futures missions de la période.' },
  { name: 'Plus de temps', icon: '/gfx/clan/opt/optMoreTime.gif', description: 'Ajoute 6 heures à la mission en cours.' },
  { name: 'Passe étape', icon: '/gfx/clan/opt/optSkipStep.gif', description: 'Supprime une étape au choix de la mission.' },
  { name: 'Double attaque', icon: '/gfx/clan/opt/optDoubleAttack.gif', description: 'Permet à un joueur de lancer une seconde attaque en parallèle.' },
  { name: 'Défense 120%', icon: '/gfx/clan/opt/optSuperDefense.gif', description: 'Un score de défense compte pour 120% (seulement pour la défense, pas pour les records).' },
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
</script>

<template>
  <div class="p-2">
    <h1 class="mt-0 text-center">Aide</h1>

    <!-- the table of content: the parts as the tabs of the site, the sections of the open part below -->
    <nav id="toc" class="mb-3">
      <ul class="flex flex-wrap justify-center gap-1">
        <li v-for="(part, i) in toc" :key="part.id">
          <button type="button"
                  class="tocButton"
                  :class="{ current: openPart?.id === part.id }"
                  :title="`${romans[i]}. ${part.title}`"
                  @click="go(part.index)">
            {{ part.title }}
          </button>
        </li>
      </ul>
    </nav>

    <!-- one section at a time: they slide in the box -->
    <div id="helpBoxCont">
      <div class="helpSlides" :style="{ transform: `translateY(-${current * 400}px)` }">
        <section v-for="(section, index) in sections"
                 :id="`help_${section.id}`"
                 :key="section.id"
                 class="helpSection"
                 :aria-hidden="index !== current">
          <img :src="section.art" alt="" class="helpArt" />
          <div class="helpText">
            <h3>{{ section.title }}</h3>
            <!-- the sections of the part (the clans), as small links -->
            <nav v-if="partOf(index).children.length" class="helpSubToc">
              <template v-for="(s, i) in [partOf(index), ...partOf(index).children]" :key="s.id">
                <span v-if="i" class="mx-1 text-kado-cyan-800">·</span>
                <strong v-if="s.index === index">{{ i ? shortTitle(s) : 'Présentation' }}</strong>
                <a v-else href="#" @click.prevent="go(s.index)">{{ i ? shortTitle(s) : 'Présentation' }}</a>
              </template>
            </nav>

            <template v-if="section.id === 'bienvenue'">
              <p>Bienvenue sur <strong>KadoKadéo</strong>, le retour de KadoKado par le projet Eternaltwin ! Retrouvez les jeux de Motion-Twin, battez vos records et grimpez dans les niveaux de chaque jeu.</p>
              <p>Chaque jour, vous disposez d'un nombre de parties à jouer sur les jeux que vous préférez. Le jeu du jour vous propose en plus un contrat : un score à battre pour remporter des <strong>points Kado</strong> <img src="/gfx/skpoint.gif" alt="Kado" class="inline size-4" />.</p>
              <p>Rejoignez un clan pour jouer en équipe, et utilisez ce menu ou le bouton « Suivant » pour découvrir le reste du site !</p>
            </template>

            <template v-else-if="section.id === 'periodes'">
              <p>Une période KadoKadéo se déroule sur deux semaines, soit <strong>14 jours</strong>. Le Kalendrier affiché en haut à droite du site indique la période actuelle ainsi que le jour actuel.</p>
              <p>Quand une période se termine, les classements sont remis à zéro : les meilleurs joueurs de chaque niveau montent au niveau supérieur et remportent des points Kado, et le tournoi des clans recommence.</p>
            </template>

            <template v-else-if="section.id === 'etoiles'">
              <p>Si vous faites un très bon score à un jeu, vous remportez une étoile. Il y a trois niveaux d'étoile pour chaque jeu :</p>
              <ul>
                <li v-for="star in stars" :key="star.name"><img :src="star.image" :alt="star.name" class="inline size-5" /> l'{{ star.name }}</li>
              </ul>
              <p>L'étoile que vous possédez est indiquée sur la boîte de chaque jeu. Les étoiles comptent aussi pour passer au niveau supérieur : il faudra une étoile minimum selon le niveau où vous vous trouvez.</p>
            </template>

            <template v-else-if="section.id === 'niveaux'">
              <p>A chaque passage de niveau, vous obtenez des points Kado supplémentaires, qui augmentent au fur et à mesure que votre niveau progresse :</p>
              <table class="w-full">
                <thead>
                  <tr>
                    <th>Niveau</th>
                    <th>Qualifiés</th>
                    <th>Etoile</th>
                    <th>Points Kado</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="league in leagueStore.leagues" :key="league.level">
                    <td class="!text-left">
                      <div class="flex items-center gap-1">
                        <img :src="`/gfx/leagues/${league.level}.png`" :alt="league.name" class="h-5">
                        <div>{{ league.name }}</div>
                      </div>
                    </td>
                    <td class="!text-left">
                      <span v-if="league.promotion_ratio">{{ league.promotion_ratio }}% (max {{ league.promotion_max_slots }})</span>
                      <span v-else>{{ league.promotion_max_slots }}</span>
                    </td>
                    <td>
                      <img v-if="league.promotion_min_stars !== null"
                           :src="stars[league.promotion_min_stars].image"
                           :alt="stars[league.promotion_min_stars].name"
                           class="inline h-5">
                    </td>
                    <td class="!text-right whitespace-nowrap">
                      {{ formatScore(league.promotion_reward) }} <img src="/gfx/skpoint.gif" alt="Kado" class="inline size-4">
                    </td>
                  </tr>
                </tbody>
              </table>
              <p>Si un joueur est seul dans son niveau, il ne pourra monter que s'il y a des joueurs dans le niveau suivant. Sinon, il faudra au moins 2 joueurs pour prétendre à monter.</p>
            </template>

            <template v-else-if="section.id === 'clans'">
              <p>Un Clan est un groupe de joueurs (maximum 50) qui se rassemblent pour combattre ensemble contre d'autres clans.</p>
              <p>Vous pouvez soit rejoindre un Clan existant en envoyant votre candidature depuis sa page, soit créer votre propre Clan à partir de la rubrique <RouterLink :to="{ name: 'clans.index' }">Clans</RouterLink>.</p>
              <p>Chaque Clan a deux scores et deux positions : une dans le classement des attaques et une dans le classement des missions. Vous pouvez participer à l'un ou l'autre de ces classements, ou aux deux !</p>
            </template>

            <template v-else-if="section.id === 'attaques'">
              <p><img src="/assets/img/gfx/icons/atk.gif" alt="Attaque" class="inline" /> Pour gagner des points, un Clan doit attaquer un autre Clan : allez sur la page d'un Clan adverse, cliquez sur « Attaquer ce clan », choisissez un jeu et effectuez une partie.</p>
              <p>Votre score devient une attaque. Pour la repousser, le Clan adverse devra faire un score supérieur au vôtre. Une attaque repoussée est annulée.</p>
              <p>Si au bout de <strong>12 heures</strong> l'attaque n'a pas été repoussée, votre Clan remporte jusqu'à <strong>10 points</strong> et le Clan adverse perd autant (jamais en dessous de zéro). Attaquez des clans au score proche du vôtre : les autres sont protégés de vos attaques.</p>
            </template>

            <template v-else-if="section.id === 'defenses'">
              <p><img src="/assets/img/gfx/icons/def.gif" alt="Défense" class="inline" /> Les attaques lancées par votre Clan et celles menées contre lui sont indiquées dans l'onglet Statut de votre clan. Cliquez sur « Défendre » et battez le score de l'attaque sur le même jeu.</p>
              <p>Sachez que tant que vous avez une attaque en cours, vous ne pouvez pas défendre ! Il faudra donc coordonner les membres du Clan entre attaquants et défenseurs.</p>
              <p>Pour progresser dans le classement, il faudra à la fois remporter des attaques et défendre efficacement contre les clans ennemis.</p>
            </template>

            <template v-else-if="section.id === 'missions'">
              <p>Votre Clan reçoit des missions : plusieurs étapes, chacune étant un score à atteindre sur un jeu. Vous avez <strong>24 heures</strong> pour toutes les réussir. Chacun peut faire les étapes sur les jeux où il est le meilleur !</p>
              <p>Chaque étape réussie rapporte un point. Si toutes les étapes sont réussies à temps, vos points sont <strong>doublés</strong>. Sinon, vous perdez les points de la mission.</p>
              <p>Chaque mission est plus difficile que la précédente, avec plus d'étapes. Combien de missions votre Clan réussira-t-il ?</p>
            </template>

            <template v-else-if="section.id === 'options'">
              <p>En réussissant des missions, votre Clan peut gagner des options. C'est le chef de clan qui les utilise, il peut aussi donner Double attaque et Défense 120% à un joueur. Elles sont remises à zéro à la fin de la période.</p>
              <table class="w-full">
                <tbody>
                  <tr v-for="bonus in clanBonuses" :key="bonus.name">
                    <td class="w-10"><img :src="bonus.icon" :alt="bonus.name" class="size-9 max-w-none"></td>
                    <td class="!text-left text-xs"><strong>{{ bonus.name }}</strong> : {{ bonus.description }}</td>
                  </tr>
                </tbody>
              </table>
            </template>

            <template v-else-if="section.id === 'classement'">
              <p>Le tournoi des clans dure une période. A la fin, les clans les mieux classés de chaque classement remportent des points Kado, répartis à parts égales entre leurs membres. « L'union fait la force » !</p>
              <table class="w-full">
                <tbody>
                  <tr v-for="reward in clanRewards" :key="reward.ranks">
                    <td class="!text-left">{{ reward.ranks }}</td>
                    <td class="!text-right">{{ formatScore(reward.points) }} <img src="/gfx/skpoint.gif" alt="Kado" class="inline size-4"></td>
                  </tr>
                </tbody>
              </table>
            </template>

            <template v-else-if="section.id === 'compte'">
              <p>Dans <RouterLink :to="{ name: 'account' }">Mon compte</RouterLink>, vous pouvez changer l'apparence du site.</p>
              <p>Le thème KadoKado est offert à tous. Le thème <strong>Karbon</strong> s'achète une seule fois avec vos points Kado : vous pourrez ensuite passer d'un thème à l'autre quand vous le voulez.</p>
            </template>

            <template v-else-if="section.id === 'questions'">
              <p>Vous avez d'autres questions ? Les joueurs de KadoKadéo et l'équipe Eternaltwin vous répondent sur le <a href="https://discord.gg/ERc3svy" target="_blank">Discord Eternaltwin</a>.</p>
              <p>Bon jeu sur KadoKadéo !</p>
            </template>
          </div>
        </section>
      </div>
    </div>

    <p class="flex justify-between">
      <input v-if="current > 0"
             type="button"
             value="Précédent"
             class="pinkButton w-auto!"
             @click="go(current - 1)" />
      <span v-else></span>
      <input v-if="current < sections.length - 1"
             type="button"
             value="Suivant"
             class="w-auto!"
             @click="go(current + 1)" />
    </p>
  </div>
</template>

<style scoped>
#toc ol {
  list-style-type: upper-roman;
  margin: 0 0 0 30px;
  padding: 0;
}

#toc ol a {
  font-size: 14px;
  font-weight: bold;
}

#toc ol ol {
  list-style-type: none;
  margin-left: 10px;
}

#toc ol ol a {
  font-weight: normal;
}

.helpSubToc {
  margin: 0 0 8px;
  font-size: 12px;
}

.helpSubToc strong {
  color: var(--color-kado-blue);
}

/* the box of 400px: the sections slide in it */
#helpBoxCont {
  overflow: hidden;
  height: 400px;
}

.helpSlides {
  transition: transform 0.6s ease-in-out;
}

.helpSection {
  display: flex;
  gap: 12px;
  height: 400px;
}

.helpArt {
  width: 275px;
  height: 400px;
  flex-shrink: 0;
}

.helpText {
  flex: 1;
  min-width: 0;
  height: 400px;
  overflow-y: auto;
}

.helpText h3 {
  margin: 0 0 6px;
}

.helpText p,
.helpText ul,
.helpText table {
  margin: 4px 0 10px;
  font-size: 13px;
  line-height: 16px;
}

.helpText ul {
  padding-left: 10px;
}

@media (max-width: 640px) {
  .helpArt {
    display: none;
  }
}
</style>
