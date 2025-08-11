<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\GuestUploadController;
use App\Http\Controllers\PhotoController;

// Routes publiques pour les invités
Route::get('/guest/{token}', [GuestUploadController::class, 'show'])->name('guest.upload');
Route::post('/guest/{token}/photos', [GuestUploadController::class, 'store'])->name('guest.photos.store');

// Routes d'authentification
Route::middleware(['auth'])->group(function () {
    // Dashboard principal
    Route::get('/', [TaskController::class, 'index'])->name('dashboard');
    
    // Gestion des tâches
    Route::resource('tasks', TaskController::class);
    
    // Génération de lien invité
    Route::post('/tasks/{task}/guest-link', [TaskController::class, 'generateGuestLink'])->name('tasks.guest-link');
    
    // Gestion des photos
    Route::post('/tasks/{task}/photos/{photo}/process', [PhotoController::class, 'process'])->name('photos.process');
    Route::post('/tasks/{task}/photos/{photo}/measure', [PhotoController::class, 'measure'])->name('photos.measure');
    
    // Récupération des mesures
    Route::get('/measurements/{measurement}', [PhotoController::class, 'getMeasurement'])->name('measurements.show');
});

// Route de test
Route::get('/test', function () {
    return inertia('Test');
});
