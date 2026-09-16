<?php

namespace App\Http\Controllers\Guru;

use App\Http\Controllers\Controller;
use App\Models\Kuis;
use App\Models\MateriBelajar;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class KuisController extends Controller
{
    private function guruId(): int
    {
        return Auth::guard('guru')->id();
    }

    public function index()
    {
        $kuis = Kuis::with('materi')
            ->latest('created_at')
            ->get();

        return view('guru.kuis.index', compact('kuis'));
    }

    public function create()
    {
        $materi = MateriBelajar::orderBy('judul_materi')->get();

        return view('guru.kuis.create', compact('materi'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'judul_kuis' => ['required', 'string', 'max:255'],
            'deskripsi' => ['nullable', 'string'],
            'id_materi' => ['required', 'integer', 'exists:materi_belajar,id_materi'],
            'batas_lulus' => ['required', 'integer', 'min:0', 'max:100'],
            'status' => ['required', 'in:draft,published'],
            'questions' => ['required', 'array', 'min:1'],
            'questions.*.pertanyaan' => ['required', 'string'],
            'questions.*.poin' => ['required', 'integer', 'min:1'],
            'questions.*.correct_answer' => ['required', 'integer', 'min:0'],
            'questions.*.options' => ['required', 'array', 'min:2'],
            'questions.*.options.*.isi_pilihan' => ['required', 'string'],
            'questions.*.options.*.penjelasan' => ['required', 'string'],
        ]);

        DB::transaction(function () use ($data) {
            $guruId = $this->guruId();

            $kuis = Kuis::create([
                'id_guru' => $guruId,
                'id_materi' => $data['id_materi'],
                'judul_kuis' => $data['judul_kuis'],
                'deskripsi' => $data['deskripsi'] ?? null,
                'jumlah_soal' => count($data['questions']),
                'batas_lulus' => $data['batas_lulus'],
                'status' => $data['status'],
            ]);

            foreach ($data['questions'] as $questionIndex => $questionData) {
                $soal = $kuis->soal()->create([
                    'pertanyaan' => $questionData['pertanyaan'],
                    'poin' => $questionData['poin'],
                    'urutan' => $questionIndex + 1,
                ]);

                foreach ($questionData['options'] as $answerIndex => $answerData) {
                    $soal->pilihanJawaban()->create([
                        'label_pilihan' => chr(65 + $answerIndex),
                        'isi_pilihan' => $answerData['isi_pilihan'],
                        'is_benar' => ((int) $questionData['correct_answer'] === $answerIndex),
                        'penjelasan' => $answerData['penjelasan'],
                    ]);
                }
            }
        });

        return redirect()
            ->route('guru.kuis.index')
            ->with('success', 'Kuis berhasil disimpan.');
    }
}
