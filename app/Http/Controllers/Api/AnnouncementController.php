<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Settings\SiteSettings;
use Illuminate\Http\JsonResponse;

class AnnouncementController extends Controller
{
    public function show(SiteSettings $settings): JsonResponse
    {
        return response()->json([
            'data' => $settings->announcement(),
        ]);
    }
}
