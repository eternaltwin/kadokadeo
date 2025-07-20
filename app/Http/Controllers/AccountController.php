<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AccountController extends Controller
{
    public function edit()
    {
        return view('pages.account.edit');
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'email' => 'nullable|email:rfc,dns,filter|max:255',
        ]);

        $user = $request->user();
        $user->update($data);

        return redirect()->route('account.edit')->with('status', 'Compte mis à jour.');
    }
}
