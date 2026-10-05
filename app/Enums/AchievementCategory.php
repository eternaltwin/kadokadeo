<?php

namespace App\Enums;

enum AchievementCategory: string
{
    case GLOBAL = 'global';
    case GAME = 'game';
    case SEASONAL = 'seasonal';
}
