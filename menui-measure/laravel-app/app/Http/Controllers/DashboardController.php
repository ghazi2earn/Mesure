<?php

namespace App\Http\Controllers;

use App\Models\Task;
use App\Models\Photo;
use App\Models\NotificationLog;
use Illuminate\Http\Request;
use Inertia\Inertia;

class DashboardController extends Controller
{
    /**
     * Afficher le tableau de bord.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Statistiques générales
        $stats = [
            'total_tasks' => $user->tasks()->count(),
            'pending_tasks' => $user->tasks()->where('status', Task::STATUS_WAITING)->count(),
            'in_progress_tasks' => $user->tasks()->where('status', Task::STATUS_IN_PROGRESS)->count(),
            'completed_tasks' => $user->tasks()->where('status', Task::STATUS_CLOSED)->count(),
            'total_photos' => Photo::whereHas('task', function($query) use ($user) {
                $query->where('user_id', $user->id);
            })->count(),
            'processed_photos' => Photo::whereHas('task', function($query) use ($user) {
                $query->where('user_id', $user->id);
            })->where('processed', true)->count(),
        ];

        // Tâches récentes
        $recentTasks = $user->tasks()
            ->with(['photos' => function($query) {
                $query->latest()->limit(3);
            }])
            ->latest()
            ->limit(5)
            ->get()
            ->map(function($task) {
                return [
                    'id' => $task->id,
                    'title' => $task->title,
                    'status' => $task->status,
                    'created_at' => $task->created_at,
                    'photos_count' => $task->photos()->count(),
                    'processed_photos_count' => $task->photos()->where('processed', true)->count(),
                ];
            });

        // Notifications récentes
        $recentNotifications = NotificationLog::whereHas('task', function($query) use ($user) {
                $query->where('user_id', $user->id);
            })
            ->with('task:id,title')
            ->latest('sent_at')
            ->limit(10)
            ->get()
            ->map(function($notification) {
                return [
                    'id' => $notification->id,
                    'type' => $notification->type,
                    'task_title' => $notification->task->title ?? 'Tâche supprimée',
                    'payload' => $notification->payload,
                    'sent_at' => $notification->sent_at,
                    'status' => $notification->status,
                ];
            });

        // Activité récente (photos uploadées aujourd'hui)
        $todayPhotos = Photo::whereHas('task', function($query) use ($user) {
                $query->where('user_id', $user->id);
            })
            ->whereDate('created_at', today())
            ->with('task:id,title')
            ->latest()
            ->limit(5)
            ->get()
            ->map(function($photo) {
                return [
                    'id' => $photo->id,
                    'task_title' => $photo->task->title ?? 'Tâche supprimée',
                    'filename' => $photo->filename,
                    'processed' => $photo->processed,
                    'created_at' => $photo->created_at,
                    'has_measurements' => $photo->measurements()->exists(),
                ];
            });

        return Inertia::render('Dashboard', [
            'stats' => $stats,
            'recentTasks' => $recentTasks,
            'recentNotifications' => $recentNotifications,
            'todayPhotos' => $todayPhotos,
        ]);
    }

    /**
     * Obtenir les notifications en temps réel.
     */
    public function notifications(Request $request)
    {
        $user = $request->user();
        
        $notifications = NotificationLog::whereHas('task', function($query) use ($user) {
                $query->where('user_id', $user->id);
            })
            ->with('task:id,title')
            ->when($request->input('since'), function($query, $since) {
                $query->where('sent_at', '>', $since);
            })
            ->latest('sent_at')
            ->limit(20)
            ->get()
            ->map(function($notification) {
                return [
                    'id' => $notification->id,
                    'type' => $notification->type,
                    'task_id' => $notification->task_id,
                    'task_title' => $notification->task->title ?? 'Tâche supprimée',
                    'payload' => $notification->payload,
                    'sent_at' => $notification->sent_at,
                    'status' => $notification->status,
                ];
            });

        return response()->json([
            'notifications' => $notifications,
            'timestamp' => now()->toISOString(),
        ]);
    }
}