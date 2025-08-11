<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('measurements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained('tasks');
            $table->foreignId('photo_id')->nullable()->constrained('photos');
            $table->foreignId('subtask_id')->nullable()->constrained('subtasks');
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
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('measurements');
    }
};
