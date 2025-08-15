<?php

namespace App\Http\Controllers;

use App\Models\Task;
use App\Models\Photo;
use App\Jobs\ProcessUploadedPhotoJob;
use Illuminate\Http\Request;
use Inertia\Inertia;

class TaskController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $tasks = Task::with(['user', 'photos'])
            ->when($request->input('search'), function ($query, $search) {
                $query->where('title', 'like', "%{$search}%");
            })
            ->when($request->input('status'), function ($query, $status) {
                $query->where('status', $status);
            })
            ->latest()
            ->paginate(15)
            ->withQueryString();

        return Inertia::render('Tasks/Index', [
            'tasks' => $tasks,
            'filters' => $request->only(['search', 'status']),
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
        ]);

        $task = $request->user()->tasks()->create($validated);

        return redirect()->route('tasks.show', $task)
            ->with('success', 'Tâche créée avec succès.');
    }

    /**
     * Display the specified resource.
     */
    public function show(Task $task)
    {
        $task->load(['photos.measurements', 'subtasks', 'measurements']);

        return Inertia::render('Tasks/Show', [
            'task' => $task,
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Task $task)
    {
        return Inertia::render('Tasks/Edit', [
            'task' => $task,
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
     * Générer un lien invité pour la tâche.
     */
    public function generateGuestLink(Task $task)
    {
        $task->generateGuestToken();
        $task->update(['status' => Task::STATUS_WAITING]);

        return response()->json([
            'url' => $task->getGuestUrl(),
            'token' => $task->guest_token,
            'expires' => $task->guest_expires->format('Y-m-d H:i:s'),
        ]);
    }

    /**
     * Retraiter une photo.
     */
    public function reprocessPhoto(Task $task, Photo $photo)
    {
        if ($photo->task_id !== $task->id) {
            abort(403);
        }

        // Réinitialiser le statut de traitement
        $photo->update(['processed' => false]);

        // Redispatcher le job de traitement
        ProcessUploadedPhotoJob::dispatch($photo);

        return response()->json([
            'success' => true,
            'message' => 'Photo en cours de retraitement.',
        ]);
    }
}