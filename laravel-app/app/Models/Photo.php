<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Photo extends Model
{
    protected $fillable = [
        'task_id',
        'path',
        'exif',
        'width_px',
        'height_px',
        'processed',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'exif' => 'array',
            'metadata' => 'array',
            'processed' => 'boolean',
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
