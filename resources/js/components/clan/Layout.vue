<script setup>
// the page of a clan as on the old site: the tabs, the "Infos" and "Actions" menu on the left, the name of the clan
const props = defineProps({
  clan: { type: Object, required: true },
  tab: { type: String, required: true },
})
const tabs = computed(() => {
  const id = props.clan.id
  const items = [
    { label: 'Présentation', value: 'show', route: { name: 'clans.show', params: { id } } },
    { label: 'Statut', value: 'status', route: { name: 'clans.status', params: { id } } },
  ]
  if (props.clan.viewer.is_member) {
    items.push({ label: 'Mission', value: 'missions', route: { name: 'clans.missions', params: { id } } })
  }
  // 4 tabs at most, as on the old site (the management is in the "Actions" menu)
  items.push({ label: 'Membres', value: 'members', route: { name: 'clans.members', params: { id } } })
  return items
})
const selectedIndex = computed(() => Math.max(0, tabs.value.findIndex((t) => t.value === props.tab)))

const stats = computed(() => props.clan.stats)
const authStore = useAuthStore()
// the free attack and defense games of the player left today
const freeGames = computed(() => authStore.user?.clan_attack_games ?? 0)
</script>

<template>
  <NavTabs :items="tabs" :selected-index="selectedIndex" />

  <div id="clan" class="flex flex-col md:flex-row gap-2 px-2">
    <div class="clanMenu shrink-0">
      <h3>Infos</h3>
      <ul class="statClan">
        <li class="score" title="Score d'attaque : il augmente lorsque le clan réussit une attaque.">
          <Number :value="stats.war_score" color="orange" />
        </li>
        <li class="rank" title="Position du clan dans le classement des attaques.">
          <Number :value="stats.war_rank ?? 0" color="green" />
        </li>
        <li class="atk" title="Attaques réussies : quand une attaque n'est pas repoussée par le clan adverse à temps, elle est réussie.">
          <Number :value="stats.attacks_won" color="pink" />
        </li>
        <li class="def" title="Défenses réussies : c'est le nombre d'attaques repoussées par ce clan.">
          <Number :value="stats.defenses_won" color="blue" />
        </li>
        <template v-if="clan.viewer.is_member">
          <li class="gemGreen" title="Vos parties gratuites du jour pour attaquer et défendre (les missions sont illimitées).">
            <Number :value="freeGames" color="green" />
          </li>
          <li class="gemOrange" title="Parties dans le coffre du clan : données par les membres, distribuées par le chef et ses bras droits.">
            <Number :value="clan.clan_games ?? 0" color="orange" />
          </li>
        </template>
      </ul>
      <h3>Actions</h3>
      <ul class="action">
        <slot name="actions" />
        <li>
          <RouterLink :to="{ name: 'clans.index' }">Classement</RouterLink>
        </li>
      </ul>
    </div>

    <div class="clanBody min-w-0 flex-1">
      <h1 class="clanName m-0 mb-4 flex items-center gap-2 text-3xl">
        <img src="/gfx/clan/h1_tristar.gif" alt="" class="shrink-0" />
        <ClanName :name="clan.name" />
      </h1>
      <slot />
    </div>
  </div>
</template>

<style>
#clan div.clanMenu {
  width: 161px;
  padding: 10px 0;
}

#clan div.clanMenu h3 {
  margin: 0 0 5px 5px;
  padding-left: 20px;
  font-size: 18px;
  font-weight: normal;
  height: 22px;
  line-height: 20px;
  color: #466167;
  background: url('/gfx/clan/greyh2_bg.jpg') -20px -1px no-repeat;
  border: 1px solid #738e93;
}

#clan div.clanMenu ul {
  margin: 0 0 10px 5px;
  padding: 0;
  list-style: none;
  border: 1px solid #738e93;
  background: url('/gfx/clan/greyBg.jpg') -650px -8px no-repeat;
}

#clan div.clanMenu ul.action {
  border: 0;
  background: none;
}

#clan ul.statClan li {
  height: 30px;
  line-height: 28px;
  text-align: right;
  padding: 0 30px 0 27px;
  background-repeat: no-repeat;
  background-position: 98% 50%;
  border-bottom: 1px solid white;
}

#clan ul.statClan li.rank {
  background-image: url('/assets/img/gfx/icons/clan_score.gif');
}

#clan ul.statClan li.score {
  background-image: url('/assets/img/gfx/icons/clan_points.gif');
}

#clan ul.statClan li.atk {
  background-image: url('/assets/img/gfx/icons/atk.gif');
}

#clan ul.statClan li.def {
  background-image: url('/assets/img/gfx/icons/def.gif');
}

#clan ul.statClan li.gemGreen,
#clan ul.statClan li.gemOrange {
  background-size: 20px auto;
  background-position: 95% 50%;
}

#clan ul.statClan li.gemGreen {
  background-image: url('/gfx/gemGreen.svg');
}

#clan ul.statClan li.gemOrange {
  background-image: url('/gfx/gemOrange.svg');
}
#clan div.clanMenu ul.action li a,
#clan div.clanMenu ul.action li button {
  display: block;
  width: 155px;
  height: 36px;
  margin: 0 0 2px 0;
  padding: 2px 10px 2px 2px;
  box-sizing: border-box;
  border: 0;
  color: #0687b1;
  text-align: right;
  font-size: 14px;
  line-height: 30px;
  /* a single line in the button */
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  text-decoration: none;
  background: url('/assets/img/gfx/icons/clanInfo.gif') no-repeat;
  cursor: pointer;
  font-family: inherit;
}

#clan div.clanMenu ul.action li a:hover,
#clan div.clanMenu ul.action li button:hover {
  color: #6fa20a;
  background-image: url('/assets/img/gfx/icons/clanInfo_hover.gif');
}

#clan h1.clanName {
  -webkit-text-stroke: 0;
}

#clan table td.clanTypeAtk,
#clan table td.clanTypeDef {
  padding: 0 0 0 5px;
  text-align: left;
  font-size: 15px;
  line-height: 17px;
  background-repeat: no-repeat;
  background-position: -34px -6px;
}

#clan table td.clanTypeAtk {
  color: #ff6b9c;
  border: 1px solid #ff6b9c;
  border-left: 5px solid #ff6b9c;
  background-color: #ffe3ec;
  background-image: url('/gfx/clan/pinkh2_bg.jpg');
}

#clan table td.clanTypeDef {
  color: #0687b1;
  border: 1px solid #5babbb;
  border-left: 5px solid #5babbb;
  background-image: url('/gfx/clan/blueh2_bg.jpg');
}

#clan table tr.oddtrue {
  background-color: #eaf8fa;
}

#clan table tr.oddfalse {
  background-color: #fff;
}

#clan .clanButton {
  padding: 1px 8px;
  border: 1px solid var(--color-kado-green-600);
  color: var(--color-kado-green-600);
  font-weight: bold;
  background: url('/gfx/bgFormButtonFill.jpg') repeat-x;
  cursor: pointer;
  font-family: inherit;
}

#clan .clanButton.pink {
  border-color: var(--color-kado-pink-600);
  color: var(--color-kado-pink-600);
  background-image: url('/gfx/bgFormButtonPinkFill.jpg');
}

#clan .clanButton:disabled {
  filter: grayscale(1);
  cursor: not-allowed;
}
</style>
