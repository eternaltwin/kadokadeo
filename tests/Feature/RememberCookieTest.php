<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Tests\TestCase;

class RememberCookieTest extends TestCase
{
    use RefreshDatabase;

    // cookie set by the OAuth callback when it was a web route, for a player without password
    public function test_an_old_remember_cookie_of_a_player_without_password_does_not_break_the_site(): void
    {
        $user = User::factory()->create(['password' => null, 'remember_token' => 'old-remember-token']);
        $this->assertNull($user->fresh()->password);

        $this->withoutVite()
            ->withCookie(Auth::guard('web')->getRecallerName(), "{$user->id}|old-remember-token|legacy-hash")
            ->get('/games')
            ->assertOk();

        $this->assertGuest('web');
    }
}
