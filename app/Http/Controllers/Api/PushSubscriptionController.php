<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Middleware\EnsurePushIsEnabled;
use App\Http\Requests\PushSubscriptionRequest;
use App\Models\PushSubscription;
use App\Push\PushMessages;
use App\Push\PushOutcome;
use App\Push\PushSender;
use App\Services\PushSubscriptionService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Str;

class PushSubscriptionController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware(EnsurePushIsEnabled::class),
            new Middleware('auth:sanctum'),
        ];
    }

    public function __construct(private readonly PushSubscriptionService $subscriptions) {}

    public function store(PushSubscriptionRequest $request)
    {
        $this->subscriptions->subscribe(
            $request->user(),
            $request->validated('endpoint'),
            publicKey: $request->validated('keys.p256dh'),
            authToken: $request->validated('keys.auth'),
            acceptLanguage: Str::limit((string) $request->header('Accept-Language'), 255, '') ?: null,
        );

        return response()->noContent();
    }

    public function test(Request $request, PushSender $pushServices)
    {
        $subscription = PushSubscription::query()
            ->where('user_id', $request->user()->id)
            ->where('endpoint', (string) $request->input('endpoint'))
            ->firstOrFail();

        $outcome = $pushServices->send($subscription, PushMessages::test(app()->getLocale()));
        if ($outcome === PushOutcome::GONE) {
            $subscription->delete();
        }

        return ['data' => ['outcome' => strtolower($outcome->name)]];
    }

    public function destroy(Request $request)
    {
        $this->subscriptions->unsubscribe($request->user(), (string) $request->input('endpoint'));

        return response()->noContent();
    }
}
