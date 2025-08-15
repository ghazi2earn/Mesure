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
        Schema::create('subtasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained()->onDelete('cascade');
            $table->string('title');
            $table->enum('type', ['longueur', 'surface']);
            $table->float('value')->nullable();
            $table->enum('unit', ['m', 'm2']);
            $table->enum('status', ['nouveau', 'en_cours', 'termine'])->default('nouveau');
            $table->timestamps();
            
            $table->index(['task_id', 'status']);
        });
    }

    /**
     * Annuler les migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('subtasks');
    }
};