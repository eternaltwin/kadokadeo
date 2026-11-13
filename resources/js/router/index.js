import './middlewares'

import { createVueRouterMiddleware } from '@yazida/vue-router-middleware'
import { nextTick } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'

import { t } from '@/i18n'
import Account from '@/pages/account.vue'
import BestsScores from '@/pages/bestsScores.vue'
import ClansDebug from '@/pages/clans/debug.vue'
import ClansForumIndex from '@/pages/clans/forum/index.vue'
import ClansForumNew from '@/pages/clans/forum/new.vue'
import ClansForumTopic from '@/pages/clans/forum/topic.vue'
import ClansIndex from '@/pages/clans/index.vue'
import ClansPlay from '@/pages/clans/play.vue'
import ClansShow from '@/pages/clans/show.vue'
import Competition from '@/pages/competition/index.vue'
import ForumIndex from '@/pages/forum/index.vue'
import ForumSection from '@/pages/forum/section.vue'
import ForumThread from '@/pages/forum/thread.vue'
import GamesDaily from '@/pages/games/daily.vue'
import GamesIndex from '@/pages/games/index.vue'
import GamesRanking from '@/pages/games/ranking.vue'
import GamesRecords from '@/pages/games/records.vue'
import GamesShow from '@/pages/games/show.vue'
import Help from '@/pages/help.vue'
import Login from '@/pages/login.vue'
import LoginCallback from '@/pages/loginCallback.vue'
import MessagesIndex from '@/pages/messages/index.vue'
import MessagesShow from '@/pages/messages/show.vue'
import ProfileShow from '@/pages/profile/show.vue'
import RunsShow from '@/pages/runs/show.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/games', meta: {} },
    { path: '/login', name: 'login', component: Login, meta: { title: () => t('titles.login') } },
    // the forum of Eternaltwin (its category of the site)
    { path: '/forum', name: 'forum.index', component: ForumIndex, meta: { middleware: ['auth'], title: () => t('titles.forum') } },
    { path: '/forum/sections/:section', name: 'forum.section', component: ForumSection, meta: { middleware: ['auth'], title: () => t('titles.forum') } },
    { path: '/forum/threads/:thread', name: 'forum.thread', component: ForumThread, meta: { middleware: ['auth'], title: () => t('titles.forum') } },
    { path: '/oauth/callback', component: LoginCallback, meta: {} },
    { path: '/help', name: 'help', component: Help, meta: { middleware: ['auth'], title: () => t('titles.help') } },
    { path: '/daily', name: 'games.daily', component: GamesDaily, meta: { middleware: ['auth'], title: () => t('titles.daily') } },
    { path: '/games', name: 'games.index', component: GamesIndex, meta: { middleware: ['auth'], title: () => t('titles.games') } },
    { path: '/competition', name: 'competition.index', component: Competition, meta: { middleware: ['auth'], title: () => t('titles.competition') } },
    { path: '/site-records', name: 'site-records', component: BestsScores, meta: { middleware: ['auth'], title: () => t('titles.site_records') } },
    { path: '/profile', name: 'profile.index', component: ProfileShow, meta: { middleware: ['auth'], title: () => t('titles.profile') } },
    { path: '/profile/:id', name: 'profile.show', component: ProfileShow, meta: { middleware: ['auth'], title: () => t('titles.profile') } },
    { path: '/games/:id', name: 'games.show', component: GamesShow, meta: { middleware: ['auth'], title: () => t('titles.game') } },
    { path: '/games/:id/ranking', name: 'games.ranking', component: GamesRanking, meta: { middleware: ['auth'], title: () => t('titles.ranking') } },
    { path: '/games/:id/records', name: 'games.records', component: GamesRecords, meta: { middleware: ['auth'], title: () => t('titles.records') } },
    // (built for one replay: a link to another one from its page makes a new page, remount)
    { path: '/runs/:id', name: 'runs.show', component: RunsShow, meta: { middleware: ['auth'], remount: true, title: () => t('titles.replay') } },
    { path: '/messages', name: 'messages.inbox', component: MessagesIndex, meta: { middleware: ['auth'], box: 'inbox', title: () => t('titles.messages') } },
    { path: '/messages/sent', name: 'messages.sent', component: MessagesIndex, meta: { middleware: ['auth'], box: 'sent', title: () => t('titles.messages') } },
    { path: '/messages/new', name: 'messages.new', component: MessagesIndex, meta: { middleware: ['auth'], box: 'new', title: () => t('titles.messages'), keepThroughLogin: true } },
    { path: '/messages/notifications', name: 'messages.notifications', component: MessagesIndex, meta: { middleware: ['auth'], box: 'notifications', title: () => t('titles.notifications') } },
    { path: '/messages/:id(\\d+)', name: 'messages.show', component: MessagesShow, meta: { middleware: ['auth'], title: () => t('titles.messages') } },
    { path: '/account', name: 'account', component: Account, meta: { middleware: ['auth'], title: () => t('titles.account') } },
    { path: '/account/preferences', name: 'account.preferences', component: Account, meta: { middleware: ['auth'], tab: 'preferences', title: () => t('titles.preferences') } },
    { path: '/clans', name: 'clans.index', component: ClansIndex, meta: { middleware: ['auth', 'clans'], title: () => t('titles.clans') } },
    { path: '/clans/debug', name: 'clans.debug', component: ClansDebug, meta: { middleware: ['auth', 'clans'], title: () => t('titles.clans_debug') } },
    { path: '/clans/play/:action', name: 'clans.play', component: ClansPlay, meta: { middleware: ['auth', 'clans'], title: () => t('titles.clan') } },
    { path: '/clans/:id', name: 'clans.show', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'show', title: () => t('titles.clan') } },
    { path: '/clans/:id/status', name: 'clans.status', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'status', title: () => t('titles.clan') } },
    { path: '/clans/:id/missions', name: 'clans.missions', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'missions', title: () => t('titles.clan') } },
    { path: '/clans/:id/members', name: 'clans.members', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'members', title: () => t('titles.clan') } },
    { path: '/clans/:id/manage', name: 'clans.manage', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'manage', title: () => t('titles.clan') } },
    { path: '/clans/:id/history', name: 'clans.history', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'history', title: () => t('titles.clan') } },
    { path: '/clans/:id/games', name: 'clans.games', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'games', title: () => t('titles.clan') } },
    { path: '/clans/:id/attack', name: 'clans.attack', component: ClansShow, meta: { middleware: ['auth', 'clans'], tab: 'attack', title: () => t('titles.clan') } },
    // the private forum of the clan
    { path: '/clans/:id/forum', name: 'clans.forum', component: ClansForumIndex, meta: { middleware: ['auth', 'clans'], title: () => t('titles.clan_forum') } },
    { path: '/clans/:id/forum/new', name: 'clans.forum.new', component: ClansForumNew, meta: { middleware: ['auth', 'clans'], title: () => t('titles.new_topic') } },
    { path: '/clans/:id/forum/:topic(\\d+)', name: 'clans.forum.topic', component: ClansForumTopic, meta: { middleware: ['auth', 'clans'], title: () => t('titles.clan_forum') } },
  ],
})

router.afterEach((to) => {
  nextTick(() => {
    document.title = to.meta.title ? `${to.meta.title()} - ${t('common.site_name')}` : t('common.site_name')
  })
})

createVueRouterMiddleware(router)

export default router
