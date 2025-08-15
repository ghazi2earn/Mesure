<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subtask extends Model
{
    use HasFactory;

    protected $fillable = [
        'task_id',
        'title',
        'type',
        'value',
        'unit',
        'status',
    ];

    protected $casts = [
        'value' => 'float',
    ];

    /**
     * Les types de sous-tâche possibles.
     */
    const TYPE_LENGTH = 'longueur';
    const TYPE_AREA = 'surface';

    /**
     * Les unités possibles.
     */
    const UNIT_METER = 'm';
    const UNIT_SQUARE_METER = 'm2';

    /**
     * Les statuts possibles.
     */
    const STATUS_NEW = 'nouveau';
    const STATUS_IN_PROGRESS = 'en_cours';
    const STATUS_COMPLETED = 'termine';

    /**
     * Obtenir la tâche parente.
     */
    public function task()
    {
        return $this->belongsTo(Task::class);
    }

    /**
     * Obtenir les mesures associées.
     */
    public function measurements()
    {
        return $this->hasMany(Measurement::class);
    }

    /**
     * Obtenir la valeur formatée avec l'unité.
     */
    public function getFormattedValueAttribute(): string
    {
        if ($this->value === null) {
            return 'Non mesuré';
        }

        return number_format($this->value, 2) . ' ' . $this->unit;
    }

    /**
     * Marquer la sous-tâche comme terminée.
     */
    public function markAsCompleted(float $value): void
    {
        $this->update([
            'value' => $value,
            'status' => self::STATUS_COMPLETED,
        ]);
    }

    /**
     * Vérifier si la sous-tâche est terminée.
     */
    public function isCompleted(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }

    /**
     * Scopes
     */
    public function scopeByStatus($query, $status)
    {
        return $query->where('status', $status);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }
}