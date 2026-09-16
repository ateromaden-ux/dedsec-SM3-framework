<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kuis;
use App\Models\MateriBelajar;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class KuisApiController extends Controller
{
    /**
     * Daftar semua kuis milik guru yang login.
     */
    public function index(Request $request): JsonResponse
    {
        $guru = $request->user();

        $kuis = Kuis::with('materi')
            ->where('id_guru', $guru->id_guru)
            ->latest()
            ->get()
            ->map(fn ($k) => $this->formatKuis($k));

        return response()->json(['data' => $kuis]);
    }

    /**
     * Detail satu kuis beserta soal & pilihan jawaban.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $guru = $request->user();

        $kuis = Kuis::with(['materi', 'soal.pilihanJawaban'])
            ->where('id_guru', $guru->id_guru)
            ->findOrFail($id);

        return response()->json(['data' => $this->formatKuisDetail($kuis)]);
    }

    /**
     * Buat kuis baru beserta soal dan pilihan jawaban.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'judul_kuis'                             => ['required', 'string', 'max:255'],
            'deskripsi'                              => ['nullable', 'string'],
            'id_materi'                              => ['required', 'integer', 'exists:materi_belajar,id_materi'],
            'batas_lulus'                            => ['required', 'integer', 'min:0', 'max:100'],
            'status'                                 => ['required', 'in:draft,published'],
            'questions'                              => ['required', 'array', 'min:1'],
            'questions.*.pertanyaan'                 => ['required', 'string'],
            'questions.*.poin'                       => ['required', 'integer', 'min:1'],
            'questions.*.correct_answer'             => ['required', 'integer', 'min:0'],
            'questions.*.options'                    => ['required', 'array', 'min:2'],
            'questions.*.options.*.isi_pilihan'      => ['required', 'string'],
            'questions.*.options.*.penjelasan'       => ['nullable', 'string'],
        ]);

        $guru  = $request->user();
        $kuis  = null;

        DB::transaction(function () use ($data, $guru, &$kuis) {
            $kuis = Kuis::create([
                'id_guru'     => $guru->id_guru,
                'id_materi'   => $data['id_materi'],
                'judul_kuis'  => $data['judul_kuis'],
                'deskripsi'   => $data['deskripsi'] ?? null,
                'jumlah_soal' => count($data['questions']),
                'batas_lulus' => $data['batas_lulus'],
                'status'      => $data['status'],
            ]);

            foreach ($data['questions'] as $qi => $qData) {
                $soal = $kuis->soal()->create([
                    'pertanyaan' => $qData['pertanyaan'],
                    'poin'       => $qData['poin'],
                    'urutan'     => $qi + 1,
                ]);

                foreach ($qData['options'] as $ai => $aData) {
                    $soal->pilihanJawaban()->create([
                        'label_pilihan' => chr(65 + $ai),
                        'isi_pilihan'   => $aData['isi_pilihan'],
                        'is_benar'      => ((int) $qData['correct_answer'] === $ai),
                        'penjelasan'    => $aData['penjelasan'] ?? '',
                    ]);
                }
            }
        });

        $kuis->load(['materi', 'soal.pilihanJawaban']);

        return response()->json([
            'message' => 'Kuis berhasil dibuat.',
            'data'    => $this->formatKuisDetail($kuis),
        ], 201);
    }

    /**
     * Update data kuis (judul, deskripsi, status, dll) — tanpa soal.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $guru = $request->user();
        $kuis = Kuis::where('id_guru', $guru->id_guru)->findOrFail($id);

        $data = $request->validate([
            'judul_kuis'  => ['sometimes', 'string', 'max:255'],
            'deskripsi'   => ['nullable', 'string'],
            'id_materi'   => ['sometimes', 'integer', 'exists:materi_belajar,id_materi'],
            'batas_lulus' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'status'      => ['sometimes', 'in:draft,published'],
        ]);

        $kuis->update($data);
        $kuis->load('materi');

        return response()->json([
            'message' => 'Kuis berhasil diupdate.',
            'data'    => $this->formatKuis($kuis),
        ]);
    }

    /**
     * Hapus kuis beserta soal & pilihan jawaban (cascade).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $guru = $request->user();
        $kuis = Kuis::where('id_guru', $guru->id_guru)->findOrFail($id);
        $kuis->delete();

        return response()->json(['message' => 'Kuis berhasil dihapus.']);
    }

    /**
     * Daftar materi belajar (untuk dropdown).
     */
    public function materiList(Request $request): JsonResponse
    {
        $materi = MateriBelajar::orderBy('judul_materi')->get(['id_materi', 'judul_materi', 'kategori']);

        return response()->json(['data' => $materi]);
    }

    // -------------------------------------------------------------------------

    private function formatKuis(Kuis $k): array
    {
        return [
            'id_kuis'     => $k->id_kuis,
            'judul_kuis'  => $k->judul_kuis,
            'deskripsi'   => $k->deskripsi,
            'jumlah_soal' => $k->jumlah_soal,
            'batas_lulus' => $k->batas_lulus,
            'status'      => $k->status,
            'id_materi'   => $k->id_materi,
            'materi'      => $k->materi ? [
                'id_materi'    => $k->materi->id_materi,
                'judul_materi' => $k->materi->judul_materi,
                'kategori'     => $k->materi->kategori ?? null,
            ] : null,
            'created_at'  => $k->created_at?->toIso8601String(),
            'updated_at'  => $k->updated_at?->toIso8601String(),
        ];
    }

    private function formatKuisDetail(Kuis $k): array
    {
        $base = $this->formatKuis($k);
        $base['soal'] = $k->soal->sortBy('urutan')->values()->map(fn ($s) => [
            'id_soal'          => $s->id_soal,
            'pertanyaan'       => $s->pertanyaan,
            'poin'             => $s->poin,
            'urutan'           => $s->urutan,
            'pilihan_jawaban'  => $s->pilihanJawaban->map(fn ($p) => [
                'id_pilihan'    => $p->id_pilihan,
                'label_pilihan' => $p->label_pilihan,
                'isi_pilihan'   => $p->isi_pilihan,
                'is_benar'      => $p->is_benar,
                'penjelasan'    => $p->penjelasan,
            ])->values(),
        ])->values();

        return $base;
    }
}
