<?php

namespace App\Jobs;

use App\Models\Photo;
use App\Models\Measurement;
use App\Models\NotificationLog;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Exception;

class ProcessUploadedPhotoJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $photo;

    /**
     * Nombre de tentatives maximales.
     */
    public $tries = 3;

    /**
     * Délai d'attente en secondes.
     */
    public $timeout = 120;

    /**
     * Créer une nouvelle instance du job.
     */
    public function __construct(Photo $photo)
    {
        $this->photo = $photo;
    }

    /**
     * Exécuter le job.
     */
    public function handle(): void
    {
        try {
            // Vérifier que la photo existe dans le disque public
            if (!Storage::disk('public')->exists($this->photo->path)) {
                throw new Exception("Le fichier photo n'existe pas: {$this->photo->path}");
            }

            // Vérifier si le service IA est configuré
            $aiServiceUrl = config('services.ai.url');
            
            if (!$aiServiceUrl || $aiServiceUrl === 'http://localhost:8000') {
                // Mode simulation - marquer comme traité sans appel au service IA
                $this->photo->metadata = array_merge($this->photo->metadata ?? [], [
                    'simulation_mode' => true,
                    'processed_at' => now()->toDateTimeString(),
                ]);
                $this->photo->processed = true;
                $this->photo->save();

                Log::info("Photo traitée en mode simulation", [
                    'photo_id' => $this->photo->id,
                    'mode' => 'simulation',
                ]);

                return;
            }

            // Préparer le fichier pour l'envoi
            $filePath = Storage::disk('public')->path($this->photo->path);
            
            // Appeler le service IA
            $response = Http::timeout(60)
                ->attach('file', file_get_contents($filePath), $this->photo->filename)
                ->post($aiServiceUrl . '/analyze', [
                    'metadata' => json_encode([
                        'expect_marker' => 'A4',
                        'photo_id' => $this->photo->id,
                        'task_id' => $this->photo->task_id,
                    ])
                ]);

            if (!$response->successful()) {
                throw new Exception("Erreur du service IA: " . $response->body());
            }

            $data = $response->json();

            // Traiter la réponse
            if ($data['success']) {
                // Sauvegarder les informations du marqueur
                if ($data['marker']) {
                    $this->photo->metadata = array_merge($this->photo->metadata ?? [], [
                        'marker' => $data['marker'],
                        'pixels_per_mm' => $data['pixels_per_mm'],
                    ]);
                }

                // Créer les mesures préliminaires
                foreach ($data['preliminary_measurements'] as $measurement) {
                    Measurement::create([
                        'task_id' => $this->photo->task_id,
                        'photo_id' => $this->photo->id,
                        'type' => $measurement['type'],
                        'value_mm' => $measurement['value_mm'] ?? null,
                        'value_mm2' => $measurement['value_mm2'] ?? null,
                        'value_m2' => $measurement['value_m2'] ?? null,
                        'points' => $data['suggestions'][$measurement['id']]['mask_poly'] ?? [],
                        'confidence' => $measurement['confidence'],
                        'processor_version' => '1.0.0',
                        'annotated_path' => $data['annotated_image_url'],
                    ]);
                }

                // Marquer la photo comme traitée
                $this->photo->processed = true;
                $this->photo->save();

                // Notifier l'administrateur
                $this->notifyAdmin($data);

                Log::info("Photo traitée avec succès", [
                    'photo_id' => $this->photo->id,
                    'marker_detected' => isset($data['marker']),
                    'measurements_count' => count($data['preliminary_measurements']),
                ]);
            } else {
                // Enregistrer l'échec mais marquer comme traité
                $this->photo->metadata = array_merge($this->photo->metadata ?? [], [
                    'processing_error' => $data['message'],
                ]);
                $this->photo->processed = true;
                $this->photo->save();

                Log::warning("Échec du traitement de la photo", [
                    'photo_id' => $this->photo->id,
                    'message' => $data['message'],
                ]);
            }
        } catch (Exception $e) {
            Log::error("Erreur lors du traitement de la photo", [
                'photo_id' => $this->photo->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            // Réessayer le job
            if ($this->attempts() < $this->tries) {
                $this->release(60); // Réessayer dans 60 secondes
            } else {
                // Marquer comme échoué après toutes les tentatives
                $this->photo->metadata = array_merge($this->photo->metadata ?? [], [
                    'processing_error' => "Échec après {$this->tries} tentatives: " . $e->getMessage(),
                ]);
                $this->photo->save();

                $this->fail($e);
            }
        }
    }

    /**
     * Notifier l'administrateur du traitement.
     */
    protected function notifyAdmin(array $data): void
    {
        try {
            $task = $this->photo->task;
            
            // Créer un log de notification
            NotificationLog::create([
                'task_id' => $task->id,
                'type' => NotificationLog::TYPE_PUSH,
                'payload' => [
                    'subject' => "Photo traitée - Tâche: {$task->title}",
                    'message' => $data['success'] 
                        ? "Marqueur A4 détecté avec " . count($data['preliminary_measurements']) . " mesures suggérées."
                        : "Échec de la détection: " . $data['message'],
                    'photo_id' => $this->photo->id,
                    'data' => $data,
                ],
                'sent_at' => now(),
                'status' => NotificationLog::STATUS_SENT,
            ]);

            // Mettre à jour le statut de la tâche si nécessaire
            if ($task->status === 'en_attente' && $task->photos()->processed()->exists()) {
                $task->update(['status' => 'en_execution']);
            }
        } catch (Exception $e) {
            Log::error("Erreur lors de la notification", [
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Gérer l'échec du job.
     */
    public function failed(Exception $exception): void
    {
        Log::error("Job ProcessUploadedPhoto échoué définitivement", [
            'photo_id' => $this->photo->id,
            'error' => $exception->getMessage(),
        ]);

        // Créer un log de notification d'erreur
        NotificationLog::create([
            'task_id' => $this->photo->task_id,
            'type' => NotificationLog::TYPE_PUSH,
            'payload' => [
                'subject' => "Erreur de traitement photo",
                'message' => "Le traitement de la photo a échoué après plusieurs tentatives.",
                'photo_id' => $this->photo->id,
                'error' => $exception->getMessage(),
            ],
            'sent_at' => now(),
            'status' => NotificationLog::STATUS_ERROR,
        ]);
    }
}