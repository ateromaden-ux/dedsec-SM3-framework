<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Guru;
use App\Models\Kuis;
use App\Models\MateriBelajar;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DebugApiController extends Controller
{
    // GET /api/debug/status
    public function status(): JsonResponse
    {
        try {
            $guruColumns   = array_column(Schema::getColumns('guru'), 'name');
            $materiColumns = array_column(Schema::getColumns('materi_belajar'), 'name');
            $soalColumns   = array_column(Schema::getColumns('soal'), 'name');
            $pilihanColumns= array_column(Schema::getColumns('pilihan_jawaban'), 'name');

            return response()->json([
                'ok'              => true,
                'guru_columns'    => $guruColumns,
                'materi_columns'  => $materiColumns,
                'soal_columns'    => $soalColumns,
                'pilihan_columns' => $pilihanColumns,
                'guru_count'      => DB::table('guru')->count(),
                'materi_count'    => DB::table('materi_belajar')->count(),
                'kuis_count'      => DB::table('kuis')->count(),
                'guru_sample'     => DB::table('guru')->first(),
                'materi_list'     => DB::table('materi_belajar')->get(['id_materi', 'judul_materi']),
            ]);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => $e->getMessage()], 500);
        }
    }

    // GET /api/debug/test-kuis
    // Langsung test insert kuis+soal+pilihan ke DB, lalu rollback
    public function testKuis(): JsonResponse
    {
        $guru   = Guru::first();
        $materi = MateriBelajar::first();

        if (! $guru)   return response()->json(['ok' => false, 'error' => 'Tidak ada guru']);
        if (! $materi) return response()->json(['ok' => false, 'error' => 'Tidak ada materi']);

        DB::beginTransaction();
        try {
            $kuis = Kuis::create([
                'id_guru'     => $guru->id_guru,
                'id_materi'   => $materi->id_materi,
                'judul_kuis'  => 'TEST DEBUG KUIS',
                'deskripsi'   => null,
                'jumlah_soal' => 1,
                'batas_lulus' => 70,
                'status'      => 'draft',
            ]);

            $soal = $kuis->soal()->create([
                'pertanyaan' => 'Pertanyaan test?',
                'poin'       => 10,
                'urutan'     => 1,
            ]);

            $options = [
                ['label' => 'A', 'isi' => 'Jawaban A', 'benar' => true,  'pen' => 'Penjelasan A'],
                ['label' => 'B', 'isi' => 'Jawaban B', 'benar' => false, 'pen' => 'Penjelasan B'],
                ['label' => 'C', 'isi' => 'Jawaban C', 'benar' => false, 'pen' => 'Penjelasan C'],
                ['label' => 'D', 'isi' => 'Jawaban D', 'benar' => false, 'pen' => 'Penjelasan D'],
            ];

            foreach ($options as $o) {
                $soal->pilihanJawaban()->create([
                    'label_pilihan' => $o['label'],
                    'isi_pilihan'   => $o['isi'],
                    'is_benar'      => $o['benar'],
                    'penjelasan'    => $o['pen'],
                ]);
            }

            DB::rollBack(); // Jangan benar-benar simpan

            return response()->json([
                'ok'      => true,
                'message' => 'DB INSERT berhasil! Masalah ada di Flutter side (token/CORS/payload).',
                'guru'    => ['id' => $guru->id_guru, 'email' => $guru->email],
                'materi'  => ['id' => $materi->id_materi, 'judul' => $materi->judul_materi],
                'token_ada' => ! empty($guru->api_token),
                'token_preview' => substr((string) $guru->api_token, 0, 10) . '...',
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json([
                'ok'    => false,
                'error' => $e->getMessage(),
                'file'  => basename($e->getFile()) . ':' . $e->getLine(),
            ], 500);
        }
    }

    // GET /api/debug/test-api  (test full API dengan token dari DB)
    public function testApi(): JsonResponse
    {
        $guru = Guru::first();
        if (! $guru) return response()->json(['ok' => false, 'error' => 'Tidak ada guru']);
        if (empty($guru->api_token)) {
            return response()->json([
                'ok'    => false,
                'error' => 'Guru belum punya api_token. Login dulu dari Flutter.',
            ]);
        }

        $materi = MateriBelajar::first();

        // Simulasi request POST /api/kuis dengan token hashed
        // api_token di DB adalah SHA-256 hash dari plain token
        // Kita tidak bisa reverse — tapi kita bisa test apakah middleware bekerja

        return response()->json([
            'ok'            => true,
            'info'          => 'Untuk test full API, gunakan Postman/curl dengan Bearer token dari saat login.',
            'login_url'     => url('/api/auth/login'),
            'kuis_url'      => url('/api/kuis'),
            'materi_url'    => url('/api/materi'),
            'materi_count'  => MateriBelajar::count(),
            'materi_list'   => MateriBelajar::all(['id_materi', 'judul_materi']),
            'guru_has_token'=> ! empty($guru->api_token),
            'hint'          => 'Jika guru_has_token=true artinya sudah login. Coba logout+login ulang dari Flutter.',
        ]);
    }

    // GET /api/debug/test-store  — test store kuis tanpa auth, langsung pakai guru pertama
    public function testStore(): JsonResponse
    {
        $guru   = Guru::first();
        $materi = MateriBelajar::first();

        if (! $guru || ! $materi) {
            return response()->json(['ok' => false, 'error' => 'Data tidak ada']);
        }

        // Simulasi payload persis dari Flutter
        $payload = [
            'judul_kuis'  => 'Test Store ' . now()->format('H:i:s'),
            'deskripsi'   => null,
            'id_materi'   => $materi->id_materi,
            'batas_lulus' => 70,
            'status'      => 'draft',
            'questions'   => [
                [
                    'pertanyaan'    => 'Pertanyaan test?',
                    'poin'          => 10,
                    'correct_answer'=> 0,
                    'options'       => [
                        ['isi_pilihan' => 'Pilihan A', 'penjelasan' => ''],
                        ['isi_pilihan' => 'Pilihan B', 'penjelasan' => ''],
                        ['isi_pilihan' => 'Pilihan C', 'penjelasan' => ''],
                        ['isi_pilihan' => 'Pilihan D', 'penjelasan' => ''],
                    ],
                ],
            ],
        ];

        DB::beginTransaction();
        try {
            $kuis = Kuis::create([
                'id_guru'     => $guru->id_guru,
                'id_materi'   => $payload['id_materi'],
                'judul_kuis'  => $payload['judul_kuis'],
                'deskripsi'   => $payload['deskripsi'],
                'jumlah_soal' => 1,
                'batas_lulus' => $payload['batas_lulus'],
                'status'      => $payload['status'],
            ]);

            $soal = $kuis->soal()->create([
                'pertanyaan' => $payload['questions'][0]['pertanyaan'],
                'poin'       => 10,
                'urutan'     => 1,
            ]);

            foreach ($payload['questions'][0]['options'] as $ai => $opt) {
                $soal->pilihanJawaban()->create([
                    'label_pilihan' => chr(65 + $ai),
                    'isi_pilihan'   => $opt['isi_pilihan'],
                    'is_benar'      => ($ai === 0),
                    'penjelasan'    => $opt['penjelasan'],
                ]);
            }

            DB::rollBack(); // Rollback — ini hanya test

            return response()->json([
                'ok'      => true,
                'message' => '✅ DB insert BERHASIL (sudah di-rollback). Masalah ada di Flutter token/headers.',
                'payload' => $payload,
                'fix'     => 'Logout dari Flutter lalu login ulang untuk refresh token.',
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json([
                'ok'    => false,
                'error' => $e->getMessage(),
                'file'  => basename($e->getFile()) . ':' . $e->getLine(),
            ], 500);
        }
    }

    // POST /api/debug/seed
    public function seed(): JsonResponse
    {
        try {
            Artisan::call('db:seed', ['--class' => 'GuruSeeder', '--force' => true]);
            return response()->json([
                'ok'     => true,
                'output' => Artisan::output(),
                'materi' => MateriBelajar::all(['id_materi', 'judul_materi']),
            ]);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => $e->getMessage()], 500);
        }
    }
}
