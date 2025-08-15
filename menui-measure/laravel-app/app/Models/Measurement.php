<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Measurement extends Model
{
    use HasFactory;

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

    protected $casts = [
        'points' => 'array',
        'value_mm' => 'float',
        'value_mm2' => 'float',
        'value_m2' => 'float',
        'confidence' => 'float',
    ];

    /**
     * Les types de mesure possibles.
     */
    const TYPE_LENGTH = 'length';
    const TYPE_AREA = 'area';

    /**
     * Obtenir la tâche associée.
     */
    public function task()
    {
        return $this->belongsTo(Task::class);
    }

    /**
     * Obtenir la photo associée.
     */
    public function photo()
    {
        return $this->belongsTo(Photo::class);
    }

    /**
     * Obtenir la sous-tâche associée.
     */
    public function subtask()
    {
        return $this->belongsTo(Subtask::class);
    }

    /**
     * Obtenir la valeur formatée selon le type.
     */
    public function getFormattedValueAttribute(): string
    {
        if ($this->type === self::TYPE_LENGTH) {
            return number_format($this->value_mm / 1000, 2) . ' m';
        } else {
            return number_format($this->value_m2, 2) . ' m²';
        }
    }

    /**
     * Obtenir la valeur en unité appropriée.
     */
    public function getValueInUnitAttribute(): float
    {
        if ($this->type === self::TYPE_LENGTH) {
            return $this->value_mm / 1000; // Convertir en mètres
        } else {
            return $this->value_m2;
        }
    }

    /**
     * Scopes
     */
    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeHighConfidence($query, $threshold = 0.8)
    {
        return $query->where('confidence', '>=', $threshold);
    }
}