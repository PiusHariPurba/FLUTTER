<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login – Pius Hari Purba</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">

    {{-- CSRF Token (Laravel requirement) --}}
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <style>
        *, *::before, *::after {
            margin: 0; padding: 0;
            box-sizing: border-box;
        }

        :root {
            --navy:   #0a1628;
            --blue:   #1a3a6e;
            --accent: #4c9be8;
            --gold:   #c9a84c;
            --white:  #ffffff;
            --err:    #ff6b6b;
        }

        body {
            font-family: 'DM Sans', sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, var(--navy) 0%, #0d2247 50%, #112755 100%);
            overflow: hidden;
            position: relative;
        }

        /* Animated background blobs */
        .blob {
            position: absolute;
            border-radius: 50%;
            filter: blur(80px);
            opacity: 0.18;
            animation: blobFloat 8s ease-in-out infinite;
        }
        .blob-1 { width: 400px; height: 400px; background: var(--accent); top: -100px; left: -100px; animation-delay: 0s; }
        .blob-2 { width: 300px; height: 300px; background: var(--gold);   bottom: -80px; right: -80px; animation-delay: 3s; }
        .blob-3 { width: 200px; height: 200px; background: #6e4eff;        top: 40%; left: 60%; animation-delay: 5s; }

        /* Floating particles */
        .particles { position: absolute; inset: 0; pointer-events: none; overflow: hidden; }
        .particle {
            position: absolute;
            width: 4px; height: 4px;
            border-radius: 50%;
            background: rgba(255,255,255,0.3);
            animation: particleFloat linear infinite;
        }

        /* ===== CARD WRAPPER ===== */
        .wrapper {
            position: relative;
            z-index: 10;
            width: 420px;
            background: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.15);
            border-radius: 24px;
            backdrop-filter: blur(24px);
            -webkit-backdrop-filter: blur(24px);
            box-shadow:
                0 0 0 1px rgba(255,255,255,0.05),
                0 20px 60px rgba(0,0,0,0.4),
                inset 0 1px 0 rgba(255,255,255,0.1);
            padding: 48px 44px;
            animation: slideUp 0.7s cubic-bezier(.16,1,.3,1) both;
        }

        /* Gold top accent bar */
        .wrapper::before {
            content: '';
            position: absolute;
            top: 0; left: 40px; right: 40px;
            height: 3px;
            background: linear-gradient(90deg, transparent, var(--gold), transparent);
            border-radius: 0 0 4px 4px;
        }

        /* ===== HEADER ===== */
        .login-header {
            text-align: center;
            margin-bottom: 38px;
        }

        .login-header .icon-circle {
            width: 58px; height: 58px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--accent), var(--blue));
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 16px;
            box-shadow: 0 8px 24px rgba(76,155,232,0.35);
        }

        .login-header .icon-circle svg { width: 26px; height: 26px; fill: white; }

        .login-header h2 {
            font-family: 'Playfair Display', serif;
            font-size: 28px;
            color: var(--white);
            margin-bottom: 6px;
        }

        .login-header p {
            color: rgba(255,255,255,0.45);
            font-size: 13px;
        }

        /* ===== INPUT ===== */
        .input-group {
            position: relative;
            margin-bottom: 22px;
        }

        .input-group label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.8px;
            text-transform: uppercase;
            color: rgba(255,255,255,0.5);
            margin-bottom: 8px;
            transition: color 0.3s;
        }

        .input-group:focus-within label { color: var(--gold); }

        .input-wrap {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-wrap .i-icon {
            position: absolute;
            left: 14px;
            color: rgba(255,255,255,0.4);
            transition: color 0.3s;
            display: flex; align-items: center;
        }

        .input-wrap .i-icon svg { width: 17px; height: 17px; stroke: currentColor; fill: none; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; }

        .input-group:focus-within .i-icon { color: var(--accent); }

        .input-wrap input {
            width: 100%;
            padding: 13px 14px 13px 42px;
            background: rgba(255,255,255,0.07);
            border: 1.5px solid rgba(255,255,255,0.12);
            border-radius: 12px;
            color: var(--white);
            font-family: 'DM Sans', sans-serif;
            font-size: 14px;
            outline: none;
            transition: border-color 0.3s, background 0.3s, box-shadow 0.3s;
        }

        .input-wrap input::placeholder { color: rgba(255,255,255,0.25); }

        .input-wrap input:focus {
            border-color: var(--accent);
            background: rgba(76,155,232,0.08);
            box-shadow: 0 0 0 3px rgba(76,155,232,0.15);
        }

        /* toggle password visibility */
        .toggle-pw {
            position: absolute;
            right: 12px;
            background: none;
            border: none;
            cursor: pointer;
            color: rgba(255,255,255,0.35);
            padding: 4px;
            display: flex;
            transition: color 0.2s;
        }
        .toggle-pw:hover { color: rgba(255,255,255,0.7); }
        .toggle-pw svg { width: 17px; height: 17px; stroke: currentColor; fill: none; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; }

        /* ===== REMEMBER & FORGOT ===== */
        .extras {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 28px;
        }

        .remember {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
        }

        .remember input[type="checkbox"] {
            accent-color: var(--accent);
            width: 15px; height: 15px;
            cursor: pointer;
        }

        .remember span {
            font-size: 13px;
            color: rgba(255,255,255,0.5);
        }

        .forgot-link {
            font-size: 13px;
            color: var(--accent);
            text-decoration: none;
            transition: color 0.2s;
        }
        .forgot-link:hover { color: var(--gold); }

        /* ===== BUTTON ===== */
        .btn-login {
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 12px;
            background: linear-gradient(135deg, var(--accent) 0%, #2a72cc 100%);
            color: var(--white);
            font-family: 'DM Sans', sans-serif;
            font-size: 15px;
            font-weight: 600;
            letter-spacing: 0.5px;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s, filter 0.2s;
            box-shadow: 0 6px 20px rgba(76,155,232,0.35);
            position: relative;
            overflow: hidden;
            margin-bottom: 20px;
        }

        .btn-login::after {
            content: '';
            position: absolute;
            inset: 0;
            background: linear-gradient(to right, transparent 30%, rgba(255,255,255,0.15), transparent 70%);
            transform: translateX(-100%);
            transition: transform 0.5s ease;
        }

        .btn-login:hover { transform: translateY(-2px); box-shadow: 0 10px 28px rgba(76,155,232,0.45); filter: brightness(1.05); }
        .btn-login:hover::after { transform: translateX(100%); }
        .btn-login:active { transform: translateY(0); }

        /* ===== REGISTER LINK ===== */
        .register-line {
            text-align: center;
            font-size: 13px;
            color: rgba(255,255,255,0.4);
        }
        .register-line a {
            color: var(--gold);
            text-decoration: none;
            font-weight: 600;
            transition: color 0.2s;
        }
        .register-line a:hover { color: var(--accent); }

        /* ===== ERROR ALERT ===== */
        .alert-error {
            background: rgba(255,107,107,0.12);
            border: 1px solid rgba(255,107,107,0.3);
            border-radius: 10px;
            padding: 11px 14px;
            margin-bottom: 20px;
            font-size: 13px;
            color: var(--err);
            display: none;
            animation: shake 0.4s ease;
        }

        /* ===== ANIMATIONS ===== */
        @keyframes slideUp {
            from { opacity: 0; transform: translateY(40px) scale(0.97); }
            to   { opacity: 1; transform: translateY(0) scale(1); }
        }

        @keyframes blobFloat {
            0%, 100% { transform: translate(0, 0) scale(1); }
            33%       { transform: translate(20px, -20px) scale(1.05); }
            66%       { transform: translate(-15px, 15px) scale(0.97); }
        }

        @keyframes particleFloat {
            0%   { transform: translateY(100vh) rotate(0deg); opacity: 0; }
            10%  { opacity: 1; }
            90%  { opacity: 0.6; }
            100% { transform: translateY(-10vh) rotate(360deg); opacity: 0; }
        }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            20%       { transform: translateX(-6px); }
            40%       { transform: translateX(6px); }
            60%       { transform: translateX(-4px); }
            80%       { transform: translateX(4px); }
        }

        /* ===== SESSION ERROR (dari Laravel) ===== */
        .laravel-error {
            background: rgba(255,107,107,0.12);
            border: 1px solid rgba(255,107,107,0.3);
            border-radius: 10px;
            padding: 11px 14px;
            margin-bottom: 20px;
            font-size: 13px;
            color: var(--err);
        }
    </style>
</head>

<body>

    {{-- Background blobs --}}
    <div class="blob blob-1"></div>
    <div class="blob blob-2"></div>
    <div class="blob blob-3"></div>

    {{-- Floating particles (generated via JS) --}}
    <div class="particles" id="particles"></div>

    {{-- ===== LOGIN CARD ===== --}}
    <div class="wrapper">

        <div class="login-header">
            <div class="icon-circle">
                <svg viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            </div>
            <h2>Selamat Datang</h2>
            <p>Silakan masuk ke akun Anda</p>
        </div>

        {{-- Laravel session error --}}
        @if (session('error'))
            <div class="laravel-error">{{ session('error') }}</div>
        @endif

        {{-- JS-side error --}}
        <div class="alert-error" id="alertError"></div>

        {{-- 
            Di Laravel, action form diarahkan ke route login.
            Controller LoginController@login yang memproses validasi.
        --}}
        <form id="loginForm" method="POST" action="{{ route('login.post') }}">
            @csrf

            <div class="input-group">
                <label>Email</label>
                <div class="input-wrap">
                    <span class="i-icon">
                        <svg viewBox="0 0 24 24"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                    </span>
                    <input type="email" name="email" id="email" placeholder="email@domain.com" required value="{{ old('email') }}">
                </div>
                @error('email')<span style="color:var(--err);font-size:12px;margin-top:4px;display:block">{{ $message }}</span>@enderror
            </div>

            <div class="input-group">
                <label>Password</label>
                <div class="input-wrap">
                    <span class="i-icon">
                        <svg viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                    </span>
                    <input type="password" name="password" id="password" placeholder="••••••••" required>
                    <button type="button" class="toggle-pw" id="togglePw" aria-label="Tampilkan password">
                        <svg id="eyeIcon" viewBox="0 0 24 24"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                </div>
                @error('password')<span style="color:var(--err);font-size:12px;margin-top:4px;display:block">{{ $message }}</span>@enderror
            </div>

            <div class="extras">
                <label class="remember">
                    <input type="checkbox" name="remember">
                    <span>Ingat Saya</span>
                </label>
                <a href="{{ route('password.request') }}" class="forgot-link">Lupa Password?</a>
            </div>

            <button type="submit" class="btn-login">Masuk</button>

            <div class="register-line">
                Belum punya akun? <a href="{{ route('register') }}">Daftar sekarang</a>
            </div>
        </form>

    </div>

    {{-- Ionicons --}}
    <script type="module" src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.esm.js"></script>
    <script nomodule src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.js"></script>

    <script>
        // ===== PARTICLES =====
        const container = document.getElementById('particles');
        for (let i = 0; i < 22; i++) {
            const p = document.createElement('div');
            p.className = 'particle';
            const size = Math.random() * 4 + 2;
            p.style.cssText = `
                left: ${Math.random() * 100}%;
                width: ${size}px;
                height: ${size}px;
                animation-duration: ${Math.random() * 12 + 8}s;
                animation-delay: ${Math.random() * 8}s;
                opacity: ${Math.random() * 0.4 + 0.1};
            `;
            container.appendChild(p);
        }

        // ===== TOGGLE PASSWORD =====
        const togglePw  = document.getElementById('togglePw');
        const pwInput   = document.getElementById('password');
        const eyeIcon   = document.getElementById('eyeIcon');
        const eyeOff = `<path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>`;
        const eyeOn  = `<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>`;

        togglePw.addEventListener('click', () => {
            const isHidden = pwInput.type === 'password';
            pwInput.type = isHidden ? 'text' : 'password';
            eyeIcon.innerHTML = isHidden ? eyeOff : eyeOn;
        });

        // ===== CLIENT-SIDE DEMO VALIDATION (untuk development) =====
        // Di production, validasi sepenuhnya ditangani oleh Laravel AuthController
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            const email = document.getElementById('email').value.trim();
            const pass  = document.getElementById('password').value;
            const alert = document.getElementById('alertError');

            // Contoh: jika mau tetap pakai credential hardcoded saat testing tanpa Laravel
            // Hapus blok ini saat sudah pakai Laravel Auth
            const demoEmail = 'qw@aw.com';
            const demoPass  = 'qw@aw.com';

            if (document.querySelector('meta[name="csrf-token"]').content === '{{ csrf_token() }}') {
                // Berarti di environment Laravel nyata — biarkan form POST berjalan normal
                return;
            }

            // Demo mode
            e.preventDefault();
            if (email !== demoEmail || pass !== demoPass) {
                alert.textContent = 'Email atau password salah. Silakan coba lagi.';
                alert.style.display = 'block';
            } else {
                window.location.href = '/tabel';
            }
        });
    </script>

</body>
</html>
