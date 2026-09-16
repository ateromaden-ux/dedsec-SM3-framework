<?php

use App\Http\Controllers\Api\AuthApiController;
use App\Http\Controllers\Api\KuisApiController;
use App\Http\Controllers\Api\SoalApiController;
use App\Http\Middleware\ApiTokenAuth;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
| Semua route di sini bisa diakses via: /api/...
| Auth menggunakan Bearer token (disimpan hash di kolom guru.api_token)
*/

// Public: Login
Route::post('/auth/login', [AuthApiController::class, 'login']);

// Protected routes
Route::middleware(ApiTokenAuth::class)->group(function () {
    // Auth
    Route::post('/auth/logout', [AuthApiController::class, 'logout']);
    Route::get('/auth/me', [AuthApiController::class, 'me']);

    // Materi (dropdown)
    Route::get('/materi', [KuisApiController::class, 'materiList']);

    // Kuis CRUD
    Route::get('/kuis',          [KuisApiController::class, 'index']);
    Route::post('/kuis',         [KuisApiController::class, 'store']);
    Route::get('/kuis/{id}',     [KuisApiController::class, 'show']);
    Route::put('/kuis/{id}',     [KuisApiController::class, 'update']);
    Route::delete('/kuis/{id}',  [KuisApiController::class, 'destroy']);

    // Soal CRUD (nested di bawah kuis)
    Route::get('/kuis/{kuisId}/soal',              [SoalApiController::class, 'index']);
    Route::post('/kuis/{kuisId}/soal',             [SoalApiController::class, 'store']);
    Route::get('/kuis/{kuisId}/soal/{soalId}',     [SoalApiController::class, 'show']);
    Route::put('/kuis/{kuisId}/soal/{soalId}',     [SoalApiController::class, 'update']);
    Route::delete('/kuis/{kuisId}/soal/{soalId}',  [SoalApiController::class, 'destroy']);
});
