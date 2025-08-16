<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\GuestUploadController;
use App\Http\Controllers\GuestUploadControllerDebug;
use App\Http\Controllers\MeasurementController;
use App\Http\Controllers\DashboardController;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('Welcome', [
        'canLogin' => Route::has('login'),
        'canRegister' => Route::has('register'),
        'laravelVersion' => Application::VERSION,
        'phpVersion' => PHP_VERSION,
    ]);
});

Route::get('/dashboard', [DashboardController::class, 'index'])->middleware(['auth', 'verified'])->name('dashboard');

// Routes pour les tâches (authentifiées)
Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
    
    // Routes des tâches
    Route::resource('tasks', TaskController::class);
    Route::post('/tasks/{task}/guest-link', [TaskController::class, 'generateGuestLink'])->name('tasks.guest-link');
    Route::post('/tasks/{task}/photos/{photo}/reprocess', [TaskController::class, 'reprocessPhoto'])->name('tasks.photos.reprocess');
    
    // Routes des mesures
    Route::post('/tasks/{task}/measurements', [MeasurementController::class, 'store'])->name('tasks.measurements.store');
    Route::post('/tasks/{task}/photos/{photo}/measure', [MeasurementController::class, 'store'])->name('measurements.store');
    Route::get('/measurements/{measurement}', [MeasurementController::class, 'show'])->name('measurements.show');
    Route::put('/measurements/{measurement}', [MeasurementController::class, 'update'])->name('measurements.update');
    Route::delete('/measurements/{measurement}', [MeasurementController::class, 'destroy'])->name('measurements.destroy');
    
    // Route pour les notifications
    Route::get('/dashboard/notifications', [DashboardController::class, 'notifications'])->name('dashboard.notifications');
});

// Routes publiques pour l'upload invité
Route::get('/guest/{token}', [GuestUploadController::class, 'show'])->name('guest.upload');
Route::post('/guest/{token}/photos', [GuestUploadController::class, 'store'])->name('guest.photos.store');
Route::get('/guest/{token}/check', [GuestUploadController::class, 'checkToken'])->name('guest.check');

// Route de débogage temporaire pour l'erreur 422
Route::post('/guest/{token}/photos-debug', [GuestUploadControllerDebug::class, 'store'])->name('guest.photos.debug');

require __DIR__.'/auth.php';
