<script setup>
import { t } from '@/i18n'
import { intlLocale } from '@/i18n/locale'

// the help as on KadoKado (HelpUI of kk.js, 2008): a box of 400px showing one section at a time with its art on the
// left, the table of content in roman numbers, a "Suivant" button, and the sections sliding from one to the next
const leagueStore = useLeagueStore()
const clanStore = useClanStore()
const route = useRoute()
const router = useRouter()

const stars = [
  { name: t('help.stars.green'), withArticle: t('help.stars.green_with_article'), image: '/gfx/starGreenMedium.gif' },
  { name: t('help.stars.orange'), withArticle: t('help.stars.orange_with_article'), image: '/gfx/starOrangeMedium.gif' },
  { name: t('help.stars.red'), withArticle: t('help.stars.red_with_article'), image: '/gfx/starRedMedium.gif' },
]

const art = (name) => `/assets/img/gfx/art/${name}.jpg`
// level 2: a part of the table of content, level 3: one of its sections (those of the clans only once they are open)
const sections = [
  { id: 'bienvenue', title: t('help.sections.welcome'), level: 2, art: art('general') },
  { id: 'periodes', title: t('help.sections.periods'), level: 2, art: art('periode') },
  { id: 'jeudujour', title: t('help.sections.daily'), level: 2, art: art('general') },
  { id: 'etoiles', title: t('help.sections.stars'), level: 2, art: art('star') },
  { id: 'niveaux', title: t('help.sections.levels'), level: 2, art: art('scoring') },
  { id: 'clans', title: t('help.sections.clans'), level: 2, art: art('clan'), clan: true },
  { id: 'attaques', title: t('help.sections.attacks'), short: t('help.sections.attacks_short'), level: 3, art: art('clan'), clan: true },
  { id: 'defenses', title: t('help.sections.defenses'), short: t('help.sections.defenses_short'), level: 3, art: art('clan'), clan: true },
  { id: 'roles', title: t('help.sections.roles'), short: t('help.sections.roles_short'), level: 3, art: art('clan'), clan: true },
  { id: 'missions', title: t('help.sections.missions'), short: t('help.sections.missions_short'), level: 3, art: art('clan'), clan: true },
  { id: 'options', title: t('help.sections.options'), short: t('help.sections.options_short'), level: 3, art: art('clan'), clan: true },
  { id: 'classement', title: t('help.sections.clan_ranking'), short: t('help.sections.clan_ranking_short'), level: 3, art: art('clan'), clan: true },
  { id: 'classementv1', title: t('help.sections.v1_ranking'), level: 2, art: art('general') },
  { id: 'compte', title: t('help.sections.account'), level: 2, art: art('pks') },
  { id: 'questions', title: t('help.sections.questions'), level: 2, art: art('gem') },
].filter((section) => clanStore.enabled || !section.clan)

// the kado points of a point of the daily ranking, set in the admin (App\Settings\SiteSettings)
const dailyKadoPerPoint = window.Kado.daily_kado_per_point

const romans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X']

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
// the part of a section, and of the section shown
const partOf = (index) => [...toc].reverse().find((part) => part.index <= index)
const openPart = computed(() => partOf(current.value) ?? null)
const go = (index) => {
  router.replace({ hash: `#${sections[index].id}` })
}

