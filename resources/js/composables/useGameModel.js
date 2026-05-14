import GreenStar from '@svg/greenStar.svg'
import GreyStar from '@svg/greyStar.svg'
import OrangeStar from '@svg/orangeStar.svg'
import RedStar from '@svg/redStar.svg'

function getStarImage(starId) {
  switch (starId) {
  case 0:
    return GreenStar
  case 1:
    return OrangeStar
  case 2:
    return RedStar
  default:
    return GreyStar
  }
}

export function useGameModel(game) {
  function getStarFromScore(score) {
    const stars = toValue(game)?.stars ?? []
    for (let i = stars.length - 1; i >= 0; i -= 1) {
      if (score >= stars[i]) {
        return getStarImage(i)
      }
    }
    return GreyStar
  }

  return {
    getStarFromScore,
  }
}
