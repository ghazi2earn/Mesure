<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Photo extends Model
{
    use HasFactory;

    protected $fillable = [
        'task_id',
        'path',
        'exif',
        'width_px',
        'height_px',
        'processed',
        'metadata',
    ];

    protected $casts = [
        'exif' => 'array',
        'metadata' => 'array',
        'processed' => 'boolean',
    ];

    /**
     * Obtenir la tâche associée à la photo.
     */
    public function task()
    {
        return $this->belongsTo(Task::class);
    }

    /**
     * Obtenir les mesures associées à cette photo.
     */
    public function measurements()
    {
        return $this->hasMany(Measurement::class);
    }

    /**
     * Obtenir l'URL complète de la photo.
     */
    public function getUrlAttribute(): string
    {
        return Storage::url($this->path);
    }

    /**
     * Obtenir le nom du fichier.
     */
    public function getFilenameAttribute(): string
    {
        return basename($this->path);
    }

    /**
     * Marquer la photo comme traitée.
     */
    public function markAsProcessed(): void
    {
        $this->update(['processed' => true]);
    }

    /**
     * Vérifier si la photo a été traitée.
     */
    public function isProcessed(): bool
    {
        return $this->processed;
    }

    /**
     * Scopes
     */
    public function scopeProcessed($query)
    {
        return $query->where('processed', true);
    }

    public function scopeUnprocessed($query)
    {
        return $query->where('processed', false);
    }
}