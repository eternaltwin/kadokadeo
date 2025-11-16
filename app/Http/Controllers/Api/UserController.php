<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Period;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller implements \Illuminate\Routing\Controllers\HasMiddleware
{
    public static function middleware()
    {
        return [
            new \Illuminate\Routing\Controllers\Middleware('auth:sanctum', only: ['index']),
        ];
    }

    /**
     * Display the authenticated user.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $user->load(['stars' => function ($query) {
            $query->where('period_id', Period::current()->first()?->id);
        }]);

        return UserResource::make($user);
    }
}
