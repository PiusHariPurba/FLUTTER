<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Biodata Personal – Pius Hari Purba</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
    <style>
        /* ===== RESET & BASE ===== */
        *, *::before, *::after {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --navy:    #0a1628;
            --blue:    #1a3a6e;
            --accent:  #4c9be8;
            --gold:    #c9a84c;
            --light:   #f4f6fb;
            --white:   #ffffff;
            --text:    #2e3a4a;
            --muted:   #6b7a8d;
        }

        html { scroll-behavior: smooth; }

        body {
            font-family: 'DM Sans', sans-serif;
            background-color: var(--light);
            color: var(--text);
            overflow-x: hidden;
        }

        /* ===== NAVBAR ===== */
        .navbar {
            background: linear-gradient(135deg, var(--navy) 0%, var(--blue) 100%);
            padding: 0 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            position: sticky;
            top: 0;
            z-index: 100;
            box-shadow: 0 2px 20px rgba(0,0,0,0.25);
        }

        .navbar a {
            color: rgba(255,255,255,0.8);
            padding: 18px 22px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            letter-spacing: 0.5px;
            position: relative;
            transition: color 0.3s ease;
        }

        .navbar a::after {
            content: '';
            position: absolute;
            bottom: 12px;
            left: 22px;
            right: 22px;
            height: 2px;
            background: var(--gold);
            transform: scaleX(0);
            transform-origin: center;
            transition: transform 0.35s cubic-bezier(.4,0,.2,1);
            border-radius: 2px;
        }

        .navbar a:hover { color: var(--white); }
        .navbar a:hover::after { transform: scaleX(1); }
        .navbar a.active { color: var(--white); }
        .navbar a.active::after { transform: scaleX(1); }

        /* ===== HERO / PROFIL ===== */
        .hero {
            background: linear-gradient(160deg, var(--navy) 0%, var(--blue) 60%, #2a5ca8 100%);
            padding: 70px 20px 90px;
            text-align: center;
            position: relative;
            overflow: hidden;
        }

        /* Decorative circles */
        .hero::before, .hero::after {
            content: '';
            position: absolute;
            border-radius: 50%;
            opacity: 0.07;
            background: var(--white);
        }
        .hero::before { width: 500px; height: 500px; top: -200px; left: -150px; }
        .hero::after  { width: 350px; height: 350px; bottom: -150px; right: -100px; }

        .hero-inner {
            position: relative;
            z-index: 1;
            animation: fadeDown 0.9s ease both;
        }

        .foto-wrap {
            display: inline-block;
            position: relative;
            margin-bottom: 20px;
        }

        .foto-wrap::before {
            content: '';
            position: absolute;
            inset: -6px;
            border-radius: 50%;
            background: conic-gradient(var(--gold), var(--accent), var(--gold));
            animation: spin 6s linear infinite;
            z-index: 0;
        }

        .foto-wrap img {
            width: 150px;
            height: 150px;
            border-radius: 50%;
            border: 5px solid var(--navy);
            position: relative;
            z-index: 1;
            object-fit: cover;
            display: block;
        }

        .hero h1 {
            font-family: 'Playfair Display', serif;
            font-size: 36px;
            color: var(--white);
            margin-bottom: 8px;
            letter-spacing: 0.5px;
        }

        .hero .tagline {
            color: var(--gold);
            font-size: 14px;
            font-weight: 400;
            letter-spacing: 2px;
            text-transform: uppercase;
            margin-bottom: 6px;
        }

        .hero .motto {
            color: rgba(255,255,255,0.6);
            font-size: 13px;
            font-style: italic;
            max-width: 480px;
            margin: 0 auto;
            line-height: 1.7;
        }

        /* ===== MAIN CONTENT ===== */
        .main {
            max-width: 960px;
            margin: -40px auto 0;
            padding: 0 20px 60px;
            display: flex;
            gap: 24px;
            position: relative;
            z-index: 2;
        }

        /* ===== CARD ===== */
        .card {
            background: var(--white);
            border-radius: 16px;
            box-shadow: 0 4px 30px rgba(10,22,40,0.09);
            padding: 32px;
            flex: 1;
            animation: fadeUp 0.8s ease both;
        }

        .card:nth-child(2) { animation-delay: 0.15s; }

        .card-title {
            font-family: 'Playfair Display', serif;
            font-size: 20px;
            color: var(--navy);
            margin-bottom: 22px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-title::before {
            content: '';
            display: inline-block;
            width: 4px;
            height: 22px;
            background: var(--gold);
            border-radius: 4px;
            flex-shrink: 0;
        }

        /* ===== ABOUT TABLE ===== */
        .about-table {
            width: 100%;
            border-collapse: collapse;
        }

        .about-table tr {
            border-bottom: 1px solid #eef0f5;
            transition: background 0.2s;
        }

        .about-table tr:last-child { border-bottom: none; }
        .about-table tr:hover { background: #f7f9ff; }

        .about-table td {
            padding: 10px 6px;
            font-size: 14px;
            color: var(--text);
            vertical-align: top;
        }

        .about-table td:first-child {
            font-weight: 500;
            color: var(--muted);
            width: 130px;
            white-space: nowrap;
        }

        .about-table td:nth-child(2) {
            color: var(--muted);
            width: 10px;
            padding: 10px 4px;
        }

        /* ===== TIMELINE ===== */
        .timeline-list {
            position: relative;
            padding-left: 36px;
        }

        .timeline-list::before {
            content: '';
            position: absolute;
            left: 7px;
            top: 8px;
            bottom: 8px;
            width: 3px;
            background: linear-gradient(to bottom, var(--accent), var(--gold));
            border-radius: 3px;
        }

        .t-event {
            position: relative;
            margin-bottom: 28px;
            animation: fadeLeft 0.7s ease both;
        }

        .t-event:nth-child(1) { animation-delay: 0.2s; }
        .t-event:nth-child(2) { animation-delay: 0.35s; }
        .t-event:nth-child(3) { animation-delay: 0.5s; }
        .t-event:last-child   { margin-bottom: 0; }

        .t-event::before {
            content: '';
            position: absolute;
            left: -30px;
            top: 6px;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            background: var(--white);
            border: 3px solid var(--accent);
            box-shadow: 0 0 0 4px rgba(76,155,232,0.12);
            transition: transform 0.3s ease, border-color 0.3s;
        }

        .t-event:hover::before {
            transform: scale(1.3);
            border-color: var(--gold);
        }

        .t-event h3 {
            font-size: 15px;
            font-weight: 600;
            color: var(--navy);
            margin-bottom: 3px;
        }

        .t-event .year {
            font-size: 12px;
            color: var(--muted);
            letter-spacing: 0.5px;
        }

        .t-event .badge {
            display: inline-block;
            background: linear-gradient(90deg, var(--accent), #2e78cc);
            color: var(--white);
            font-size: 10px;
            font-weight: 600;
            letter-spacing: 1px;
            padding: 2px 8px;
            border-radius: 20px;
            margin-top: 4px;
            text-transform: uppercase;
        }

        /* ===== KONTAK ===== */
        .kontak-section {
            max-width: 960px;
            margin: 0 auto 60px;
            padding: 0 20px;
            animation: fadeUp 1s ease 0.3s both;
        }

        .kontak-card {
            background: linear-gradient(135deg, var(--navy) 0%, var(--blue) 100%);
            border-radius: 20px;
            padding: 40px;
            position: relative;
            overflow: hidden;
            box-shadow: 0 8px 40px rgba(10,22,40,0.18);
        }

        .kontak-card::before {
            content: '';
            position: absolute;
            width: 300px; height: 300px;
            border-radius: 50%;
            background: rgba(255,255,255,0.04);
            top: -100px; right: -80px;
            pointer-events: none;
        }

        .kontak-card::after {
            content: '';
            position: absolute;
            width: 200px; height: 200px;
            border-radius: 50%;
            background: rgba(201,168,76,0.08);
            bottom: -60px; left: -60px;
            pointer-events: none;
        }

        .kontak-title {
            font-family: 'Playfair Display', serif;
            font-size: 22px;
            color: var(--white);
            margin-bottom: 8px;
            position: relative;
            z-index: 1;
        }

        .kontak-sub {
            color: rgba(255,255,255,0.5);
            font-size: 13px;
            margin-bottom: 30px;
            position: relative;
            z-index: 1;
        }

        .kontak-links {
            display: flex;
            gap: 16px;
            flex-wrap: wrap;
            position: relative;
            z-index: 1;
        }

        .kontak-btn {
            display: flex;
            align-items: center;
            gap: 12px;
            background: rgba(255,255,255,0.09);
            border: 1px solid rgba(255,255,255,0.15);
            border-radius: 14px;
            padding: 14px 22px;
            text-decoration: none;
            color: var(--white);
            font-size: 14px;
            font-weight: 500;
            transition: background 0.3s, transform 0.25s, border-color 0.3s;
            backdrop-filter: blur(6px);
        }

        .kontak-btn:hover {
            background: rgba(255,255,255,0.18);
            border-color: var(--gold);
            transform: translateY(-3px);
        }

        .kontak-btn .icon-wrap {
            width: 38px;
            height: 38px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .kontak-btn.ig .icon-wrap  { background: linear-gradient(135deg,#f09433,#e6683c,#dc2743,#cc2366,#bc1888); }
        .kontak-btn.wa .icon-wrap  { background: #25D366; }

        .kontak-btn .icon-wrap svg { width: 20px; height: 20px; fill: white; }

        .kontak-btn .detail { display: flex; flex-direction: column; }
        .kontak-btn .platform { font-size: 11px; color: rgba(255,255,255,0.5); margin-bottom: 1px; text-transform: uppercase; letter-spacing: 0.8px; }
        .kontak-btn .handle   { font-size: 14px; font-weight: 600; }

        /* ===== AUDIO ===== */
        .audio-wrap {
            text-align: center;
            padding: 10px 20px 0;
        }
        .audio-wrap audio { height: 32px; opacity: 0.7; }

        /* ===== ANIMATIONS ===== */
        @keyframes fadeDown {
            from { opacity: 0; transform: translateY(-30px); }
            to   { opacity: 1; transform: translateY(0); }
        }

        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(30px); }
            to   { opacity: 1; transform: translateY(0); }
        }

        @keyframes fadeLeft {
            from { opacity: 0; transform: translateX(-20px); }
            to   { opacity: 1; transform: translateX(0); }
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* ===== RESPONSIVE ===== */
        @media (max-width: 768px) {
            .main { flex-direction: column; }
            .navbar { flex-wrap: wrap; padding: 0 10px; }
            .navbar a { padding: 12px 14px; font-size: 13px; }
            .kontak-links { flex-direction: column; }
            .kontak-card { padding: 28px 20px; }
        }
    </style>
</head>
<body>

{{-- ===== NAVBAR ===== --}}
<nav class="navbar">
    <a href="{{ route('biodata') }}" class="active">Biodata Personal</a>
    <a href="{{ route('penugasan') }}">Penugasan</a>
    <a href="{{ route('laman-pengunjung') }}">Laman Pengunjung</a>
    <a href="{{ route('login') }}">Log-in</a>
</nav>

{{-- ===== HERO ===== --}}
<section class="hero">
    <div class="hero-inner">
        <div class="foto-wrap">
            <img src="{{ asset('images/pp.jpg') }}" alt="Foto Profil Pius">
        </div>
        <div class="tagline">Mahasiswa Informatika</div>
        <h1>Pius Hari Purba</h1>
        <p class="motto">"Faith is when we take an umbrella before praying for rain."</p>
    </div>
</section>

{{-- ===== AUDIO ===== --}}
<div class="audio-wrap">
    <audio controls autoplay>
        <source src="{{ asset('audio/instrukaro.mp3') }}" type="audio/mpeg">
    </audio>
</div>

{{-- ===== MAIN: ABOUT + TIMELINE ===== --}}
<div class="main">

    {{-- About Card --}}
    <div class="card">
        <div class="card-title">About</div>
        <table class="about-table">
            <tr><td>Nama</td><td>:</td><td>Pius Hari Purba</td></tr>
            <tr><td>NRP</td><td>:</td><td>241210160165</td></tr>
            <tr><td>Jenis Kelamin</td><td>:</td><td>Laki-laki</td></tr>
            <tr><td>Tempat / TTL</td><td>:</td><td>Medan, 09 Mei 200X</td></tr>
            <tr><td>Agama</td><td>:</td><td>Kristen Protestan</td></tr>
            <tr><td>Alamat</td><td>:</td><td>Gg Kekeyi No 47, Lamongan, Jawa Timur</td></tr>
        </table>
    </div>

    {{-- Timeline Card --}}
    <div class="card">
        <div class="card-title">Education Timeline</div>
        <div class="timeline-list">
            <div class="t-event">
                <h3>SD Antonius Medan</h3>
                <div class="year">2005 – 2011</div>
                <span class="badge">Sekolah Dasar</span>
            </div>
            <div class="t-event">
                <h3>SMP Putri Cahaya Medan</h3>
                <div class="year">2011 – 2014</div>
                <span class="badge">Sekolah Menengah Pertama</span>
            </div>
            <div class="t-event">
                <h3>SMA Negeri 4 Medan</h3>
                <div class="year">2014 – 2017</div>
                <span class="badge">Sekolah Menengah Atas</span>
            </div>
        </div>
    </div>

</div>

{{-- ===== KONTAK ===== --}}
<section class="kontak-section">
    <div class="kontak-card">
        <div class="kontak-title">Hubungi Saya</div>
        <div class="kontak-sub">Tersedia di platform berikut</div>

        <div class="kontak-links">

            {{-- Instagram --}}
            <a href="https://www.instagram.com/pius_purba257?igsh=MWFkeHptY2I2cGpwZw==" target="_blank" class="kontak-btn ig">
                <div class="icon-wrap">
                    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                    </svg>
                </div>
                <div class="detail">
                    <span class="platform">Instagram</span>
                    <span class="handle">@pius_purba257</span>
                </div>
            </a>

            {{-- WhatsApp --}}
            <a href="https://wa.me/qr/URYKBAWE6FSKG1" target="_blank" class="kontak-btn wa">
                <div class="icon-wrap">
                    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                    </svg>
                </div>
                <div class="detail">
                    <span class="platform">WhatsApp</span>
                    <span class="handle">0838-7083-2740</span>
                </div>
            </a>

        </div>
    </div>
</section>

</body>
</html>
