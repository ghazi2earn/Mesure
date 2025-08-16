<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessUploadedPhotoJob;
use App\Models\Photo;
use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Inertia\Inertia;
use Illuminate\Validation\ValidationException;

class GuestUploadControllerDebug extends Controller
{
    /**
     * Version de débogage pour identifier l'erreur 422
     */
    public function store(Request $request, $token)
    {
        // Log détaillé de la requête
        Log::info('=== DEBUG UPLOAD START ===', [
            'token' => $token,
            'method' => $request->method(),
            'url' => $request->url(),
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        // Vérifier la tâche
        $task = Task::where('guest_token', $token)->first();
        if (!$task) {
            Log::error('Task not found', ['token' => $token]);
            return response()->json(['error' => 'Task not found'], 404);
        }

        Log::info('Task found', [
            'task_id' => $task->id,
            'task_title' => $task->title,
            'token_valid' => $task->isGuestTokenValid(),
        ]);

        if (!$task->isGuestTokenValid()) {
            Log::error('Token invalid', ['token' => $token]);
            return response()->json(['error' => 'Token expired'], 403);
        }

        // Log des informations de configuration
        Log::info('Server configuration', [
            'php_upload_max_filesize' => ini_get('upload_max_filesize'),
            'php_post_max_size' => ini_get('post_max_size'),
            'php_max_file_uploads' => ini_get('max_file_uploads'),
            'php_memory_limit' => ini_get('memory_limit'),
            'php_max_execution_time' => ini_get('max_execution_time'),
        ]);

        // Log des données de la requête
        Log::info('Request data', [
            'content_type' => $request->header('Content-Type'),
            'content_length' => $request->header('Content-Length'),
            'has_files' => $request->hasFile('photos'),
            'all_input_keys' => array_keys($request->all()),
            'files_keys' => array_keys($request->allFiles()),
        ]);

        // Vérifier les fichiers uploadés
        if (!$request->hasFile('photos')) {
            Log::error('No photos in request');
            return response()->json(['error' => 'No photos found in request'], 422);
        }

        $photos = $request->file('photos');
        if (!is_array($photos)) {
            Log::error('Photos is not an array', ['type' => gettype($photos)]);
            return response()->json(['error' => 'Photos must be an array'], 422);
        }

        Log::info('Photos analysis', [
            'photos_count' => count($photos),
            'photos_info' => collect($photos)->map(function ($file, $index) {
                return [
                    'index' => $index,
                    'original_name' => $file->getClientOriginalName(),
                    'mime_type' => $file->getClientMimeType(),
                    'size_bytes' => $file->getSize(),
                    'size_mb' => round($file->getSize() / 1024 / 1024, 2),
                    'extension' => $file->getClientOriginalExtension(),
                    'is_valid' => $file->isValid(),
                    'error' => $file->getError(),
                    'error_message' => $file->getErrorMessage(),
                ];
            })->toArray(),
        ]);

        // Test des validations une par une
        try {
            // 1. Validation du nombre de photos
            $request->validate([
                'photos' => 'required|array|min:1|max:10',
            ]);
            Log::info('✓ Validation photos array: OK');
        } catch (ValidationException $e) {
            Log::error('✗ Validation photos array failed', ['errors' => $e->errors()]);
            return response()->json(['error' => 'Photos array validation failed', 'details' => $e->errors()], 422);
        }

        try {
            // 2. Validation de base des fichiers
            $request->validate([
                'photos.*' => 'required|file',
            ]);
            Log::info('✓ Validation photos file: OK');
        } catch (ValidationException $e) {
            Log::error('✗ Validation photos file failed', ['errors' => $e->errors()]);
            return response()->json(['error' => 'Photos file validation failed', 'details' => $e->errors()], 422);
        }

        try {
            // 3. Validation du type d'image
            $request->validate([
                'photos.*' => 'required|image',
            ]);
            Log::info('✓ Validation photos image: OK');
        } catch (ValidationException $e) {
            Log::error('✗ Validation photos image failed', ['errors' => $e->errors()]);
            return response()->json(['error' => 'Photos image validation failed', 'details' => $e->errors()], 422);
        }

        try {
            // 4. Validation des mimes
            $request->validate([
                'photos.*' => 'required|mimes:jpeg,jpg,png',
            ]);
            Log::info('✓ Validation photos mimes: OK');
        } catch (ValidationException $e) {
            Log::error('✗ Validation photos mimes failed', ['errors' => $e->errors()]);
            return response()->json(['error' => 'Photos mimes validation failed', 'details' => $e->errors()], 422);
        }

        try {
            // 5. Validation de la taille
            $request->validate([
                'photos.*' => 'required|max:10240',
            ]);
            Log::info('✓ Validation photos size: OK');
        } catch (ValidationException $e) {
            Log::error('✗ Validation photos size failed', ['errors' => $e->errors()]);
            return response()->json(['error' => 'Photos size validation failed', 'details' => $e->errors()], 422);
        }

        // Test du stockage
        try {
            $storageTest = Storage::disk('public')->put('test_upload.txt', 'test content');
            if ($storageTest) {
                Storage::disk('public')->delete('test_upload.txt');
                Log::info('✓ Storage test: OK');
            } else {
                Log::error('✗ Storage test: FAILED');
                return response()->json(['error' => 'Storage not accessible'], 500);
            }
        } catch (\Exception $e) {
            Log::error('✗ Storage test exception', ['error' => $e->getMessage()]);
            return response()->json(['error' => 'Storage error: ' . $e->getMessage()], 500);
        }

        // Si tout est OK, essayer un upload réel
        try {
            $uploadedPhotos = [];
            foreach ($request->file('photos') as $photoFile) {
                $filename = 'debug_' . $task->id . '_' . uniqid() . '.' . $photoFile->getClientOriginalExtension();
                $path = $photoFile->storeAs('photos/' . $task->id, $filename, 'public');
                
                if (!$path) {
                    throw new \Exception('Failed to store file');
                }

                Log::info('File stored successfully', [
                    'original_name' => $photoFile->getClientOriginalName(),
                    'stored_path' => $path,
                    'disk_exists' => Storage::disk('public')->exists($path),
                ]);

                $uploadedPhotos[] = [
                    'path' => $path,
                    'filename' => $filename,
                    'size' => $photoFile->getSize(),
                ];
            }

            Log::info('=== DEBUG UPLOAD SUCCESS ===', [
                'uploaded_count' => count($uploadedPhotos),
                'files' => $uploadedPhotos,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Debug upload successful',
                'uploaded_files' => $uploadedPhotos,
                'debug_info' => [
                    'task_id' => $task->id,
                    'token' => $token,
                    'timestamp' => now()->toDateTimeString(),
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Upload failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'error' => 'Upload failed: ' . $e->getMessage(),
                'debug_info' => [
                    'task_id' => $task->id,
                    'token' => $token,
                ],
            ], 500);
        }
    }
}
