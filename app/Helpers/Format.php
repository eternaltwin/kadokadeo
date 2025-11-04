<?php

function formatScore(int $score): string
{
    return number_format($score, 0, '.', ' ');
}

function formatTime($seconds): string
{
    if (!is_numeric($seconds) || $seconds < 0) {
        return '??:??';
    }
    $hours = floor($seconds / 3600);
    $minutes = floor(($seconds % 3600) / 60);
    $secs = $seconds % 60;

    if ($hours > 0) {
        return sprintf('%02d:%02d:%02d', $hours, $minutes, $secs);
    } else {
        return sprintf('%02d:%02d', $minutes, $secs);
    }
}
