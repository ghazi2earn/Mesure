<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Measurement extends Model
{
    protected $fillable = [
        'task_id',
        'photo_id',
        'subtask_id',
        'type',
        'value_mm',
        'value_mm2',
        'value_m2',
        'points',
        'mask_path',
        'annotated_path',
        'confidence',
        'processor_version',
    ];

    protected function casts(): array
    {
        return [
            'points' => 'array',
            'confidence' => 'float',
            'value_mm' => 'float',
            'value_mm2' => 'float',
            'value_m2' => 'float',
        ];
    }

    /**
     * Relation avec la tâche
     */
    public function task(): BelongsTo
    {
        return $this->belongsTo(Task::class);
    }

    /**
     * Relation avec la photo
     */
    public function photo(): BelongsTo
    {
        return $this->belongsTo(Photo::class);
    }

    /**
     * Relation avec la sous-tâche
     */
    public function subtask(): BelongsTo
    {
        return $this->belongsTo(Subtask::class);
    }
}
