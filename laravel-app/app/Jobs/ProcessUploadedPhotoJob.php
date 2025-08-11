<?php

namespace App\Jobs;

use App\Models\Photo;
use App\Models\Measurement;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class ProcessUploadedPhotoJob implements ShouldQueue
{
    use Queueable;

    protected $photo;

    /**
     * Create a new job instance.
     */
    public function __construct(Photo $photo)
    {
        $this->photo = $photo;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        try {
            Log::info("Traitement de la photo {$this->photo->id}");

            // Préparer le fichier pour l'envoi au service AI
            $photoPath = storage_path('app/' . $this->photo->path);
            
            if (!file_exists($photoPath)) {
                Log::error("Fichier photo non trouvé: {$photoPath}");
                return;
            }

            // Préparer les métadonnées
            $metadata = [
                'expect_marker' => 'A4',
                'photo_id' => $this->photo->id,
                'task_id' => $this->photo->task_id
            ];

            // Appeler le service AI
            $response = Http::attach(
                'file',
                file_get_contents($photoPath),
                basename($this->photo->path)
            )->post(config('app.ai_service_url') . '/analyze', [
                'metadata' => json_encode($metadata)
            ]);

            if ($response->successful()) {
                $result = $response->json();
                
                // Sauvegarder les résultats
                if (isset($result['marker']) && $result['marker']) {
                    // Mettre à jour les métadonnées de la photo
                    $this->photo->update([
                        'processed' => true,
                        'metadata' => array_merge($this->photo->metadata ?? [], [
                            'marker_detected' => true,
                            'pixels_per_mm' => $result['pixels_per_mm'],
                            'marker_corners' => $result['marker']['corners']
                        ])
                    ]);

                    // Créer les mesures préliminaires
                    if (isset($result['preliminary_measurements'])) {
                        foreach ($result['preliminary_measurements'] as $measurement) {
                            Measurement::create([
                                'task_id' => $this->photo->task_id,
                                'photo_id' => $this->photo->id,
                                'type' => $measurement['type'],
                                'value_mm2' => $measurement['value_mm2'] ?? null,
                                'confidence' => $measurement['confidence'],
                                'processor_version' => '1.0.0',
                                'points' => json_encode([]),
                                'annotated_path' => $result['annotated_image_url'] ?? null
                            ]);
                        }
                    }
                } else {
                    // Aucun marqueur détecté
                    $this->photo->update([
                        'processed' => true,
                        'metadata' => array_merge($this->photo->metadata ?? [], [
                            'marker_detected' => false,
                            'error' => 'Aucun marqueur A4 détecté'
                        ])
                    ]);
                }

                Log::info("Photo {$this->photo->id} traitée avec succès");
            } else {
                Log::error("Erreur du service AI: " . $response->body());
                
                $this->photo->update([
                    'metadata' => array_merge($this->photo->metadata ?? [], [
                        'processing_error' => $response->body()
                    ])
                ]);
            }

        } catch (\Exception $e) {
            Log::error("Erreur lors du traitement de la photo {$this->photo->id}: " . $e->getMessage());
            
            $this->photo->update([
                'metadata' => array_merge($this->photo->metadata ?? [], [
                    'processing_error' => $e->getMessage()
                ])
            ]);
        }
    }
}
