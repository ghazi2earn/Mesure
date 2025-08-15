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

class GuestUploadController extends Controller
{
    /**
     * Afficher la page de téléchargement pour les invités.
     */
    public function show($token)
    {
        $task = Task::where('guest_token', $token)->firstOrFail();

        if (!$task->isGuestTokenValid()) {
            abort(403, 'Le lien a expiré.');
        }

        return Inertia::render('GuestUpload', [
            'task' => [
                'id' => $task->id,
                'title' => $task->title,
                'description' => $task->description,
                'existing_photos_count' => $task->photos()->count(),
            ],
            'token' => $token,
        ]);
    }

    /**
     * Traiter le téléchargement de photos par les invités.
     */
    public function store(Request $request, $token)
    {
        $task = Task::where('guest_token', $token)->firstOrFail();

        if (!$task->isGuestTokenValid()) {
            throw ValidationException::withMessages([
                'token' => ['Le lien a expiré.'],
            ]);
        }

        $request->validate([
            'photos' => 'required|array|min:1|max:10',
            'photos.*' => 'required|image|mimes:jpeg,jpg,png|max:10240', // 10MB max
            'contact_email' => 'nullable|email',
            'contact_phone' => 'nullable|string|max:20',
        ]);

        $uploadedPhotos = [];

        try {
            foreach ($request->file('photos') as $photoFile) {
                // Générer un nom de fichier unique
                $filename = 'task_' . $task->id . '_' . uniqid() . '.' . $photoFile->getClientOriginalExtension();
                
                // Stocker le fichier
                $path = $photoFile->storeAs('photos/' . $task->id, $filename, 'public');
                
                // Obtenir les dimensions de l'image
                list($width, $height) = getimagesize($photoFile->getRealPath());
                
                // Extraire les données EXIF si disponibles
                $exif = null;
                if (function_exists('exif_read_data') && in_array($photoFile->getClientOriginalExtension(), ['jpg', 'jpeg'])) {
                    try {
                        $exif = exif_read_data($photoFile->getRealPath());
                    } catch (\Exception $e) {
                        Log::warning('Impossible de lire les données EXIF', ['error' => $e->getMessage()]);
                    }
                }
                
                // Créer l'enregistrement de la photo
                $photo = Photo::create([
                    'task_id' => $task->id,
                    'path' => $path,
                    'exif' => $exif,
                    'width_px' => $width,
                    'height_px' => $height,
                    'metadata' => [
                        'original_name' => $photoFile->getClientOriginalName(),
                        'mime_type' => $photoFile->getClientMimeType(),
                        'size' => $photoFile->getSize(),
                        'uploaded_by' => 'guest',
                        'uploaded_at' => now()->toDateTimeString(),
                    ],
                ]);
                
                $uploadedPhotos[] = $photo;
                
                // Dispatcher le job de traitement
                ProcessUploadedPhotoJob::dispatch($photo);
            }

            // Mettre à jour le statut de la tâche si nécessaire
            if ($task->status === Task::STATUS_WAITING) {
                $task->update(['status' => Task::STATUS_IN_PROGRESS]);
            }

            // Enregistrer les informations de contact si fournies
            if ($request->filled('contact_email') || $request->filled('contact_phone')) {
                $task->metadata = array_merge($task->metadata ?? [], [
                    'guest_contact' => [
                        'email' => $request->input('contact_email'),
                        'phone' => $request->input('contact_phone'),
                        'submitted_at' => now()->toDateTimeString(),
                    ],
                ]);
                $task->save();
            }

            // Logger l'activité
            Log::info('Photos téléchargées par un invité', [
                'task_id' => $task->id,
                'photos_count' => count($uploadedPhotos),
                'token' => $token,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Photos téléchargées avec succès. Elles sont en cours de traitement.',
                'photos_count' => count($uploadedPhotos),
                'photos' => collect($uploadedPhotos)->map(function ($photo) {
                    return [
                        'id' => $photo->id,
                        'filename' => $photo->filename,
                        'size' => $photo->metadata['size'] ?? null,
                    ];
                }),
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors du téléchargement des photos', [
                'task_id' => $task->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            // Nettoyer les fichiers déjà uploadés en cas d'erreur
            foreach ($uploadedPhotos as $photo) {
                Storage::disk('public')->delete($photo->path);
                $photo->delete();
            }

            throw ValidationException::withMessages([
                'photos' => ['Une erreur est survenue lors du téléchargement. Veuillez réessayer.'],
            ]);
        }
    }

    /**
     * Vérifier le statut d'un token.
     */
    public function checkToken($token)
    {
        $task = Task::where('guest_token', $token)->first();

        if (!$task) {
            return response()->json([
                'valid' => false,
                'message' => 'Lien invalide.',
            ], 404);
        }

        if (!$task->isGuestTokenValid()) {
            return response()->json([
                'valid' => false,
                'message' => 'Le lien a expiré.',
            ], 403);
        }

        return response()->json([
            'valid' => true,
            'task' => [
                'title' => $task->title,
                'photos_count' => $task->photos()->count(),
            ],
        ]);
    }
}