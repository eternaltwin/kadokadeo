<?php

namespace App\Enums;

enum AchievementProgressScope: string
{
    case LIFETIME = 'lifetime';
    case PER_PERIOD = 'per_period';
}
