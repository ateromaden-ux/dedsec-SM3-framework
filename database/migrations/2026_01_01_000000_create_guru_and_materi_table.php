<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasTable('guru')) {
            Schema::create('guru', function (Blueprint $table) {
                $table->id('id_guru');
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('nama_guru');
                $table->string('nip')->nullable()->unique();
                $table->string('mata_pelajaran')->nullable();
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('materi_belajar')) {
            Schema::create('materi_belajar', function (Blueprint $table) {
                $table->id('id_materi');
                $table->string('judul_materi');
                $table->text('deskripsi')->nullable();
                $table->timestamps();
            });
        }

    }

    public function down(): void
    {
        Schema::dropIfExists('materi_belajar');
        Schema::dropIfExists('guru');
    }
};
