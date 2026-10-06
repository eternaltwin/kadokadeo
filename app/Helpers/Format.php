<?php

function formatScore(int $score): string
{
    return number_format($score, 0, '.', ' ');
}

function formatScoreDotted(int $score): string
{
    return number_format($score, 0, ',', '.');
}

function typoFromImg(?int $nb, int $typo): ?string // Writing with small typo img
{
    if (is_int($nb) && is_int($typo) && $typo > 0 && $typo <= 7) {
        $nb_string = formatScoreDotted($nb);
        $typo_folders = [
            1 => 'green',
            2 => 'orange',
            3 => 'pink',
            4 => 'blue',
            5 => 'bigGreen',
            6 => 'bigOrange',
            7 => 'bigRed',
        ];
        $html_string = '';
        for ($i = 1; $i <= strlen($nb_string); $i++) {
            $img_folder = $typo_folders[$typo];
            $img_name = $nb_string[$i - 1] == '.' ? 'dot' : $nb_string[$i - 1];
            $html_string .= '<img src="/gfx/typo/'.$img_folder.'/'.$img_name.'.svg" alt="'.$img_name.'">';
        }

        return $html_string;
    } else {
        return $nb;
    }
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
