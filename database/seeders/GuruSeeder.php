<?php

namespace Database\Seeders;

use App\Models\Guru;
use App\Models\MateriBelajar;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class GuruSeeder extends Seeder
{
    public function run(): void
    {
        // Buat akun guru
        $guru = Guru::firstOrCreate(
            ['email' => 'guru@sekolah.id'],
            ['password' => Hash::make('password')]
        );

        // Buat beberapa materi belajar contoh (level_materi: int, e.g. 1=Dasar, 2=Menengah)
        $materiList = [
            ['id_guru' => $guru->id_guru, 'kategori' => 'Web', 'level_materi' => 1, 'judul_materi' => 'HTML & CSS Dasar',               'deskripsi' => 'Pengenalan struktur halaman web.'],
            ['id_guru' => $guru->id_guru, 'kategori' => 'Web', 'level_materi' => 1, 'judul_materi' => 'JavaScript Pemula',               'deskripsi' => 'Konsep dasar pemrograman JavaScript.'],
            ['id_guru' => $guru->id_guru, 'kategori' => 'OOP', 'level_materi' => 2, 'judul_materi' => 'Pemrograman Berorientasi Objek', 'deskripsi' => 'OOP dengan PHP.'],
            ['id_guru' => $guru->id_guru, 'kategori' => 'DB',  'level_materi' => 1, 'judul_materi' => 'Basis Data MySQL',               'deskripsi' => 'Pengelolaan data menggunakan MySQL.'],
        ];

        foreach ($materiList as $materi) {
            MateriBelajar::firstOrCreate(
                ['judul_materi' => $materi['judul_materi'], 'id_guru' => $guru->id_guru],
                $materi
            );
        }

        $this->command->info('✅ Akun guru berhasil dibuat:');
        $this->command->info('   Email    : guru@sekolah.id');
        $this->command->info('   Password : password');
    }
}
