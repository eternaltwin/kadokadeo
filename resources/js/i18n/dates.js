// The dates shown to a player. A date for the server or for a comparison keeps its own format, without this file.
import dayjs from 'dayjs'

import { intlLocale, pageLocale } from './locale'

const FORMATS = {
  fr: {
    date: 'DD/MM/YYYY',
    dateTime: 'DD/MM/YYYY HH:mm',
    dateAt: 'DD/MM/YYYY à HH:mm',
    shortDateAt: 'DD/MM/YY à HH:mm',
    dayTime: 'DD/MM HH:mm',
    dayAt: 'DD/MM à HH:mm',
  },
  en: {
    date: 'MM/DD/YYYY',
    dateTime: 'MM/DD/YYYY HH:mm',
    dateAt: 'MM/DD/YYYY [at] HH:mm',
    shortDateAt: 'MM/DD/YY [at] HH:mm',
    dayTime: 'MM/DD HH:mm',
    dayAt: 'MM/DD [at] HH:mm',
  },
}

export const formatDate = (date, style = 'date') => dayjs(date).format((FORMATS[pageLocale()] ?? FORMATS.fr)[style])

export const weekdayOf = (date) => new Date(date).toLocaleDateString(intlLocale(), { weekday: 'long' })
