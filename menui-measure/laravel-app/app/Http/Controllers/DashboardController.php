<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\Task;

class DashboardController extends Controller
{
    /**
     * Afficher le tableau de bord.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        $tasks = Task::with(['user', 'assignedUser'])
            ->when(!$user->isAdmin(), function ($query) use ($user) {
                $query->where('user_id', $user->id)
                    ->orWhere('assigned_to', $user->id);
            })
            ->latest()
            ->paginate(10);

        $stats = [
            'total' => Task::when(!$user->isAdmin(), function ($query) use ($user) {
                $query->where('user_id', $user->id);
            })->count(),
            'nouveau' => Task::when(!$user->isAdmin(), function ($query) use ($user) {
                $query->where('user_id', $user->id);
            })->where('status', 'nouveau')->count(),
            'en_attente' => Task::when(!$user->isAdmin(), function ($query) use ($user) {
                $query->where('user_id', $user->id);
            })->where('status', 'en_attente')->count(),
            'en_execution' => Task::when(!$user->isAdmin(), function ($query) use ($user) {
                $query->where('user_id', $user->id);
            })->where('status', 'en_execution')->count(),
            'cloture' => Task::when(!$user->isAdmin(), function ($query) use ($user) {
                $query->where('user_id', $user->id);
            })->where('status', 'cloture')->count(),
        ];

        return Inertia::render('Dashboard', [
            'tasks' => $tasks,
            'stats' => $stats,
        ]);
    }
}