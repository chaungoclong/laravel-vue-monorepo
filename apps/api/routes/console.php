<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
	$this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::call(function () {
	Log::info('=== SCHEDULER CLOSURE RUNNING ===');
	Log::info('Task chạy lúc: ' . now()->toDateTimeString());
	Log::info('Server time: ' . now()->timezone('Asia/Ho_Chi_Minh')->toDateTimeString());
	Log::info('=== SCHEDULER TASK COMPLETED ===');
})->everyMinute()->name('test-every-minute')->withoutOverlapping();