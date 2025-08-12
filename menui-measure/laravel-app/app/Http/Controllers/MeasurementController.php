<?php

namespace App\Http\Controllers;

use App\Models\Measurement;
use App\Models\Task;
use App\Models\Photo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class MeasurementController extends Controller
{
    /**
     * Store a newly created measurement.
     */
    public function store(Request $request, Task $task, Photo $photo)
    {
        $validated = $request->validate([
            'type' => 'required|in:length,area',
            'points' => 'required|array',
            'subtask_id' => 'nullable|exists:subtasks,id',
        ]);

        // Vérifier que la photo appartient à la tâche
        if ($photo->task_id !== $task->id) {
            abort(403);
        }

        // Récupérer les informations de pixels_per_mm depuis les métadonnées de la photo
        $pixelsPerMm = $photo->metadata['pixels_per_mm'] ?? null;

        if (!$pixelsPerMm) {
            return response()->json([
                'error' => 'Impossible de calculer la mesure. Le marqueur A4 n\'a pas été détecté.',
            ], 422);
        }

        // Calculer les valeurs selon le type
        $measurementData = [
            'task_id' => $task->id,
            'photo_id' => $photo->id,
            'subtask_id' => $validated['subtask_id'] ?? null,
            'type' => $validated['type'],
            'points' => $validated['points'],
            'confidence' => 0.95, // Confiance élevée car c'est une mesure manuelle
            'processor_version' => '1.0.0',
        ];

        if ($validated['type'] === 'length') {
            // Calculer la distance entre deux points
            $p1 = $validated['points'][0];
            $p2 = $validated['points'][1];
            $distancePx = sqrt(pow($p2['x'] - $p1['x'], 2) + pow($p2['y'] - $p1['y'], 2));
            $distanceMm = $distancePx / $pixelsPerMm;
            
            $measurementData['value_mm'] = $distanceMm;
        } else {
            // Calculer l'aire du polygone
            $areaPx = $this->calculatePolygonArea($validated['points']);
            $areaMm2 = $areaPx / ($pixelsPerMm * $pixelsPerMm);
            $areaM2 = $areaMm2 / 1000000;
            
            $measurementData['value_mm2'] = $areaMm2;
            $measurementData['value_m2'] = $areaM2;
        }

        $measurement = Measurement::create($measurementData);

        // Si une sous-tâche est liée, la mettre à jour
        if ($measurement->subtask) {
            $value = $validated['type'] === 'length' 
                ? $measurement->value_mm / 1000 // Convertir en mètres
                : $measurement->value_m2;
                
            $measurement->subtask->markAsCompleted($value);
        }

        return response()->json([
            'measurement' => $measurement->load('subtask'),
            'formatted_value' => $measurement->formatted_value,
        ]);
    }

    /**
     * Display the specified measurement.
     */
    public function show(Measurement $measurement)
    {
        return response()->json([
            'measurement' => $measurement->load(['task', 'photo', 'subtask']),
        ]);
    }

    /**
     * Update the specified measurement.
     */
    public function update(Request $request, Measurement $measurement)
    {
        $validated = $request->validate([
            'points' => 'sometimes|array',
            'confidence' => 'sometimes|numeric|min:0|max:1',
        ]);

        $measurement->update($validated);

        return response()->json([
            'measurement' => $measurement,
        ]);
    }

    /**
     * Remove the specified measurement.
     */
    public function destroy(Measurement $measurement)
    {
        $measurement->delete();

        return response()->json([
            'message' => 'Mesure supprimée avec succès.',
        ]);
    }

    /**
     * Calculer l'aire d'un polygone.
     */
    private function calculatePolygonArea(array $points): float
    {
        $area = 0;
        $n = count($points);

        for ($i = 0; $i < $n; $i++) {
            $j = ($i + 1) % $n;
            $area += $points[$i]['x'] * $points[$j]['y'];
            $area -= $points[$j]['x'] * $points[$i]['y'];
        }

        return abs($area / 2);
    }
}