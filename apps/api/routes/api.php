<?php

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

Route::get('/user', static function (Request $request) {
	return $request->user();
})->middleware('auth:sanctum');

Route::get('/test', static function () {
	Log::info('Time: ' . Carbon::now()->toDateTimeString());
	return response()->json([
		'status' => 'success',
		'message' => 'Laravel API test hoạt động',
		'time' => now()
	]);
});