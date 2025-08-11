<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\GuestUploadController;
use App\Http\Controllers\MeasurementController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TaskController;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

/*
|--------------------------------------------------------------------------
| Routes Web
|--------------------------------------------------------------------------
*/

// Page d'accueil
Route::get('/', function () {
    return Inertia::render('Welcome', [
        'canLogin' => Route::has('login'),
        'canRegister' => Route::has('register'),
        'laravelVersion' => Application::VERSION,
        'phpVersion' => PHP_VERSION,
    ]);
});

// Routes publiques pour les invités
Route::prefix('guest')->name('guest.')->group(function () {
    Route::get('/{token}', [GuestUploadController::class, 'show'])->name('show');
    Route::post('/{token}/photos', [GuestUploadController::class, 'store'])->name('upload');
    Route::get('/{token}/check', [GuestUploadController::class, 'checkToken'])->name('check');
});

// Routes protégées par authentification
Route::middleware(['auth', 'verified'])->group(function () {
    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    
    // Gestion des tâches
    Route::resource('tasks', TaskController::class);
    Route::post('/tasks/{task}/guest-link', [TaskController::class, 'generateGuestLink'])->name('tasks.guest-link');
    Route::post('/tasks/{task}/photos/{photo}/process', [TaskController::class, 'reprocessPhoto'])->name('tasks.reprocess-photo');
    Route::post('/tasks/{task}/photos/{photo}/measure', [MeasurementController::class, 'store'])->name('measurements.store');
    
    // Gestion des mesures
    Route::get('/measurements/{measurement}', [MeasurementController::class, 'show'])->name('measurements.show');
    Route::put('/measurements/{measurement}', [MeasurementController::class, 'update'])->name('measurements.update');
    Route::delete('/measurements/{measurement}', [MeasurementController::class, 'destroy'])->name('measurements.destroy');
    
    // Profil utilisateur
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

// Routes d'authentification (générées par Laravel Breeze)
require __DIR__.'/auth.php';