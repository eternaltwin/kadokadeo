<?php

namespace Tests\Unit;

use App\Services\RunService;
use PHPUnit\Framework\TestCase;

class RunServiceTest extends TestCase
{
    private string $publicKey;
    private string $privateKey;
    private RunService $runService;

    protected function setUp(): void
    {
        // Generate a RSA key pair
        $keyResource = openssl_pkey_new([
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ]);
        openssl_pkey_export($keyResource, $privateKey);
        $this->publicKey = openssl_pkey_get_details($keyResource)['key'];
        $this->privateKey = $privateKey;
        $this->runService = new RunService([
            'public_key' => $this->publicKey,
            'private_key' => $this->privateKey,
        ]);
    }

    public function testGetAesKeyFromEncrypted()
    {
        // Random AES key
        $aesKey = random_bytes(16);

        // Encrypt the AES key with the service public key
        openssl_public_encrypt($aesKey, $encryptedAesKey, $this->publicKey);
        $encryptedAesKeyBase64 = base64_encode($encryptedAesKey);

        $result = $this->invokePrivateMethod($this->runService, 'getAesKeyFromEncrypted', [$encryptedAesKeyBase64]);

        $this->assertEquals($aesKey, $result);
    }

    public function testGetDecryptedPayload()
    {
        $aesKey = random_bytes(16);
        $algo = 'aes-128-cbc';
        $ivLength = openssl_cipher_iv_length($algo);
        $iv = random_bytes($ivLength);

        $payload = json_encode(['foo' => 'bar']);
        $cipherText = openssl_encrypt($payload, $algo, $aesKey, OPENSSL_RAW_DATA, $iv);

        $payloadRaw = $iv . $cipherText;
        $payloadBase64 = base64_encode($payloadRaw);

        $result = $this->invokePrivateMethod($this->runService, 'getDecryptedPayload', [$payloadBase64, $aesKey]);

        $this->assertEquals($payload, $result);
    }

    private function invokePrivateMethod($object, $methodName, array $parameters = [])
    {
        $reflection = new \ReflectionClass(get_class($object));
        $method = $reflection->getMethod($methodName);
        $method->setAccessible(true);
        return $method->invokeArgs($object, $parameters);
    }
}
