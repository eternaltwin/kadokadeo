import { formatScore } from '@/composables/helpers'
import { t } from '@/i18n'

import { useApi } from './useApi'
import { usePaginatedList } from './usePaginatedList'

// the text and the link of a notification of the player (App\Http\Resources\UserNotificationResource), in the tab
// « Notifications » and in the toasts
export function notificationText(notification) {
  const actor = notification.actor?.display_name ?? t('notifications.a_player')
  const game = notification.run?.game?.name
  const ofGame = game ? t('notifications.of_game', { game }) : ''
  switch (notification.type) {
    case 'run_comment':
      return t('notifications.run_comment', { actor, ofGame })
    case 'comment_reply':
      return t('notifications.comment_reply', { actor, ofGame })
    case 'comment_likes': {
      const others = notification.count - 1
      return others > 0
        ? t('notifications.comment_likes_others', { actor, ofGame, count: others }, others)
        : t('notifications.comment_like', { actor, ofGame })
    }
    case 'clan_application':
      return t('notifications.clan_application', { actor, clan: notification.clan?.name ?? '' })
    case 'clan_accepted':
      return t('notifications.clan_accepted', { clan: notification.clan?.name ?? '' })
    case 'clan_refused':
      return t('notifications.clan_refused', { clan: notification.clan?.name ?? '' })
    default:
      return t('notifications.new')
  }
}

export function notificationLink(notification) {
  switch (notification.type) {
    case 'run_comment':
    case 'comment_reply':
    case 'comment_likes':
      return notification.run ? { name: 'runs.show', params: { id: notification.run.id }, query: notification.comment ? { comment: notification.comment.id } : {} } : null
    case 'clan_application':
      return notification.clan ? { name: 'clans.manage', params: { id: notification.clan.id } } : null
    case 'clan_accepted':
    case 'clan_refused':
      return notification.clan ? { name: 'clans.show', params: { id: notification.clan.id } } : null
    default:
      return null
  }
}

// the toasts of the feats of the clan of the player (App\Events\ClanToast)
export function clanToast(event) {
  const player = event.player?.display_name
  const game = event.game?.name
  switch (event.kind) {
    case 'defense_repelled':
      return { title: t('notifications.defense_title'), text: t('notifications.defense_text', { player, game, score: formatScore(event.score) }), to: { name: 'clans.status', params: { id: event.clan_id } } }
    case 'step_completed':
      return { title: t('notifications.step_title'), text: t('notifications.step_text', { player, game, score: formatScore(event.score) }), to: { name: 'clans.missions', params: { id: event.clan_id } } }
    case 'mission_available':
      return { title: t('notifications.clan_toast_title'), text: t('notifications.mission_text'), to: { name: 'clans.missions', params: { id: event.clan_id } } }
    default:
      return null
  }
}

// the notifications of the player, page by page (App\Http\Controllers\Api\NotificationController); onPage: what comes
// with a page (its unread counts)
export function useNotificationList({ onPage = null } = {}) {
  return usePaginatedList('/notifications', { onPage })
}

// what the player does with their notifications: read them all, delete one or all
export function useNotificationActions() {
  const { isLoading, error, post, del } = useApi()

  return {
    isLoading,
    error,
    // their unread counts after
    markRead: () => post('/notifications/read').then((response) => response.data.data),
    remove: (id) => del(`/notifications/${id}`),
    removeAll: () => del('/notifications'),
  }
}
