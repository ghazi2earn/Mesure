<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Exécuter les migrations.
     */
    public function up(): void
    {
        Schema::create('notifications_log', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->nullable()->constrained()->onDelete('set null');
            $table->string('type');
            $table->json('payload');
            $table->datetime('sent_at');
            $table->enum('status', ['sent', 'error']);
            $table->timestamps();
            
            $table->index(['task_id', 'status']);
            $table->index('type');
        });
    }

    /**
     * Annuler les migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notifications_log');
    }
};