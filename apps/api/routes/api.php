<?php

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

Route::get('/user', static function (Request $request) {
	return $request->user();
})->middleware('auth:sanctum');

Route::get('v1/test', static function () {
	Log::info('Time1: ' . Carbon::now()->toDateTimeString());
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

Route::post('v1/test-queue', static function (Request $request) {
	$startTime = Carbon::now();

	Log::info('Test Queue API (Closure) V3 called at: ' . $startTime->toDateTimeString());

	// Validate dữ liệu từ request
	$data = $request->validate([
		'message' => 'nullable|string|max:500',
		'delay' => 'nullable|integer|min:0|max:30',   // delay tối đa 30 giây
	]);

	$customMessage = $data['message'] ?? 'Test Queue Job bằng Closure thành công!';
	$delaySeconds = (int)($data['delay'] ?? 0);

	// Dispatch closure vào queue
	$pendingDispatch = dispatch(static function () use ($customMessage) {
		Log::info('=== QUEUE CLOSURE JOB STARTED ===');
		Log::info('Message from API: ' . $customMessage);
		Log::info('Processed at: ' . now()->toDateTimeString());

		// Giả lập công việc mất thời gian (để thấy rõ là async)
		sleep(3);

		Log::info('=== QUEUE CLOSURE JOB COMPLETED ===');
	});

	// Thêm delay nếu có
	if ($delaySeconds > 0) {
		$pendingDispatch->delay(now()->addSeconds($delaySeconds));
		$statusMessage = "Job Closure đã được đẩy vào queue với delay $delaySeconds giây.";
	} else {
		$statusMessage = "Job Closure đã được dispatch thành công vào queue.";
	}

	$endTime = Carbon::now();

	return response()->json([
		'status' => 'success',
		'message' => $statusMessage,
		'dispatched_at' => $startTime->toDateTimeString(),
		'response_time' => $startTime->diffInMilliseconds($endTime) . ' ms',
		'job_data' => [
			'message' => $customMessage,
			'delay' => $delaySeconds . ' giây'
		],
		'note' => 'Mở terminal chạy "php artisan queue:work" để xem job chạy. Kiểm tra file storage/logs/laravel.log'
	]);
});