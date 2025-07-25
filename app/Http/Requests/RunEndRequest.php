<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RunEndRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'payload' => 'required|string', // encrypted with AES
            'key' => 'required|string', // AES key, encrypted with server's public key
            'sign' => 'required|string', // signed with AES key
        ];
    }
}
