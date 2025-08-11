<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationLog extends Model
{
    use HasFactory;

    protected $table = 'notifications_log';

    protected $fillable = [
        'task_id',
        'type',
        'payload',
        'sent_at',
        'status',
    ];

    protected $casts = [
        'payload' => 'array',
        'sent_at' => 'datetime',
    ];

    /**
     * Les statuts possibles.
     */
    const STATUS_SENT = 'sent';
    const STATUS_ERROR = 'error';

    /**
     * Les types de notification.
     */
    const TYPE_EMAIL = 'email';
    const TYPE_SMS = 'sms';
    const TYPE_WHATSAPP = 'whatsapp';
    const TYPE_PUSH = 'push';

    /**
     * Obtenir la tâche associée.
     */
    public function task()
    {
        return $this->belongsTo(Task::class);
    }

    /**
     * Vérifier si la notification a été envoyée avec succès.
     */
    public function isSuccessful(): bool
    {
        return $this->status === self::STATUS_SENT;
    }

    /**
     * Scopes
     */
    public function scopeSuccessful($query)
    {
        return $query->where('status', self::STATUS_SENT);
    }

    public function scopeFailed($query)
    {
        return $query->where('status', self::STATUS_ERROR);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeRecent($query, $days = 7)
    {
        return $query->where('sent_at', '>=', now()->subDays($days));
    }
}