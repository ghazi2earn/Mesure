<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Subtask extends Model
{
    protected $fillable = [
        'task_id',
        'title',
        'type',
        'value',
        'unit',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'value' => 'float',
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
     * Relation avec les mesures
     */
    public function measurements(): HasMany
    {
        return $this->hasMany(Measurement::class);
    }
}