// the rules of the clans set in the admin (App\Settings\ClanSettings)
if (!clanStore.rules) {
  clanStore.reload()
}
const rules = computed(() => clanStore.rules ?? {})
// 1er, 2e / 1st, 2nd, 3rd, 4th: the ordinal categories of the language
const ORDINALS = {
  one: () => t('last_period.ordinal_one'),
  two: () => t('last_period.ordinal_two'),
  few: () => t('last_period.ordinal_few'),
  other: () => t('last_period.ordinal_other'),
}
const rank = (n) => `${n}${(ORDINALS[new Intl.PluralRules(intlLocale(), { type: 'ordinal' }).select(n)] ?? ORDINALS.other)()}`
const ranks = (reward) => (reward.from === reward.to ? rank(reward.from) : t('help.clan_ranking.range', { from: rank(reward.from), to: rank(reward.to) }))
const clanRewards = computed(() => [
  { title: t('help.clan_ranking.war'), rewards: rules.value.rewards?.war ?? [] },
  { title: t('help.clan_ranking.missions'), rewards: rules.value.rewards?.missions ?? [] },
])
// the seats of a role for a clan of n members (App\Services\ClanService::combatSeats): at least one (nothing while
// the rules load)
const seatsFor = (members, share) => (members && share != null ? Math.max(1, Math.floor((members * share) / 100)) : '')
// "1 Jeu cool et 2 Jeu caca": the options given at the start of the period
const startingBonuses = computed(() => {
  const parts = (rules.value.bonuses ?? []).filter((bonus) => bonus.starting > 0).map((bonus) => `${bonus.starting} ${bonus.label}`)
  return parts.length > 1 ? t('help.options.last_bonus', { bonuses: parts.slice(0, -1).join(', '), last: parts.at(-1) }) : parts[0]
})
const gamePacks = computed(() => (rules.value.game_packs ?? []).map((pack) => t('help.attacks.pack', { games: pack.count, price: formatScore(pack.price) })).join(', '))
</script>

