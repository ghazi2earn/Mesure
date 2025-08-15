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
        Schema::create('measurements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained()->onDelete('cascade');
            $table->foreignId('photo_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('subtask_id')->nullable()->constrained()->onDelete('set null');
            $table->enum('type', ['length', 'area']);
            $table->float('value_mm')->nullable();
            $table->float('value_mm2')->nullable();
            $table->float('value_m2')->nullable();
            $table->json('points');
            $table->string('mask_path')->nullable();
            $table->string('annotated_path')->nullable();
            $table->float('confidence');
            $table->string('processor_version');
            $table->timestamps();
            
            $table->index(['task_id', 'type']);
            $table->index('photo_id');
        });
    }

    /**
     * Annuler les migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('measurements');
    }
};