<?php

// Laravel reads a catalog from PHP, and falls back to French only for a catalog in a group like this one.
// The texts are in server.json, the format of the other catalogs and of the translators.
return json_decode(file_get_contents(__DIR__.'/server.json'), true);
