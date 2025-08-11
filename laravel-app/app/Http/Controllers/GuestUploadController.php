<?php

namespace App\Http\Controllers;

use App\Models\Task;
use App\Models\Photo;
use App\Jobs\ProcessUploadedPhotoJob;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;

class GuestUploadController extends Controller
{
    /**
     * Afficher la page d'upload pour les invités
     */
    public function show($token)
    {
        $task = Task::where('guest_token', $token)
            ->where('guest_expires', '>', now())
            ->firstOrFail();

        return Inertia::render('GuestUpload', [
            'task' => $task,
            'token' => $token
        ]);
    }

    /**
     * Traiter l'upload des photos par les invités
     */
    public function store(Request $request, $token)
    {
        // Vérifier le token
        $task = Task::where('guest_token', $token)
            ->where('guest_expires', '>', now())
            ->firstOrFail();

        // Validation
        $request->validate([
            'photos' => 'required|array|min:1|max:10',
            'photos.*' => 'required|image|mimes:jpeg,jpg,png|max:10240', // 10MB max
        ], [
            'photos.required' => 'Veuillez sélectionner au moins une photo.',
            'photos.*.image' => 'Chaque fichier doit être une image.',
            'photos.*.mimes' => 'Seuls les formats JPEG, JPG et PNG sont acceptés.',
            'photos.*.max' => 'Chaque image ne doit pas dépasser 10MB.',
        ]);

        $uploadedPhotos = [];

        foreach ($request->file('photos') as $photo) {
            // Générer un nom unique
            $filename = Str::random(40) . '.' . $photo->getClientOriginalExtension();
            $path = "photos/{$task->id}/{$filename}";

            // Stocker le fichier
            $photo->storeAs("photos/{$task->id}", $filename, 'local');

            // Lire les dimensions et EXIF
            $imagePath = storage_path('app/' . $path);
            $imageInfo = getimagesize($imagePath);
            $exifData = null;
            
            if (function_exists('exif_read_data') && in_array($photo->getClientOriginalExtension(), ['jpg', 'jpeg'])) {
                $exifData = @exif_read_data($imagePath);
            }

            // Créer l'enregistrement en base
            $photoRecord = Photo::create([
                'task_id' => $task->id,
                'path' => $path,
                'width_px' => $imageInfo[0],
                'height_px' => $imageInfo[1],
                'exif' => $exifData,
                'metadata' => [
                    'original_name' => $photo->getClientOriginalName(),
                    'uploaded_at' => now()->toISOString(),
                    'file_size' => $photo->getSize()
                ]
            ]);

            // Lancer le traitement asynchrone
            ProcessUploadedPhotoJob::dispatch($photoRecord);

            $uploadedPhotos[] = $photoRecord;
        }

        // Mettre à jour le statut de la tâche
        $task->update(['status' => 'en_execution']);

        return Inertia::render('GuestUpload/Success', [
            'task' => $task,
            'uploaded_count' => count($uploadedPhotos)
        ]);
    }
}
