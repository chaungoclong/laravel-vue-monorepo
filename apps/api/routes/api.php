<?php

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

Route::get('/user', static function (Request $request) {
	return $request->user();
})->middleware('auth:sanctum');

Route::get('v1/test', static function () {
	Log::info('Time: ' . Carbon::now()->toDateTimeString());
	return response()->json([
		'status' => 'success',
		'message' => 'Laravel API test hoạt động',
		'time' => now()
	]);
});

Route::post('v1/test-upload', static function (Request $request) {
	Log::info('Upload request received at: ' . Carbon::now()->toDateTimeString());

	// Kiểm tra có file không
	if (!$request->hasFile('file')) {
		return response()->json([
			'status' => 'error',
			'message' => 'Không tìm thấy file. Vui lòng gửi file với key "file"'
		], 422);
	}

	$file = $request->file('file');

	// Kiểm tra file hợp lệ
	if (!$file->isValid()) {
		return response()->json([
			'status' => 'error',
			'message' => 'File không hợp lệ'
		], 422);
	}

	// Lấy thông tin file
	$originalName = $file->getClientOriginalName();
	$mimeType = $file->getMimeType();
	$size = $file->getSize();
	$fileName = $file->hashName();

	// Lưu file vào thư mục storage/app/public/uploads (có thể public)
	$path = $file->storeAs('uploads', $fileName, 'public');

	Log::info("File uploaded successfully: $originalName -> $path");

	return response()->json([
		'status' => 'success',
		'message' => 'Upload file thành công',
		'data' => [
			'original_name' => $originalName,
			'file_name' => $fileName,
			'path' => $path,
			'url' => asset('storage/' . $path),   // link public
			'mime_type' => $mimeType,
			'size' => $size,
			'size_mb' => round($size / 1024 / 1024, 2) . ' MB'
		]
	]);
});