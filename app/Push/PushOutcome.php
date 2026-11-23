<?php

namespace App\Push;

enum PushOutcome
{
    case DELIVERED;
    case GONE;
    case RETRY;
    // our payload or our keys: trying again would not help
    case REJECTED;
}
