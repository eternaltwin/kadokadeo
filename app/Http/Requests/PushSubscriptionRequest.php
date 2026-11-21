<?php

namespace App\Http\Requests;

use Closure;
use Illuminate\Foundation\Http\FormRequest;

// the server sends requests to the endpoint: only the push services of the browsers (SSRF)
class PushSubscriptionRequest extends FormRequest
{
    // a public key P-256, uncompressed
    private const PUBLIC_KEY_BYTES = 65;

    private const AUTH_TOKEN_BYTES = 16;

    public function rules(): array
    {
        return [
            'endpoint' => ['required', 'string', 'max:500', 'url:https', $this->ofAPushService(...)],
            'keys.p256dh' => ['required', 'string', $this->base64urlOf(self::PUBLIC_KEY_BYTES)],
            'keys.auth' => ['required', 'string', $this->base64urlOf(self::AUTH_TOKEN_BYTES)],
        ];
    }

    private function ofAPushService(string $attribute, mixed $endpoint, Closure $fail): void
    {
        $host = strtolower((string) parse_url((string) $endpoint, PHP_URL_HOST));
        $known = collect(config('kado.push_services'))->contains(fn (string $service) => $host === $service || str_ends_with($host, ".{$service}"));
        if (!$known) {
            $fail('validation.url')->translate();
        }
    }

    private function base64urlOf(int $bytes): Closure
    {
        return function (string $attribute, mixed $value, Closure $fail) use ($bytes) {
            $decoded = is_string($value) && preg_match('/^[A-Za-z0-9_-]+={0,2}$/', $value) === 1 ? base64_decode(strtr($value, '-_', '+/'), true) : false;
            if ($decoded === false || strlen($decoded) !== $bytes) {
                $fail('validation.string')->translate();
            }
        };
    }
}
