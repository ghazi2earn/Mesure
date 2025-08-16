<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Task;
use App\Models\Photo;
use App\Models\NotificationLog;

class GenerateDemoData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'demo:generate';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Générer des données de démonstration pour le dashboard';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Création de données de démonstration...');

        // Récupérer le premier utilisateur
        $user = User::first();
        if (!$user) {
            $this->error('Aucun utilisateur trouvé. Veuillez créer un utilisateur d\'abord.');
            return 1;
        }

        // Récupérer ou créer quelques tâches
        $task = $user->tasks()->first();
        if (!$task) {
            $task = $user->tasks()->create([
                'title' => 'Tâche de démonstration',
                'description' => 'Une tâche créée pour tester le dashboard',
                'status' => 'en_execution',
            ]);
            $this->info("Tâche créée: {$task->title}");
        }

        // Créer quelques notifications de test
        $notifications = [
            [
                'type' => NotificationLog::TYPE_PUSH,
                'payload' => [
                    'subject' => 'Photo traitée avec succès',
                    'message' => 'Marqueur A4 détecté avec 3 mesures suggérées.',
                ],
                'status' => NotificationLog::STATUS_SENT,
            ],
            [
                'type' => NotificationLog::TYPE_EMAIL,
                'payload' => [
                    'subject' => 'Nouvelle photo uploadée',
                    'message' => 'Une photo a été uploadée par un invité et est en cours de traitement.',
                ],
                'status' => NotificationLog::STATUS_SENT,
            ],
            [
                'type' => NotificationLog::TYPE_PUSH,
                'payload' => [
                    'subject' => 'Échec de traitement',
                    'message' => 'Impossible de détecter le marqueur A4 sur la photo.',
                ],
                'status' => NotificationLog::STATUS_ERROR,
            ],
            [
                'type' => NotificationLog::TYPE_PUSH,
                'payload' => [
                    'subject' => 'Traitement terminé',
                    'message' => 'Toutes les photos de la tâche ont été traitées avec succès.',
                ],
                'status' => NotificationLog::STATUS_SENT,
            ],
        ];

        foreach ($notifications as $notifData) {
            NotificationLog::create([
                'task_id' => $task->id,
                'type' => $notifData['type'],
                'payload' => $notifData['payload'],
                'sent_at' => now()->subMinutes(rand(1, 60)),
                'status' => $notifData['status'],
            ]);
        }

        $this->info('✅ ' . count($notifications) . ' notifications créées avec succès!');

        // Créer quelques photos de test si nécessaire
        $photosCount = $task->photos()->count();
        if ($photosCount < 3) {
            for ($i = $photosCount; $i < 3; $i++) {
                Photo::create([
                    'task_id' => $task->id,
                    'path' => "photos/{$task->id}/demo_photo_{$i}.jpg",
                    'width_px' => 1920,
                    'height_px' => 1080,
                    'processed' => rand(0, 1) === 1,
                    'metadata' => [
                        'original_name' => "demo_photo_{$i}.jpg",
                        'mime_type' => 'image/jpeg',
                        'size' => rand(500000, 2000000),
                        'uploaded_by' => 'guest',
                        'uploaded_at' => now()->subHours(rand(1, 24))->toDateTimeString(),
                    ],
                ]);
            }
            $this->info('✅ Photos de démonstration créées!');
        }

        // Créer quelques tâches supplémentaires pour les statistiques
        if ($user->tasks()->count() < 5) {
            $statuses = ['nouveau', 'en_attente', 'en_execution', 'cloture'];
            for ($i = 1; $i < 5; $i++) {
                $user->tasks()->create([
                    'title' => "Tâche de test #{$i}",
                    'description' => "Description de la tâche de test numéro {$i}",
                    'status' => $statuses[array_rand($statuses)],
                ]);
            }
            $this->info('✅ Tâches de test créées pour les statistiques!');
        }

        $this->info('🎉 Données de démonstration créées avec succès!');
        $this->info('Vous pouvez maintenant tester le dashboard à l\'adresse: /dashboard');

        return 0;
    }
}
