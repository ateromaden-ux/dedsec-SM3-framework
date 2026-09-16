<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kuis;
use App\Models\Soal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SoalApiController extends Controller
{
    /**
     * Daftar soal dalam sebuah kuis.
     */
    public function index(Request $request, int $kuisId): JsonResponse
    {
        $guru = $request->user();
        $kuis = Kuis::where('id_guru', $guru->id_guru)->findOrFail($kuisId);

        $soal = $kuis->soal()
            ->with('pilihanJawaban')
            ->orderBy('urutan')
            ->get()
            ->map(fn ($s) => $this->formatSoal($s));

        return response()->json(['data' => $soal]);
    }

    /**
     * Detail satu soal beserta pilihan jawaban.
     */
    public function show(Request $request, int $kuisId, int $soalId): JsonResponse
    {
        $guru = $request->user();
        $kuis = Kuis::where('id_guru', $guru->id_guru)->findOrFail($kuisId);

        $soal = $kuis->soal()->with('pilihanJawaban')->findOrFail($soalId);

        return response()->json(['data' => $this->formatSoal($soal)]);
    }

    /**
     * Tambah soal baru ke kuis.
     */
    public function store(Request $request, int $kuisId): JsonResponse
    {
        $guru = $request->user();
        $kuis = Kuis::where('id_guru', $guru->id_guru)->findOrFail($kuisId);

        $data = $request->validate([
            'pertanyaan'                => ['required', 'string'],
            'poin'                      => ['required', 'integer', 'min:1'],
            'correct_answer'            => ['required', 'integer', 'min:0'],
            'options'                   => ['required', 'array', 'min:2'],
            'options.*.isi_pilihan'     => ['required', 'string'],
            'options.*.penjelasan'      => ['nullable', 'string'],
        ]);

        $soal = null;

        DB::transaction(function () use ($kuis, $data, &$soal) {
            $nextUrutan = $kuis->soal()->max('urutan') + 1;

            $soal = $kuis->soal()->create([
                'pertanyaan' => $data['pertanyaan'],
                'poin'       => $data['poin'],
                'urutan'     => $nextUrutan,
            ]);

            foreach ($data['options'] as $ai => $aData) {
                $soal->pilihanJawaban()->create([
                    'label_pilihan' => chr(65 + $ai),
                    'isi_pilihan'   => $aData['isi_pilihan'],
                    'is_benar'      => ((int) $data['correct_answer'] === $ai),
                    'penjelasan'    => $aData['penjelasan'] ?? '',
                ]);
            }

            // Update jumlah_soal di kuis
            $kuis->increment('jumlah_soal');
        });

        $soal->load('pilihanJawaban');

        return response()->json([
            'message' => 'Soal berhasil ditambahkan.',
            'data'    => $this->formatSoal($soal),
        ], 201);
    }

    /**
     * Update soal beserta pilihan jawaban (replace semua pilihan).
     */
    public function update(Request $request, int $kuisId, int $soalId): JsonResponse
    {
        $guru = $request->user();
        $kuis = Kuis::where('id_guru', $guru->id_guru)->findOrFail($kuisId);
        $soal = $kuis->soal()->findOrFail($soalId);

        $data = $request->validate([
            'pertanyaan'                => ['sometimes', 'string'],
            'poin'                      => ['sometimes', 'integer', 'min:1'],
            'correct_answer'            => ['required_with:options', 'integer', 'min:0'],
            'options'                   => ['sometimes', 'array', 'min:2'],
            'options.*.isi_pilihan'     => ['required_with:options', 'string'],
            'options.*.penjelasan'      => ['nullable', 'string'],
        ]);

        DB::transaction(function () use ($soal, $data) {
            $soal->update([
                'pertanyaan' => $data['pertanyaan'] ?? $soal->pertanyaan,
                'poin'       => $data['poin'] ?? $soal->poin,
            ]);

            // Jika ada options baru, hapus lama dan buat ulang
            if (isset($data['options'])) {
                $soal->pilihanJawaban()->delete();

                foreach ($data['options'] as $ai => $aData) {
                    $soal->pilihanJawaban()->create([
                        'label_pilihan' => chr(65 + $ai),
                        'isi_pilihan'   => $aData['isi_pilihan'],
                        'is_benar'      => ((int) $data['correct_answer'] === $ai),
                        'penjelasan'    => $aData['penjelasan'] ?? '',
                    ]);
                }
            }
        });

        $soal->load('pilihanJawaban');

        return response()->json([
            'message' => 'Soal berhasil diupdate.',
            'data'    => $this->formatSoal($soal),
        ]);
    }

    /**
     * Hapus soal (beserta pilihan jawaban via cascade).
     */
    public function destroy(Request $request, int $kuisId, int $soalId): JsonResponse
    {
        $guru = $request->user();
        $kuis = Kuis::where('id_guru', $guru->id_guru)->findOrFail($kuisId);
        $soal = $kuis->soal()->findOrFail($soalId);

        DB::transaction(function () use ($soal, $kuis) {
            $soal->delete();
            // Renumber urutan
            $kuis->soal()->orderBy('urutan')->get()->each(function ($s, $i) {
                $s->update(['urutan' => $i + 1]);
            });
            // Update jumlah_soal
            $kuis->decrement('jumlah_soal');
        });

        return response()->json(['message' => 'Soal berhasil dihapus.']);
    }

    // -------------------------------------------------------------------------

    private function formatSoal(Soal $s): array
    {
        return [
            'id_soal'         => $s->id_soal,
            'id_kuis'         => $s->id_kuis,
            'pertanyaan'      => $s->pertanyaan,
            'poin'            => $s->poin,
            'urutan'          => $s->urutan,
            'pilihan_jawaban' => $s->pilihanJawaban->map(fn ($p) => [
                'id_pilihan'    => $p->id_pilihan,
                'label_pilihan' => $p->label_pilihan,
                'isi_pilihan'   => $p->isi_pilihan,
                'is_benar'      => $p->is_benar,
                'penjelasan'    => $p->penjelasan,
            ])->values(),
        ];
    }
}
