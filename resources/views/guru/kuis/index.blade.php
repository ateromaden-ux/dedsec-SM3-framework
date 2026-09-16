<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar Kuis - LearnPath</title>
    <link rel="stylesheet" href="{{ asset('css/kuis-builder.css') }}">
    <style>
        .kuis-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 20px;
            margin-top: 24px;
        }

        .kuis-card {
            background: var(--surface, #1e1e2e);
            border: 1px solid var(--border, rgba(255,255,255,0.08));
            border-radius: 16px;
            padding: 24px;
            transition: transform .2s, box-shadow .2s;
        }

        .kuis-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 32px rgba(0,0,0,0.3);
        }

        .kuis-title { font-size: 18px; font-weight: 700; color: #e2e8f0; margin-bottom: 8px; }
        .kuis-meta { font-size: 13px; color: rgba(255,255,255,0.45); margin-bottom: 16px; }
        .kuis-meta span { margin-right: 12px; }

        .badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-draft { background: rgba(251,191,36,0.15); color: #fbbf24; }
        .badge-published { background: rgba(52,211,153,0.15); color: #34d399; }

        .kuis-actions { display: flex; gap: 10px; margin-top: 16px; }

        .empty-state {
            text-align: center;
            padding: 80px 20px;
            color: rgba(255,255,255,0.4);
        }

        .empty-state .icon { font-size: 48px; margin-bottom: 16px; }
        .empty-state h3 { font-size: 20px; color: rgba(255,255,255,0.6); margin-bottom: 8px; }

        .alert-success {
            background: rgba(52,211,153,0.1);
            border: 1px solid rgba(52,211,153,0.3);
            border-radius: 10px;
            padding: 14px 18px;
            color: #34d399;
            margin-bottom: 24px;
        }
    </style>
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

        <form action="{{ route('logout') }}" method="POST" style="margin-top:auto;">
            @csrf
            <button type="submit" class="nav-item logout" style="width:100%;background:none;border:none;cursor:pointer;text-align:left;">
                <span>↪</span>Logout
            </button>
        </form>
    </aside>

    <main class="main-content">
        <header class="page-header">
            <div>
                <h1>Daftar Kuis</h1>
                <p style="color:rgba(255,255,255,0.45);font-size:14px;margin-top:4px;">
                    Kelola semua kuis yang telah kamu buat
                </p>
            </div>
            <div class="header-actions">
                <a href="{{ route('guru.kuis.create') }}" class="btn btn-primary">＋ Buat Kuis Baru</a>
            </div>
        </header>

        @if (session('success'))
            <div class="alert-success">✓ {{ session('success') }}</div>
        @endif

        @if ($kuis->isEmpty())
            <div class="empty-state">
                <div class="icon">📋</div>
                <h3>Belum ada kuis</h3>
                <p>Mulai buat kuis pertamamu!</p>
                <a href="{{ route('guru.kuis.create') }}" class="btn btn-primary" style="margin-top:20px;display:inline-block;">
                    ＋ Buat Kuis Pertama
                </a>
            </div>
        @else
            <div class="kuis-grid">
                @foreach ($kuis as $item)
                    <div class="kuis-card">
                        <div class="kuis-title">{{ $item->judul_kuis }}</div>
                        <div class="kuis-meta">
                            <span>📚 {{ $item->materi?->judul_materi ?? 'Tanpa Materi' }}</span>
                            <span>📝 {{ $item->jumlah_soal }} soal</span>
                            <span>🎯 Lulus ≥ {{ $item->batas_lulus }}</span>
                        </div>
                        <span class="badge badge-{{ $item->status }}">{{ $item->status }}</span>

                        <div class="kuis-actions">
                            <a href="#" class="btn btn-outline" style="font-size:13px;padding:8px 14px;">Edit</a>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </main>
</div>
</body>
</html>
