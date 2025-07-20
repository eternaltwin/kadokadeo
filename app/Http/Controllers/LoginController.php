<?php

namespace App\Http\Controllers;

use App\Models\User;
use Eternaltwin\OauthClient\RfcOauthClient;
use Eternaltwin\Client\Auth as EtwinAuth;
use Eternaltwin\Client\HttpEtwinClient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LoginController extends Controller
{
    private readonly RfcOauthClient $oauthClient;
    private readonly HttpEtwinClient $etwinClient;

    public function __construct()
    {
        $this->etwinClient = new HttpEtwinClient(config('services.etwin.identityServerUri'));
        $this->oauthClient = new RfcOauthClient(
            config('services.etwin.eternaltwinUrl') . 'oauth/authorize',
            config('services.etwin.eternaltwinUrl') . 'oauth/token',
            config('app.url') . '/oauth/callback',
            config('services.etwin.oauthId'),
            config('services.etwin.oauthSecret')
        );
    }

    // Send the user the the Eternal-twin connection form for sign in
    public function login()
    {
        $scope = 'base';
        $state = 'kadokadeo';

        try {
            $authorizationUri = $this->oauthClient->getAuthorizationUri($scope, $state);
        } catch (\Exception $e) {
            // TODO: Handle error properly, maybe redirect to an error page
            return $e->getMessage();
        }

        return redirect()->away($authorizationUri);
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/');
    }

    // Get the callback from Eternal-twin when connected successfully, then create the session
    public function loginCallback(Request $request)
    {
        $data = $request->validate([
            'code' => 'required|string',
            //'state' => 'required|string',
        ]);

        $accessToken = $this->oauthClient->getAccessTokenSync($data['code']);
        $self = $this->etwinClient->getSelf(EtwinAuth::fromToken($accessToken->getAccessToken()));
        $user = $self->getUser();
        $userDisplayName = $user->getDisplayName()->getCurrent()->getValue();
        $userUuid = $user->getId();

        $attrs = [
            'ewtin_id' => $userUuid->toString(),
            'display_name' => $userDisplayName->toString(),
            'last_seen_at' => now(),
        ];

        // Check if the user already exists in the database
        $dbUser = User::where('ewtin_id', $userUuid->toString())->first();
        if ($dbUser) {
            $dbUser->fill($attrs);
        } else {
            $dbUser = new User($attrs);
        }
        $dbUser->save();

        Auth::login($dbUser, true);

        return redirect()->intended('/');
    }
}
