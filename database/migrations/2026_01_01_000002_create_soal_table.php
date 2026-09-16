<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('soal', function (Blueprint $table) {
            $table->id('id_soal');
            $table->unsignedBigInteger('id_kuis');
            $table->text('pertanyaan');
            $table->unsignedInteger('poin')->default(10);
            $table->unsignedInteger('urutan');
            $table->timestamps();

            $table->foreign('id_kuis')
                ->references('id_kuis')->on('kuis')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('soal');
    }
};
