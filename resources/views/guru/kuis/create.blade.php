<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Buat Kuis - LearnPath</title>
    <link rel="stylesheet" href="{{ asset('css/kuis-builder.css') }}">
</head>
<body>
<div class="app-shell">
    <aside class="sidebar">
        <div class="brand">
            <span class="brand-icon">▣</span>
            <span>LearnPath</span>
        </div>

        <nav class="sidebar-nav">
            <a href="#" class="nav-item"><span>⊞</span>Dashboard</a>
            <a href="#" class="nav-item"><span>▣</span>Materi Belajar</a>
            <a href="{{ route('guru.kuis.index') }}" class="nav-item active"><span>?</span>Kuis</a>
            <a href="#" class="nav-item"><span>▤</span>Bank Soal</a>
            <a href="#" class="nav-item"><span>♧</span>Siswa</a>
            <a href="#" class="nav-item"><span>▥</span>Progress Siswa</a>
            <a href="#" class="nav-item"><span>⚙</span>Settings</a>
        </nav>

        <a href="#" class="nav-item logout"><span>↪</span>Logout</a>
    </aside>

    <main class="main-content">
        <form id="quizForm" action="{{ route('guru.kuis.store') }}" method="POST">
            @csrf
            <input type="hidden" name="status" id="statusInput" value="draft">

            <header class="page-header">
                <div>
                    <a href="{{ route('guru.kuis.index') }}" class="back-link">← Kembali</a>
                    <h1>Buat Kuis</h1>
                </div>
                <div class="header-actions">
                    <button type="button" class="btn btn-outline" data-submit-status="draft">Simpan Draft</button>
                    <button type="button" class="btn btn-primary" data-submit-status="published">Publikasi Kuis</button>
                </div>
            </header>

            @if ($errors->any())
                <div class="alert alert-error">
                    <strong>Periksa kembali data:</strong>
                    <ul>
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <section class="settings-card">
                <h2>Pengaturan Kuis</h2>

                <div class="settings-grid">
                    <div class="field">
                        <label for="judul_kuis">Judul Kuis</label>
                        <input id="judul_kuis" name="judul_kuis" type="text"
                               value="{{ old('judul_kuis') }}"
                               placeholder="Kuis Pemrograman Web Dasar - HTML" required>
                    </div>

                    <div class="field">
                        <label for="deskripsi">Deskripsi</label>
                        <textarea id="deskripsi" name="deskripsi" rows="3"
                                  placeholder="Kuis evaluasi pemahaman siswa...">{{ old('deskripsi') }}</textarea>
                    </div>

                    <div class="field">
                        <label for="id_materi">Pilih Materi Pembelajaran</label>
                        <select id="id_materi" name="id_materi" required>
                            <option value="">Pilih materi</option>
                            @foreach ($materi as $item)
                                <option value="{{ $item->id_materi }}"
                                    @selected(old('id_materi') == $item->id_materi)>
                                    {{ $item->judul_materi }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="info-field">
                        <label>Status Kuis</label>
                        <span class="status-badge" id="statusBadge">DRAFT</span>
                    </div>

                    <div class="info-field">
                        <label>Jumlah Soal</label>
                        <strong><span id="questionCount">0</span> Soal Terbuat</strong>
                    </div>

                    <div class="field">
                        <label for="batas_lulus">Nilai Kelulusan</label>
                        <input id="batas_lulus" name="batas_lulus" type="number"
                               min="0" max="100" value="{{ old('batas_lulus', 70) }}" required>
                    </div>
                </div>
            </section>

            <div class="section-heading">
                <h2>Daftar Soal</h2>
                <button type="button" class="btn btn-primary" id="addQuestionTop">＋ Tambah Soal</button>
            </div>

            <div id="questionsContainer"></div>

            <button type="button" class="add-question-large" id="addQuestionBottom">
                ＋ Tambah Soal Baru
            </button>

            <div class="bottom-actions">
                <button type="button" class="btn btn-outline" data-submit-status="draft">Simpan Draft</button>
                <button type="button" class="btn btn-secondary" id="previewBtn">Preview Kuis</button>
                <button type="button" class="btn btn-primary" data-submit-status="published">Terbitkan Kuis</button>
            </div>
        </form>
    </main>
</div>

<template id="questionTemplate">
    <article class="question-card" data-question-index="__INDEX__">
        <div class="question-header">
            <div class="question-title">
                <span class="drag-handle" title="Geser untuk mengurutkan">⋮⋮</span>
                <h3>Soal <span class="question-number">1</span></h3>
                <span class="type-badge">Pilihan Ganda</span>
            </div>

            <div class="question-tools">
                <input class="point-input" type="number" min="1" name="questions[__INDEX__][poin]" value="10" title="Poin">
                <span class="point-label">Poin</span>
                <button type="button" class="icon-btn duplicate-question" title="Duplikat">⧉</button>
                <button type="button" class="icon-btn delete-question danger" title="Hapus">♲</button>
            </div>
        </div>

        <div class="field">
            <label>Pertanyaan</label>
            <textarea name="questions[__INDEX__][pertanyaan]" class="question-input" rows="3"
                      placeholder="Masukkan pertanyaan..." required></textarea>
        </div>

        <div class="answer-section">
            <div class="answer-section-title">
                <label>Pilihan Jawaban</label>
                <span class="hint">Pilih satu jawaban yang benar</span>
            </div>

            <div class="answers-container"></div>

            <button type="button" class="add-answer">＋ Tambah Pilihan</button>
        </div>
    </article>
</template>

<template id="answerTemplate">
    <div class="answer-card" data-answer-index="__ANSWER_INDEX__">
        <div class="answer-main">
            <span class="answer-label">A</span>

            <input type="text"
                   name="questions[__INDEX__][options][__ANSWER_INDEX__][isi_pilihan]"
                   placeholder="Masukkan pilihan jawaban..."
                   class="answer-input" required>

            <label class="correct-control">
                <input type="radio"
                       name="questions[__INDEX__][correct_answer]"
                       value="__ANSWER_INDEX__"
                       class="correct-radio">
                <span>Jawaban benar</span>
            </label>

            <button type="button" class="icon-btn delete-answer" title="Hapus pilihan">×</button>
        </div>

        <div class="explanation-wrap">
            <label>Penjelasan Jawaban</label>
            <textarea name="questions[__INDEX__][options][__ANSWER_INDEX__][penjelasan]"
                      class="explanation-input" rows="2"
                      placeholder="Jelaskan mengapa jawaban ini benar atau salah..." required></textarea>
        </div>
    </div>
</template>

<div class="modal-backdrop" id="previewModal" hidden>
    <div class="preview-modal">
        <button type="button" class="modal-close" id="closePreview">×</button>
        <div class="preview-header">
            <span class="preview-kicker">PREVIEW KUIS</span>
            <h2 id="previewTitle">Judul Kuis</h2>
            <p id="previewDescription"></p>
        </div>
        <div id="previewBody"></div>
    </div>
</div>

<script src="{{ asset('js/kuis-builder.js') }}"></script>
</body>
</html>
