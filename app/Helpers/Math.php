<?php

function randomNumber()
{
    return mt_rand() / mt_getrandmax();
}
