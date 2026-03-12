<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

// Halaman pertama yang muncul = Login
Route::get('/', function () {
    return redirect()->route('login');
});

// Login
Route::get('/login',  [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login'])->name('login.post');
Route::post('/logout',[AuthController::class, 'logout'])->name('logout');

// Setelah login berhasil → ke biodata (dilindungi middleware auth)
Route::middleware('auth')->group(function () {
    Route::get('/biodata', function () {
        return view('biodata');
    })->name('biodata');

    Route::get('/penugasan',        fn() => view('penugasan'))->name('penugasan');
    Route::get('/laman-pengunjung', fn() => view('laman-pengunjung'))->name('laman-pengunjung');
    Route::get('/tabel',            fn() => view('tabel'))->name('tabel');
});

Route::get('/register', [AuthController::class, 'showRegister'])->name('register');
Route::post('/register',[AuthController::class, 'register'])->name('register.post');
Route::get('/forgot-password', fn() => view('auth.forgot-password'))->name('password.request');