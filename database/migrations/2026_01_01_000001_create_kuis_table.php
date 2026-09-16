<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('kuis', function (Blueprint $table) {
            $table->id('id_kuis');
            $table->unsignedBigInteger('id_guru');
            $table->unsignedBigInteger('id_materi');
            $table->string('judul_kuis');
            $table->text('deskripsi')->nullable();
            $table->unsignedInteger('jumlah_soal')->default(0);
            $table->unsignedTinyInteger('batas_lulus')->default(70);
            $table->enum('status', ['draft', 'published'])->default('draft');
            $table->timestamps();

            $table->foreign('id_guru')
                ->references('id_guru')->on('guru')
                ->cascadeOnDelete();

            $table->foreign('id_materi')
                ->references('id_materi')->on('materi_belajar')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kuis');
    }
};