<template>
  <div class="p-2">
    <KadoPageTitle class="mb-5">{{ $t('help.title') }}</KadoPageTitle>

    <!-- the table of content: the parts as the tabs of the site, the sections of the open part below -->
    <nav class="mb-3">
      <ul class="flex flex-wrap justify-center gap-1">
        <li v-for="(part, i) in toc" :key="part.id">
          <button type="button"
                  class="h-[26px] cursor-pointer border border-solid bg-repeat-x px-2.5 font-[inherit] text-[15px] leading-6 font-bold whitespace-nowrap small-caps"
                  :class="openPart?.id === part.id
                    ? 'border-white bg-kado-teal-500 bg-[url(/gfx/bgTabmenuActive.jpg)] text-white bg-blend-multiply'
                    : 'border-kado-teal-500 bg-[url(/gfx/bgTabmenu.jpg)] text-kado-blue-700 hover:bg-[url(/gfx/bgTabmenuHover.jpg)] hover:text-kado-teal-500'"
                  :title="`${romans[i]}. ${part.title}`"
                  @click="go(part.index)">
            {{ part.title }}
          </button>
        </li>
      </ul>
    </nav>

    <!-- one section at a time: they slide in the box -->
    <div class="h-[400px] overflow-hidden">
      <div class="transition-transform duration-[600ms] ease-in-out motion-reduce:transition-none" :style="{ transform: `translateY(-${current * 400}px)` }">
        <section v-for="(section, index) in sections"
                 :id="`help_${section.id}`"
                 :key="section.id"
                 class="flex h-[400px] gap-3"
                 :aria-hidden="index !== current">
          <img :src="section.art" alt="" class="hidden h-[400px] w-[275px] shrink-0 sm:block" />
          <div class="h-[400px] min-w-0 flex-1 overflow-y-auto [&_h3]:mt-0 [&_h3]:mb-1.5 [&_p]:mx-2.5 [&_p]:mt-1 [&_p]:mb-2.5 [&_p]:text-[13px] [&_p]:leading-4 [&_table]:mt-1 [&_table]:mb-2.5 [&_table]:text-[13px] [&_table]:leading-4 [&_ul]:mt-1 [&_ul]:mb-2.5 [&_ul]:pl-2.5 [&_ul]:text-[13px] [&_ul]:leading-4">
            <h3 class="text-2xl font-semibold text-kado-blue-800">{{ section.title }}</h3>
            <!-- the sections of the part (the clans), as small links -->
            <nav v-if="partOf(index).children.length" class="mb-2 text-xs">
              <template v-for="(s, i) in [partOf(index), ...partOf(index).children]" :key="s.id">
                <span v-if="i" class="mx-1 text-kado-teal-500">·</span>
                <strong v-if="s.index === index" class="text-kado-blue-700">{{ i ? s.short : $t('help.overview') }}</strong>
                <a v-else href="#" @click.prevent="go(s.index)">{{ i ? s.short : $t('help.overview') }}</a>
              </template>
            </nav>

            <template v-if="section.id === 'bienvenue'">
              <i18n-t keypath="help.welcome.intro" tag="p">
                <template #site><strong>{{ $t('common.site_name') }}</strong></template>
              </i18n-t>
              <i18n-t keypath="help.welcome.contract" tag="p">
                <template #points><strong>{{ $t('help.kado_points') }}</strong></template>
                <template #icon><img src="/gfx/skpoint.gif" :alt="$t('help.kado_alt')" class="inline size-4" /></template>
              </i18n-t>
              <p>{{ clanStore.enabled ? $t('help.welcome.navigation_with_clans') : $t('help.welcome.navigation') }}</p>
            </template>

            <template v-else-if="section.id === 'periodes'">
              <i18n-t keypath="help.periods.length" tag="p">
                <template #days><strong>{{ $t('help.periods.days') }}</strong></template>
              </i18n-t>
              <p>{{ clanStore.enabled ? $t('help.periods.close_with_clans') : $t('help.periods.close') }}</p>
            </template>

            <template v-else-if="section.id === 'jeudujour'">
              <i18n-t keypath="help.daily.draw" tag="p">
                <template #same><strong>{{ $t('help.daily.same') }}</strong></template>
                <template #attempt><strong>{{ $t('help.daily.attempt') }}</strong></template>
                <template #icon><img src="/gfx/skpoint.gif" :alt="$t('help.kado_alt')" class="inline size-4" /></template>
              </i18n-t>
              <i18n-t keypath="help.daily.top10" tag="p">
                <template #ranking_points><strong>{{ $t('help.daily.ranking_points') }}</strong></template>
              </i18n-t>
              <i18n-t keypath="help.daily.reward" tag="p">
                <template #every_player><strong>{{ $t('help.daily.every_player') }}</strong></template>
                <template #kado>{{ dailyKadoPerPoint }}</template>
                <template #icon><img src="/gfx/skpoint.gif" :alt="$t('help.kado_alt')" class="inline size-4" /></template>
              </i18n-t>
            </template>

            <template v-else-if="section.id === 'etoiles'">
              <p>{{ $t('help.stars.intro') }}</p>
              <ul>
                <li v-for="star in stars" :key="star.name"><img :src="star.image" :alt="star.name" class="inline size-5" /> {{ star.withArticle }}</li>
              </ul>
              <p>{{ $t('help.stars.outro') }}</p>
            </template>

            <template v-else-if="section.id === 'niveaux'">
              <p>{{ $t('help.levels.intro') }}</p>
              <KadoTable class="w-full">
                <thead>
                  <tr>
                    <th>{{ $t('help.levels.level') }}</th>
                    <th>{{ $t('help.levels.qualified') }}</th>
                    <th>{{ $t('help.levels.star') }}</th>
                    <th>{{ $t('help.levels.kado_points') }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="league in leagueStore.leagues" :key="league.level">
                    <td class="text-left">
                      <div class="flex items-center gap-1">
                        <img :src="`/gfx/leagues/${league.level}.svg`" :alt="league.name" class="h-5">
                        <div>{{ league.name }}</div>
                      </div>
                    </td>
                    <td class="text-left">
                      <span v-if="league.promotion_ratio">{{ $t('help.levels.ratio', { ratio: league.promotion_ratio, max: league.promotion_max_slots }) }}</span>
                      <span v-else>{{ league.promotion_max_slots }}</span>
                    </td>
                    <td>
                      <img v-if="league.promotion_min_stars !== null"
                           :src="stars[league.promotion_min_stars].image"
                           :alt="stars[league.promotion_min_stars].name"
                           class="inline h-5">
                    </td>
                    <td class="text-right whitespace-nowrap">
                      {{ formatScore(league.promotion_reward) }} <img src="/gfx/skpoint.gif" :alt="$t('help.kado_alt')" class="inline size-4">
                    </td>
                  </tr>
                </tbody>
              </KadoTable>
              <p>{{ $t('help.levels.alone') }}</p>
            </template>

            <template v-else-if="section.id === 'clans'">
              <p>{{ $t('help.clans.intro', { max: rules.max_members }) }}</p>
              <i18n-t keypath="help.clans.join" tag="p">
                <template #link><RouterLink :to="{ name: 'clans.index' }">{{ $t('help.clans.join_link') }}</RouterLink></template>
              </i18n-t>
              <i18n-t v-if="rules.creation_price || rules.application_price" keypath="help.clans.prices" tag="p">
                <template #creation><strong>{{ $t('help.clans.price', { points: formatScore(rules.creation_price ?? 0) }) }}</strong></template>
                <template #application><strong>{{ $t('help.clans.price', { points: formatScore(rules.application_price ?? 0) }) }}</strong></template>
              </i18n-t>
              <p>{{ $t('help.clans.locked') }}</p>
              <i18n-t keypath="help.clans.leaders" tag="p">
                <template #chief><strong>{{ $t('help.clans.chief') }}</strong></template>
                <template #right_hands><strong>{{ $t('help.clans.right_hands') }}</strong></template>
              </i18n-t>
              <p>{{ $t('help.clans.two_rankings') }}</p>
              <p>{{ $t('help.clans.player_ranking') }}</p>
            </template>

            <template v-else-if="section.id === 'attaques'">
              <i18n-t keypath="help.attacks.how" tag="p">
                <template #icon><img src="/assets/img/gfx/icons/atk.gif" :alt="$t('help.attacks.icon_alt')" class="inline" /></template>
              </i18n-t>
              <p>{{ $t('help.attacks.repel') }}</p>
              <i18n-t keypath="help.attacks.reward" tag="p">
                <template #hours><strong>{{ $t('help.attacks.hours', { hours: rules.attack_hours }) }}</strong></template>
                <template #points><strong>{{ $t('help.attacks.points', { points: rules.attack_max_points }) }}</strong></template>
                <template #max>{{ rules.attack_max_points }}</template>
                <template #palier>{{ rules.attack_points_palier }}</template>
                <template #range>{{ rules.protection_range }}</template>
              </i18n-t>
              <p>{{ $t('help.attacks.upgrade', { hours: rules.attack_hours }) }}</p>
              <i18n-t keypath="help.attacks.closing" tag="p">
                <template #before_end><strong>{{ $t('help.attacks.before_end', { hours: rules.attack_hours }) }}</strong></template>
              </i18n-t>
              <i18n-t keypath="help.attacks.games" tag="p">
                <template #free><strong>{{ $t('help.attacks.free', { games: rules.attack_games_per_day }) }}</strong></template>
                <template #clan_games><strong>{{ $t('help.attacks.clan_games') }}</strong></template>
                <template #packs>{{ gamePacks }}</template>
              </i18n-t>
            </template>

            <template v-else-if="section.id === 'defenses'">
              <i18n-t keypath="help.defenses.where" tag="p">
                <template #icon><img src="/assets/img/gfx/icons/def.gif" :alt="$t('help.defenses.icon_alt')" class="inline" /></template>
              </i18n-t>
              <p>{{ $t('help.defenses.blocked') }}</p>
              <i18n-t keypath="help.defenses.defender" tag="p">
                <template #defender><strong>{{ $t('help.roles.defender') }}</strong></template>
                <template #link><a href="#" @click.prevent="go(sections.findIndex((s) => s.id === 'roles'))">{{ $t('help.defenses.defender_link') }}</a></template>
              </i18n-t>
              <p>{{ $t('help.defenses.reserve') }}</p>
              <p>{{ $t('help.defenses.progress') }}</p>
            </template>

            <template v-else-if="section.id === 'roles'">
              <i18n-t keypath="help.roles.intro" tag="p">
                <template #member><strong>{{ $t('help.roles.member') }}</strong></template>
                <template #attacker><strong>{{ $t('help.roles.attacker') }}</strong></template>
                <template #defender><strong>{{ $t('help.roles.defender') }}</strong></template>
              </i18n-t>
              <KadoTable class="w-full">
                <thead>
                  <tr>
                    <th class="text-left">{{ $t('help.roles.role') }}</th>
                    <th>{{ $t('help.roles.attacks_at_once') }}</th>
                    <th>{{ $t('help.roles.defend_while_attacking') }}</th>
                    <th>{{ $t('help.roles.seats') }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="text-left"><strong>{{ $t('help.roles.attacker') }}</strong></td>
                    <td>2</td>
                    <td>{{ $t('help.roles.no') }}</td>
                    <td>{{ $t('help.roles.seats_share', { percent: rules.attacker_seats }) }}</td>
                  </tr>
                  <tr>
                    <td class="text-left"><strong>{{ $t('help.roles.defender') }}</strong></td>
                    <td>1</td>
                    <td>{{ $t('help.roles.yes') }}</td>
                    <td>{{ $t('help.roles.seats_share', { percent: rules.defender_seats }) }}</td>
                  </tr>
                  <tr>
                    <td class="text-left"><strong>{{ $t('help.roles.member') }}</strong></td>
                    <td>1</td>
                    <td>{{ $t('help.roles.no') }}</td>
                    <td>{{ $t('help.roles.seats_others') }}</td>
                  </tr>
                </tbody>
              </KadoTable>
              <p>{{ $t('help.roles.example', { max: rules.max_members, attackers: seatsFor(rules.max_members, rules.attacker_seats), defenders: seatsFor(rules.max_members, rules.defender_seats) }) }}</p>
              <i18n-t keypath="help.roles.locked" tag="p">
                <template #locked_until><strong>{{ $t('help.roles.locked_until') }}</strong></template>
              </i18n-t>
            </template>

            <template v-else-if="section.id === 'missions'">
              <i18n-t v-if="rules.mission_minutes_less > 0" keypath="help.missions.time_decreasing" tag="p">
                <template #hours><strong>{{ $t('help.missions.hours', { hours: rules.mission_hours }) }}</strong></template>
                <template #less>{{ formatMinutes(rules.mission_minutes_less) }}</template>
                <template #min>{{ formatMinutes(Math.min(rules.mission_min_minutes, rules.mission_hours * 60)) }}</template>
                <template #free><strong>{{ $t('help.missions.free') }}</strong></template>
              </i18n-t>
              <i18n-t v-else keypath="help.missions.time" tag="p">
                <template #hours><strong>{{ $t('help.missions.hours', { hours: rules.mission_hours }) }}</strong></template>
                <template #free><strong>{{ $t('help.missions.free') }}</strong></template>
              </i18n-t>
              <p>{{ $t('help.missions.reserve') }}</p>
              <p>{{ $t('help.missions.steps', { alone: rules.mission_steps_alone, full: rules.mission_steps_full, max: rules.max_members }) }}</p>
              <i18n-t keypath="help.missions.reward" tag="p">
                <template #points><strong>{{ $t('help.missions.points', { points: rules.mission_points_first }) }}</strong></template>
                <template #every>{{ rules.mission_points_every }}</template>
                <template #min>{{ rules.mission_points_min }}</template>
              </i18n-t>
            </template>

            <template v-else-if="section.id === 'options'">
              <p>{{ startingBonuses ? $t('help.options.intro_with_starting', { bonuses: startingBonuses, chance: rules.bonus_chance }) : $t('help.options.intro', { chance: rules.bonus_chance }) }}</p>
              <KadoTable class="w-full">
                <tbody>
                  <tr v-for="bonus in rules.bonuses ?? []" :key="bonus.type">
                    <td class="w-10"><img :src="bonus.icon" :alt="bonus.label" class="size-9 max-w-none"></td>
                    <i18n-t keypath="help.options.bonus" tag="td" class="text-left text-xs">
                      <template #label><strong>{{ bonus.label }}</strong></template>
                      <template #description>{{ bonus.description }}</template>
                    </i18n-t>
                  </tr>
                </tbody>
              </KadoTable>
            </template>

            <template v-else-if="section.id === 'classement'">
              <p>{{ $t('help.clan_ranking.intro') }}</p>
              <div class="flex flex-wrap gap-4">
                <KadoTable v-for="ranking in clanRewards" :key="ranking.title" class="min-w-48 flex-1">
                  <thead>
                    <tr><th colspan="2" class="text-xs">{{ ranking.title }}</th></tr>
                  </thead>
                  <tbody>
                    <tr v-for="reward in ranking.rewards" :key="reward.from">
                      <td class="text-left">{{ ranks(reward) }}</td>
                      <td class="text-right">{{ formatScore(reward.points) }} <img src="/gfx/skpoint.gif" :alt="$t('help.kado_alt')" class="inline size-4"></td>
                    </tr>
                  </tbody>
                </KadoTable>
              </div>
            </template>

            <template v-else-if="section.id === 'classementv1'">
              <p>{{ $t('help.v1_ranking.intro') }}</p>
              <p>{{ $t('help.v1_ranking.scale') }}</p>

              <KadoTable>
                <thead>
                  <tr>
                    <th>{{ $t('help.v1_ranking.score_reached') }}</th>
                    <th>{{ $t('help.v1_ranking.v1_points') }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td><img src="/gfx/iconGreenStar.gif" :alt="$t('help.v1_ranking.green_star')" /></td>
                    <td>1000</td>
                  </tr>
                  <tr>
                    <td><img src="/gfx/iconOrangeStar.gif" :alt="$t('help.v1_ranking.orange_star')" /></td>
                    <td>1100</td>
                  </tr>
                  <tr>
                    <td><img src="/gfx/iconRedStar.gif" :alt="$t('help.v1_ranking.red_star')" /></td>
                    <td>1150</td>
                  </tr>
                  <tr>
                    <td>{{ $t('help.v1_ranking.v1_score') }}</td>
                    <td>1500</td>
                  </tr>
                </tbody>
              </KadoTable>
            </template>

            <template v-else-if="section.id === 'compte'">
              <i18n-t keypath="help.account.look" tag="p">
                <template #link><RouterLink :to="{ name: 'account' }">{{ $t('help.account.look_link') }}</RouterLink></template>
              </i18n-t>
              <i18n-t keypath="help.account.karbon" tag="p">
                <template #theme><strong>{{ $t('help.account.karbon_theme') }}</strong></template>
              </i18n-t>
            </template>

            <template v-else-if="section.id === 'questions'">
              <i18n-t keypath="help.questions.other" tag="p">
                <template #discord><a href="https://discord.gg/cqasFsD" target="_blank">{{ $t('help.questions.discord') }}</a></template>
              </i18n-t>
              <p>{{ $t('help.questions.enjoy') }}</p>
            </template>
          </div>
        </section>
      </div>
    </div>

    <p class="mx-2.5 my-4 flex justify-between">
      <FormButton v-if="current > 0"
                  size="lg"
                  variant="pink"
                  @click="go(current - 1)">{{ $t('help.previous') }}</FormButton>
      <span v-else></span>
      <FormButton v-if="current < sections.length - 1" size="lg" @click="go(current + 1)">{{ $t('help.next') }}</FormButton>
    </p>
  </div>
</template>

