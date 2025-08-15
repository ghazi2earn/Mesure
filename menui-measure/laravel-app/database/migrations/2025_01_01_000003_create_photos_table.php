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
        Schema::create('photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained()->onDelete('cascade');
            $table->string('path');
            $table->json('exif')->nullable();
            $table->integer('width_px');
            $table->integer('height_px');
            $table->boolean('processed')->default(false);
            $table->json('metadata')->nullable();
            $table->timestamps();
            
            $table->index(['task_id', 'processed']);
        });
    }

    /**
     * Annuler les migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('photos');
    }
};