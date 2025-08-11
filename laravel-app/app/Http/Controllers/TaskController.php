<?php

namespace App\Http\Controllers;

use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;

class TaskController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Task::with(['user', 'assignedUser'])
            ->withCount('photos')
            ->where('user_id', Auth::id());

        // Filtrer par statut si spécifié
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $tasks = $query->latest()->get();

        // Calculer les statistiques
        $stats = [
            'total_tasks' => Task::where('user_id', Auth::id())->count(),
            'pending_tasks' => Task::where('user_id', Auth::id())->where('status', 'en_attente')->count(),
            'active_tasks' => Task::where('user_id', Auth::id())->where('status', 'en_execution')->count(),
            'completed_tasks' => Task::where('user_id', Auth::id())->where('status', 'cloture')->count(),
        ];

        return Inertia::render('Dashboard', [
            'tasks' => $tasks,
            'stats' => $stats
        ]);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return Inertia::render('Tasks/Create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'assigned_to' => 'nullable|exists:users,id'
        ]);

        $task = Task::create([
            'title' => $validated['title'],
            'description' => $validated['description'],
            'user_id' => Auth::id(),
            'assigned_to' => $validated['assigned_to'],
            'status' => 'nouveau'
        ]);

        return redirect()->route('tasks.show', $task)
            ->with('success', 'Tâche créée avec succès.');
    }

    /**
     * Display the specified resource.
     */
    public function show(Task $task)
    {
        $task->load(['photos.measurements', 'subtasks', 'user', 'assignedUser']);

        return Inertia::render('Tasks/Show', [
            'task' => $task
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Task $task)
    {
        return Inertia::render('Tasks/Edit', [
            'task' => $task
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Task $task)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'status' => 'required|in:nouveau,en_attente,en_execution,cloture',
            'assigned_to' => 'nullable|exists:users,id'
        ]);

        $task->update($validated);

        return redirect()->route('tasks.show', $task)
            ->with('success', 'Tâche mise à jour avec succès.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Task $task)
    {
        $task->delete();

        return redirect()->route('tasks.index')
            ->with('success', 'Tâche supprimée avec succès.');
    }

    /**
     * Generate a guest link for the task
     */
    public function generateGuestLink(Task $task)
    {
        $token = Str::random(32);
        $expiresAt = now()->addDays(config('app.guest_token_expiry_days', 7));

        $task->update([
            'guest_token' => $token,
            'guest_expires' => $expiresAt,
            'status' => 'en_attente'
        ]);

        $guestUrl = url("/guest/{$token}");

        return response()->json([
            'success' => true,
            'guest_url' => $guestUrl,
            'expires_at' => $expiresAt->toISOString()
        ]);
    }
}
