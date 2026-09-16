<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - LearnPath</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
        }

        .card {
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 20px;
            padding: 48px 40px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 25px 50px rgba(0,0,0,0.4);
        }

        .brand {
            text-align: center;
            margin-bottom: 36px;
        }

        .brand-icon {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 56px;
            height: 56px;
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
            border-radius: 16px;
            font-size: 24px;
            margin-bottom: 16px;
            box-shadow: 0 8px 24px rgba(99,102,241,0.4);
        }

        h1 {
            color: #fff;
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 6px;
        }

        .subtitle {
            color: rgba(255,255,255,0.5);
            font-size: 14px;
        }

        .field {
            margin-bottom: 20px;
        }

        label {
            display: block;
            color: rgba(255,255,255,0.7);
            font-size: 13px;
            font-weight: 500;
            margin-bottom: 8px;
        }

        input[type="email"],
        input[type="password"] {
            width: 100%;
            padding: 12px 16px;
            background: rgba(255,255,255,0.08);
            border: 1px solid rgba(255,255,255,0.12);
            border-radius: 10px;
            color: #fff;
            font-size: 15px;
            font-family: inherit;
            outline: none;
            transition: border-color .2s, background .2s;
        }

        input[type="email"]:focus,
        input[type="password"]:focus {
            border-color: #6366f1;
            background: rgba(99,102,241,0.1);
        }

        input::placeholder { color: rgba(255,255,255,0.3); }

        .remember-row {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 28px;
        }

        .remember-row input { width: auto; accent-color: #6366f1; }
        .remember-row label { margin: 0; color: rgba(255,255,255,0.6); font-size: 14px; }

        .btn-login {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
            color: #fff;
            font-size: 15px;
            font-weight: 600;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-family: inherit;
            transition: opacity .2s, transform .1s;
            box-shadow: 0 8px 24px rgba(99,102,241,0.35);
        }

        .btn-login:hover { opacity: .9; transform: translateY(-1px); }
        .btn-login:active { transform: translateY(0); }

        .error-box {
            background: rgba(239,68,68,0.15);
            border: 1px solid rgba(239,68,68,0.3);
            border-radius: 10px;
            padding: 12px 16px;
            margin-bottom: 20px;
            color: #fca5a5;
            font-size: 14px;
        }

        .demo-hint {
            margin-top: 24px;
            padding: 14px 16px;
            background: rgba(99,102,241,0.1);
            border: 1px solid rgba(99,102,241,0.2);
            border-radius: 10px;
            color: rgba(255,255,255,0.6);
            font-size: 13px;
            text-align: center;
            line-height: 1.6;
        }

        .demo-hint strong { color: rgba(255,255,255,0.9); }
    </style>
</head>
<body>
<div class="card">
    <div class="brand">
        <div class="brand-icon">▣</div>
        <h1>LearnPath</h1>
        <p class="subtitle">Masuk ke akun guru Anda</p>
    </div>

    @if ($errors->any())
        <div class="error-box">
            {{ $errors->first() }}
        </div>
    @endif

    <form action="{{ route('login.submit') }}" method="POST">
        @csrf

        <div class="field">
            <label for="email">Email</label>
            <input id="email" type="email" name="email"
                   value="{{ old('email') }}"
                   placeholder="guru@sekolah.id" required autofocus>
        </div>

        <div class="field">
            <label for="password">Password</label>
            <input id="password" type="password" name="password"
                   placeholder="••••••••" required>
        </div>

        <div class="remember-row">
            <input type="checkbox" id="remember" name="remember">
            <label for="remember">Ingat saya</label>
        </div>

        <button type="submit" class="btn-login">Masuk</button>
    </form>

    <div class="demo-hint">
        Belum punya akun? Jalankan seeder:<br>
        <strong>php artisan db:seed --class=GuruSeeder</strong>
    </div>
</div>
</body>
</html>
