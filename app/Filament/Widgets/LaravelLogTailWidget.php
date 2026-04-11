<?php

namespace App\Filament\Widgets;

use Filament\Widgets\Widget;

class LaravelLogTailWidget extends Widget
{
    protected string $view = 'filament.widgets.laravel-log-tail-widget';

    protected int|string|array $columnSpan = 'full';

    protected static ?int $sort = 10;

    protected int $maxLines = 120;

    public array $logLines = [];

    public bool $logFileExists = false;

    public string $updatedAt = '';

    public function mount(): void
    {
        $this->refreshLogs();
    }

    public function refreshLogs(): void
    {
        $logPath = storage_path('logs/laravel.log');
        $this->logFileExists = is_file($logPath);

        if (! $this->logFileExists) {
            $this->logLines = [];
            $this->updatedAt = now()->format('H:i:s');

            return;
        }

        $this->logLines = $this->readLastLines($logPath, $this->maxLines);
        $this->updatedAt = now()->format('H:i:s');
    }

    /**
     * @return list<string>
     */
    private function readLastLines(string $path, int $lines): array
    {
        $handle = fopen($path, 'rb');

        if ($handle === false) {
            return [];
        }

        fseek($handle, 0, SEEK_END);
        $position = ftell($handle);

        if ($position === false || $position === 0) {
            fclose($handle);

            return [];
        }

        $buffer = '';
        $lineCount = 0;
        $chunkSize = 4096;

        while ($position > 0 && $lineCount <= $lines) {
            $readSize = min($chunkSize, $position);
            $position -= $readSize;

            fseek($handle, $position);
            $chunk = fread($handle, $readSize);

            if ($chunk === false) {
                break;
            }

            $buffer = $chunk.$buffer;
            $lineCount = substr_count($buffer, "\n");
        }

        fclose($handle);

        $rows = preg_split('/\r\n|\r|\n/', trim($buffer));

        if ($rows === false) {
            return [];
        }

        return array_values(array_slice($rows, -$lines));
    }
}
