<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('pilihan_jawaban', function (Blueprint $table) {
            $table->id('id_pilihan');
            $table->unsignedBigInteger('id_soal');
            $table->char('label_pilihan', 1);
            $table->text('isi_pilihan');
            $table->boolean('is_benar')->default(false);
            $table->text('penjelasan');
            $table->timestamps();

            $table->foreign('id_soal')
                ->references('id_soal')->on('soal')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pilihan_jawaban');
    }
};
