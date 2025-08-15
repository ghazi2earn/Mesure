<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Task extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'status',
        'guest_token',
        'guest_expires',
        'user_id',
        'assigned_to',
    ];

    protected $casts = [
        'guest_expires' => 'datetime',
    ];

    /**
     * Les statuts possibles d'une tâche.
     */
    const STATUS_NEW = 'nouveau';
    const STATUS_WAITING = 'en_attente';
    const STATUS_IN_PROGRESS = 'en_execution';
    const STATUS_CLOSED = 'cloture';

    /**
     * Obtenir l'utilisateur qui a créé la tâche.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Obtenir l'utilisateur assigné à la tâche.
     */
    public function assignedUser()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    /**
     * Obtenir les photos de la tâche.
     */
    public function photos()
    {
        return $this->hasMany(Photo::class);
    }

    /**
     * Obtenir les sous-tâches.
     */
    public function subtasks()
    {
        return $this->hasMany(Subtask::class);
    }

    /**
     * Obtenir les mesures de la tâche.
     */
    public function measurements()
    {
        return $this->hasMany(Measurement::class);
    }

    /**
     * Obtenir les logs de notifications.
     */
    public function notificationLogs()
    {
        return $this->hasMany(NotificationLog::class);
    }

    /**
     * Générer un token d'invité unique.
     */
    public function generateGuestToken(): string
    {
        $this->guest_token = Str::random(32);
        $this->guest_expires = now()->addDays(config('app.guest_token_expiry_days', 7));
        $this->save();

        return $this->guest_token;
    }

    /**
     * Vérifier si le token d'invité est valide.
     */
    public function isGuestTokenValid(): bool
    {
        return $this->guest_token && 
               $this->guest_expires && 
               $this->guest_expires->isFuture();
    }

    /**
     * Obtenir l'URL publique pour les invités.
     */
    public function getGuestUrl(): string
    {
        return route('guest.upload', ['token' => $this->guest_token]);
    }

    /**
     * Scopes
     */
    public function scopeByStatus($query, $status)
    {
        return $query->where('status', $status);
    }

    public function scopeWithValidGuestToken($query)
    {
        return $query->whereNotNull('guest_token')
                     ->where('guest_expires', '>', now());
    }
}