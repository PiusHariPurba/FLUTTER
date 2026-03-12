{{-- ============================================================ --}}
{{-- FILE   : biodata.blade.php                                   --}}
{{-- TUJUAN : Halaman utama biodata personal Pius Hari Purba.     --}}
{{--          Menampilkan profil, riwayat pendidikan, dan kontak. --}}
{{-- ============================================================ --}}

<!DOCTYPE html>
{{-- Deklarasi tipe dokumen HTML5; memberi tahu browser bahwa dokumen ini menggunakan standar HTML5 --}}
<html lang="id">
{{-- Tag root/akar dokumen HTML. Atribut lang="id" menyatakan bahasa konten adalah Bahasa Indonesia,
     penting untuk aksesibilitas (screen reader) dan optimasi mesin pencari (SEO) --}}
<head>
{{-- Bagian <head> berisi metadata, resource, dan informasi halaman
     yang tidak ditampilkan langsung sebagai konten visual --}}
    <meta charset="UTF-8">
    {{-- Meta tag encoding karakter: UTF-8 mendukung semua karakter Latin termasuk
         huruf beraksara Indonesia, simbol, dan seluruh karakter Unicode --}}
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    {{-- Meta viewport untuk tampilan responsif di perangkat mobile:
         width=device-width  → lebar halaman menyesuaikan lebar layar perangkat
         initial-scale=1.0   → tidak ada zoom awal; tampilan dimulai pada skala 1:1 --}}
    <title>Biodata Personal – Pius Hari Purba</title>
    {{-- Judul halaman yang muncul di tab browser, bookmark, dan hasil mesin pencari --}}
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
    {{-- Mengimpor dua font dari Google Fonts:
         - Playfair Display (berat 600 & 700): font serif klasik-elegan untuk heading/judul
         - DM Sans (berat 300, 400, 500): font sans-serif modern untuk teks isi
         display=swap: browser menampilkan teks dengan font fallback terlebih dahulu
                       sambil menunggu font Google selesai diunduh --}}
    <style>
    {{-- Tag pembuka blok CSS internal; semua aturan gaya halaman ditulis di sini --}}

        /* ===== RESET & BASE ===== */
        /* Bagian reset: menghapus styling bawaan browser dan menetapkan aturan dasar seluruh elemen */

        *, *::before, *::after {
            /* Selector universal: menarget SEMUA elemen HTML beserta pseudo-elemen ::before dan ::after */
            margin: 0;
            /* Menghapus margin bawaan browser pada semua elemen agar tidak ada jarak tak terduga */
            padding: 0;
            /* Menghapus padding bawaan browser pada semua elemen */
            box-sizing: border-box;
            /* Mengubah model kotak: lebar & tinggi elemen kini sudah menyertakan padding dan border,
               sehingga ukuran elemen lebih dapat diprediksi (tidak meluap karena padding/border) */
        }

        :root {
            /* Pseudo-class :root menarget elemen HTML paling atas (setara dengan "html"),
               digunakan untuk mendeklarasikan variabel CSS global yang bisa dipakai di seluruh stylesheet */
            --navy:    #0a1628;
            /* Variabel warna biru-hitam gelap (navy), dipakai untuk latar belakang navbar/hero */
            --blue:    #1a3a6e;
            /* Variabel warna biru tua sedang, dipakai untuk gradien dan latar belakang sekunder */
            --accent:  #4c9be8;
            /* Variabel warna biru cerah (aksen), dipakai pada elemen yang ingin ditonjolkan */
            --gold:    #c9a84c;
            /* Variabel warna emas, dipakai sebagai aksen premium pada garis dan dekorasi */
            --light:   #f4f6fb;
            /* Variabel warna abu-biru sangat terang, dipakai sebagai warna latar halaman */
            --white:   #ffffff;
            /* Variabel warna putih murni, dipakai untuk teks dan latar kartu */
            --text:    #2e3a4a;
            /* Variabel warna teks utama (biru gelap-keabuan), nyaman untuk teks panjang */
            --muted:   #6b7a8d;
            /* Variabel warna teks teredam (abu-biru), untuk label atau teks informasi sekunder */
        }

        html { scroll-behavior: smooth; }
        /* Mengaktifkan animasi scroll halus (smooth scrolling) saat mengklik tautan anchor/internal */

        body {
            /* Elemen <body> adalah wadah utama seluruh konten yang terlihat di halaman */
            font-family: 'DM Sans', sans-serif;
            /* Menetapkan font DM Sans sebagai font utama; sans-serif adalah fallback jika font Google gagal dimuat */
            background-color: var(--light);
            /* Mewarnai latar belakang halaman dengan variabel --light (abu-biru sangat terang) */
            color: var(--text);
            /* Menetapkan warna teks default menggunakan variabel --text (biru gelap-keabuan) */
            overflow-x: hidden;
            /* Menyembunyikan scrollbar horizontal dan mencegah konten meluap ke sisi kanan halaman */
        }

        /* ===== NAVBAR ===== */
        /* Gaya untuk bar navigasi yang menempel (sticky) di bagian atas halaman */

        .navbar {
            /* Kelas .navbar diterapkan pada elemen <nav> yang berisi semua tautan menu */
            background: linear-gradient(135deg, var(--navy) 0%, var(--blue) 100%);
            /* Latar belakang navbar: gradien linear diagonal 135° dari navy (kiri-atas) ke biru (kanan-bawah) */
            padding: 0 40px;
            /* Padding vertikal 0 (tinggi diatur oleh padding link), horizontal 40px agar ada jarak dari tepi */
            display: flex;
            /* Mengaktifkan tata letak Flexbox agar tautan-tautan ditata dalam satu baris horizontal */
            align-items: center;
            /* Menyelaraskan tautan secara vertikal di tengah navbar */
            justify-content: center;
            /* Menyelaraskan tautan secara horizontal di tengah navbar */
            gap: 8px;
            /* Jarak antar tautan navigasi sebesar 8px */
            position: sticky;
            /* Navbar mengikuti scroll pengguna (menempel di atas viewport) */
            top: 0;
            /* Navbar menempel tepat di paling atas viewport saat halaman di-scroll */
            z-index: 100;
            /* Navbar selalu tampil di depan (di atas) elemen lain karena nilai z-index yang tinggi */
            box-shadow: 0 2px 20px rgba(0,0,0,0.25);
            /* Bayangan di bawah navbar: geser vertikal 2px, blur 20px, warna hitam 25% transparan */
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
            /* Pseudo-elemen ::after membuat garis bawah animasi yang tersembunyi secara default */
            content: '';
            /* Konten kosong (wajib) agar pseudo-elemen ter-render di DOM */
            position: absolute;
            /* Posisi absolut terhadap tautan parent (yang punya position: relative) */
            bottom: 12px;
            /* Garis ditempatkan 12px dari bawah area tautan */
            left: 22px;
            /* Garis dimulai dari 22px kiri (sejajar dengan padding-left tautan) */
            right: 22px;
            /* Garis berakhir 22px dari kanan (sejajar dengan padding-right tautan) */
            height: 2px;
            /* Ketebalan garis bawah 2px */
            background: var(--gold);
            /* Warna garis bawah: emas dari variabel --gold */
            transform: scaleX(0);
            /* Garis disembunyikan awalnya dengan mengecilkan skala horizontal menjadi 0 */
            transform-origin: center;
            /* Transformasi bermula dari tengah sehingga garis melebar ke kedua sisi bersamaan */
            transition: transform 0.35s cubic-bezier(.4,0,.2,1);
            /* Animasi 0.35 detik dengan kurva Material Design (akselerasi-deselerasi halus) */
            border-radius: 2px;
            /* Ujung garis sedikit membulat */
        }

        .navbar a:hover { color: var(--white); }
        /* Saat tautan di-hover, warna teks berubah dari putih 80% menjadi putih penuh */
        .navbar a:hover::after { transform: scaleX(1); }
        .navbar a.active { color: var(--white); }
        .navbar a.active::after { transform: scaleX(1); }

        .hero {
            /* Kelas .hero diterapkan pada <section> yang berisi foto profil, tagline, nama, dan motto */
            background: linear-gradient(160deg, var(--navy) 0%, var(--blue) 60%, #2a5ca8 100%);
            /* Gradien tiga warna diagonal 160°:
               - navy (biru-hitam) di titik 0%
               - biru tua di titik 60%
               - biru medium (#2a5ca8) di titik 100%
               Menciptakan kedalaman warna yang menarik di latar hero */
            padding: 70px 20px 90px;
            /* Padding atas 70px, kiri-kanan 20px, bawah 90px (lebih besar agar
               kartu utama bisa overlap/menimpa hero dari bawah secara estetis) */
            text-align: center;
            /* Memusatkan semua konten hero secara horizontal */
            position: relative;
            /* Posisi relative agar dekorasi lingkaran (::before & ::after) bisa
               diposisikan secara absolut di dalam area hero */
            overflow: hidden;
            /* Menyembunyikan bagian lingkaran dekoratif yang melampaui batas hero */
        }

        /* Decorative circles */
        /* Dua lingkaran transparan besar sebagai elemen dekoratif latar hero */

        .hero::before, .hero::after {
            /* Pseudo-elemen untuk kedua lingkaran dekoratif di sudut hero */
            content: '';
            /* Konten kosong (wajib) agar pseudo-elemen muncul di DOM */
            position: absolute;
            /* Posisi absolut agar lingkaran bisa ditempatkan bebas di dalam hero */
            border-radius: 50%;
            /* Mengubah kotak menjadi lingkaran penuh */
            opacity: 0.07;
            /* Sangat transparan (7%) agar terlihat sebagai latar halus, tidak mengganggu konten */
            background: var(--white);
            /* Lingkaran berwarna putih; dengan opacity 7% tampak sebagai cahaya samar */
        }

        .hero::before { width: 500px; height: 500px; top: -200px; left: -150px; }
        /* Lingkaran besar kiri-atas: 500×500px, sebagian besar di luar area hero (koordinat negatif) */

        .hero::after  { width: 350px; height: 350px; bottom: -150px; right: -100px; }
        /* Lingkaran lebih kecil kanan-bawah: 350×350px, sebagian di luar batas hero */

        .hero-inner {
            /* Div pembungkus konten dalam hero (foto, tagline, nama, motto) */
            position: relative;
            /* Posisi relative agar z-index berlaku, konten tampil di atas pseudo-elemen dekoratif */
            z-index: 1;
            /* Memastikan konten hero berada di lapisan atas (di depan lingkaran dekoratif z-index: 0) */
            animation: fadeDown 0.9s ease both;
            /* Animasi masuk dari atas: keyframe "fadeDown", durasi 0.9 detik, easing "ease",
               "both" = keyframe awal dan akhir diterapkan sebelum/sesudah animasi berjalan */
        }

        .foto-wrap {
            /* Container untuk foto profil beserta efek cincin berputar di sekelilingnya */
            display: inline-block;
            /* Tampil sebagai inline-block agar lebar menyesuaikan konten dan bisa ditengahkan via text-align */
            position: relative;
            /* Posisi relative agar pseudo-elemen ::before (cincin putar) bisa diposisikan di sekitarnya */
            margin-bottom: 20px;
            /* Jarak bawah 20px antara foto dan teks tagline */
        }

        .foto-wrap::before {
            /* Pseudo-elemen yang membentuk cincin gradien berputar di sekeliling foto profil */
            content: '';
            /* Wajib ada meski kosong agar pseudo-elemen muncul di DOM */
            position: absolute;
            /* Posisi absolut relatif terhadap .foto-wrap */
            inset: -6px;
            /* Shorthand untuk top/right/bottom/left: -6px; memperluas pseudo-elemen 6px ke semua sisi */
            border-radius: 50%;
            /* Membentuk pseudo-elemen menjadi lingkaran */
            background: conic-gradient(var(--gold), var(--accent), var(--gold));
            /* Gradien konik (melingkar): dari emas → biru accent → emas kembali,
               menciptakan efek cincin dengan perpaduan warna yang kaya */
            animation: spin 6s linear infinite;
            /* Animasi rotasi: keyframe "spin", durasi 6 detik, kecepatan konstan (linear), berulang tanpa henti */
            z-index: 0;
            /* Berada di belakang gambar foto (foto punya z-index: 1) */
        }

        .foto-wrap img {
            /* Gaya untuk elemen gambar foto profil */
            width: 150px;
            /* Lebar gambar 150px */
            height: 150px;
            /* Tinggi gambar 150px (membentuk persegi sebelum dibulatkan) */
            border-radius: 50%;
            /* Memotong gambar menjadi bentuk lingkaran */
            border: 5px solid var(--navy);
            /* Border 5px warna navy sebagai pemisah antara foto dan cincin agar keduanya terlihat kontras */
            position: relative;
            /* Posisi relative agar z-index berlaku terhadap pseudo-elemen ::before parent */
            z-index: 1;
            /* Foto berada di depan cincin gradien (::before z-index: 0) */
            object-fit: cover;
            /* Gambar dipotong dan diperbesar untuk mengisi container tanpa distorsi (rasio aspek dijaga) */
            display: block;
            /* Menghilangkan ruang kosong bawaan inline image yang bisa menyebabkan celah kecil di bawah */
        }

        .hero h1 {
            /* Gaya untuk heading nama lengkap di dalam hero */
            font-family: 'Playfair Display', serif;
            /* Font Playfair Display yang elegan untuk nama agar terkesan formal dan prestisius */
            font-size: 36px;
            /* Ukuran teks 36px, besar dan menonjol sebagai elemen utama hero */
            color: var(--white);
            /* Teks putih kontras dengan latar hero yang gelap */
            margin-bottom: 8px;
            /* Jarak bawah 8px antara nama dan tagline */
            letter-spacing: 0.5px;
            /* Jarak antar karakter sedikit diperlebar untuk kesan premium */
        }

        .hero .tagline {
            /* Gaya untuk teks tagline/sub-judul (contoh: "Mahasiswa Informatika") */
            color: var(--gold);
            /* Warna emas untuk membedakan tagline dari teks lain dan memberi kesan premium */
            font-size: 14px;
            /* Ukuran teks kecil, berfungsi sebagai teks pendukung di bawah nama */
            font-weight: 400;
            /* Ketebalan normal (regular), tidak tebal */
            letter-spacing: 2px;
            /* Jarak antar karakter lebar (2px) untuk efek "spaced-out" yang elegan */
            text-transform: uppercase;
            /* Semua karakter diubah ke huruf kapital */
            margin-bottom: 6px;
            /* Jarak bawah 6px sebelum elemen berikutnya */
        }

        .hero .motto {
            /* Gaya untuk teks motto/kutipan inspiratif di bawah nama */
            color: rgba(255,255,255,0.6);
            /* Putih 60% transparan agar motto tampil lebih lembut, tidak sepenting nama */
            font-size: 13px;
            /* Ukuran kecil agar motto tidak mendominasi visual hero */
            font-style: italic;
            /* Teks miring (italic) untuk menandakan ini adalah kutipan */
            max-width: 480px;
            /* Lebar maksimum 480px agar teks tidak terlalu panjang per baris (lebih mudah dibaca) */
            margin: 0 auto;
            /* Margin kiri-kanan otomatis agar motto terpusat secara horizontal */
            line-height: 1.7;
            /* Tinggi baris 1.7× ukuran font, memberikan jarak antar baris yang nyaman untuk dibaca */
        }

        /* ===== MAIN CONTENT ===== */
        /* Gaya untuk container utama yang menampung dua kartu: About dan Education Timeline */

        .main {
            /* Container utama (Flexbox) yang menampung dua kartu informasi secara berdampingan */
            max-width: 960px;
            /* Lebar maksimum 960px agar konten tidak terlalu lebar di layar besar */
            margin: -40px auto 0;
            /* -40px di atas: kartu "naik" overlap dengan hero (efek estetis kartu keluar dari hero)
               auto kiri-kanan: container terpusat secara horizontal
               0 di bawah: tidak ada margin tambahan di bawah */
            padding: 0 20px 60px;
            /* Tidak ada padding atas, kiri-kanan 20px agar tidak menyentuh tepi layar,
               bawah 60px untuk jarak sebelum seksi kontak */
            display: flex;
            /* Flexbox agar dua kartu tampil berdampingan secara horizontal */
            gap: 24px;
            /* Jarak antar kartu 24px */
            position: relative;
            /* Posisi relative agar z-index berlaku (kartu harus tampil di atas hero) */
            z-index: 2;
            /* z-index 2 memastikan container berada di atas elemen hero (z-index: 1) */
        }

        /* ===== CARD ===== */
        /* Gaya umum untuk setiap kartu informasi (About & Education Timeline) */

        .card {
            /* Kelas .card diterapkan pada setiap div kartu informasi */
            background: var(--white);
            /* Latar belakang kartu putih, kontras dengan halaman --light */
            border-radius: 16px;
            /* Sudut kartu membulat 16px untuk tampilan modern dan ramah */
            box-shadow: 0 4px 30px rgba(10,22,40,0.09);
            /* Bayangan kartu: geser bawah 4px, blur 30px, warna navy 9% transparan (bayangan sangat halus) */
            padding: 32px;
            /* Ruang dalam (padding) 32px di semua sisi agar konten kartu tidak terlalu rapat ke tepi */
            flex: 1;
            /* Kartu memperluas diri secara merata mengisi sisa ruang Flexbox (kedua kartu sama lebar) */
            animation: fadeUp 0.8s ease both;
            /* Animasi masuk dari bawah: keyframe "fadeUp", durasi 0.8 detik */
        }

        .card:nth-child(2) { animation-delay: 0.15s; }
        /* Kartu kedua (Timeline) muncul 0.15 detik lebih lambat dari kartu pertama (About),
           menciptakan efek staggered (berurutan) yang lebih menarik */

        .card-title {
            /* Gaya untuk judul di dalam setiap kartu (contoh: "About", "Education Timeline") */
            font-family: 'Playfair Display', serif;
            /* Font elegan Playfair Display untuk judul kartu */
            font-size: 20px;
            /* Ukuran judul kartu 20px */
            color: var(--navy);
            /* Warna teks navy gelap agar kontras dengan latar kartu putih */
            margin-bottom: 22px;
            /* Jarak bawah 22px antara judul dan konten kartu */
            display: flex;
            /* Flexbox agar tanda aksen (::before) dan teks judul sejajar secara vertikal */
            align-items: center;
            /* Menyelaraskan tanda aksen dan teks di tengah secara vertikal */
            gap: 10px;
            /* Jarak antara tanda aksen dan teks judul 10px */
        }

        .card-title::before {
            /* Pseudo-elemen sebagai garis/tanda aksen vertikal berwarna emas di kiri judul */
            content: '';
            /* Konten kosong agar pseudo-elemen muncul */
            display: inline-block;
            /* Ditampilkan sebagai inline-block agar bisa diberi width dan height */
            width: 4px;
            /* Lebar tanda aksen 4px (tipis) */
            height: 22px;
            /* Tinggi tanda aksen 22px, kira-kira setara tinggi teks judul */
            background: var(--gold);
            /* Tanda aksen berwarna emas */
            border-radius: 4px;
            /* Ujung atas dan bawah tanda aksen sedikit membulat */
            flex-shrink: 0;
            /* Mencegah tanda aksen menyusut walau ruang Flexbox terbatas */
        }

        /* ===== ABOUT TABLE ===== */
        /* Gaya untuk tabel data biodata personal */

        .about-table {
            /* Tabel HTML yang menampilkan data biodata dalam format baris-kolom */
            width: 100%;
            /* Tabel memenuhi seluruh lebar container kartu */
            border-collapse: collapse;
            /* Menggabungkan border sel yang bersebelahan menjadi satu garis,
               menghilangkan celah antar sel */
        }

        .about-table tr {
            /* Gaya untuk setiap baris (<tr>) dalam tabel */
            border-bottom: 1px solid #eef0f5;
            /* Garis pemisah horizontal di bawah setiap baris dengan warna abu-biru sangat terang */
            transition: background 0.2s;
            /* Animasi perubahan warna latar baris saat hover berlangsung selama 0.2 detik */
        }

        .about-table tr:last-child { border-bottom: none; }
        /* Baris terakhir tidak memiliki garis bawah agar tampilan lebih bersih dan tidak "tumpang") */

        .about-table tr:hover { background: #f7f9ff; }
        /* Saat cursor diarahkan ke baris, latar berubah ke biru sangat terang untuk efek interaktif */

        .about-table td {
            /* Gaya untuk setiap sel data (<td>) dalam tabel */
            padding: 10px 6px;
            /* Padding vertikal 10px, horizontal 6px agar konten sel tidak terlalu rapat ke tepi */
            font-size: 14px;
            /* Ukuran teks dalam sel 14px */
            color: var(--text);
            /* Warna teks menggunakan variabel --text (biru gelap-keabuan) */
            vertical-align: top;
            /* Konten sel rata ke atas (berguna jika sel sejajar berbeda ketinggian karena konten panjang) */
        }

        .about-table td:first-child {
            /* Sel kolom pertama: berisi label biodata (contoh: "Nama", "NRP", "Alamat") */
            font-weight: 500;
            /* Teks label sedikit lebih tebal (medium) agar mudah dibedakan dari nilai */
            color: var(--muted);
            /* Warna teredam untuk label, memberi fokus visual ke kolom nilai */
            width: 130px;
            /* Lebar kolom label ditetapkan 130px agar semua baris memiliki lebar label yang konsisten */
            white-space: nowrap;
            /* Mencegah teks label terpotong/berpindah baris walau ruang terbatas */
        }

        .about-table td:nth-child(2) {
            /* Sel kolom kedua: berisi karakter pemisah ":" */
            color: var(--muted);
            /* Warna teredam agar titik dua tidak terlalu mencolok */
            width: 10px;
            /* Lebar kolom sangat kecil karena hanya memuat satu karakter ":" */
            padding: 10px 4px;
            /* Padding horizontal dikurangi (4px) agar titik dua lebih rapat ke label dan nilai */
        }

        /* ===== TIMELINE ===== */
        /* Gaya untuk komponen timeline riwayat pendidikan */

        .timeline-list {
            /* Container daftar event timeline */
            position: relative;
            /* Posisi relative agar garis vertikal (pseudo-elemen ::before) bisa diposisikan secara absolut di dalamnya */
            padding-left: 36px;
            /* Ruang di kiri sebesar 36px untuk menempatkan garis vertikal dan lingkaran indikator */
        }

        .timeline-list::before {
            /* Pseudo-elemen yang membentuk garis vertikal gradien di sepanjang timeline */
            content: '';
            /* Konten kosong agar pseudo-elemen muncul */
            position: absolute;
            /* Posisi absolut relatif terhadap .timeline-list */
            left: 7px;
            /* Garis ditempatkan 7px dari tepi kiri container */
            top: 8px;
            /* Garis dimulai 8px dari atas agar tidak tepat di ujung container */
            bottom: 8px;
            /* Garis berakhir 8px dari bawah agar tidak tepat di ujung terbawah */
            width: 3px;
            /* Ketebalan garis timeline 3px */
            background: linear-gradient(to bottom, var(--accent), var(--gold));
            /* Gradien vertikal: biru accent di atas ke emas di bawah, memberi efek visual dinamis */
            border-radius: 3px;
            /* Ujung atas dan bawah garis sedikit membulat */
        }

        .t-event {
            /* Gaya untuk setiap item/event riwayat pendidikan dalam timeline */
            position: relative;
            /* Posisi relative agar lingkaran indikator (::before) bisa diposisikan absolut terhadapnya */
            margin-bottom: 28px;
            /* Jarak bawah 28px antar event untuk breathing room yang cukup */
            animation: fadeLeft 0.7s ease both;
            /* Animasi masuk dari kiri: keyframe "fadeLeft", durasi 0.7 detik */
        }

        .t-event:nth-child(1) { animation-delay: 0.2s; }
        /* Event pertama (SD) muncul 0.2 detik setelah halaman dimuat */

        .t-event:nth-child(2) { animation-delay: 0.35s; }
        /* Event kedua (SMP) muncul 0.35 detik setelah halaman dimuat (staggered) */

        .t-event:nth-child(3) { animation-delay: 0.5s; }
        /* Event ketiga (SMA) muncul 0.5 detik setelah halaman dimuat (staggered paling lambat) */

        .t-event:last-child   { margin-bottom: 0; }
        /* Event terakhir tidak punya margin bawah agar tidak ada ruang kosong berlebih di bawahnya */

        .t-event::before {
            /* Pseudo-elemen sebagai lingkaran indikator yang menandai setiap event di garis timeline */
            content: '';
            /* Konten kosong agar pseudo-elemen muncul */
            position: absolute;
            /* Posisi absolut relatif terhadap .t-event parent */
            left: -30px;
            /* Lingkaran ditempatkan 30px ke kiri dari tepi kiri event, tepat di atas garis timeline */
            top: 6px;
            /* Lingkaran sejajar dengan baris pertama teks event (judul institusi) */
            width: 14px;
            height: 14px;
            /* Ukuran lingkaran indikator 14×14px */
            border-radius: 50%;
            /* Membuat elemen berbentuk lingkaran penuh */
            background: var(--white);
            /* Isi lingkaran putih agar kontras dengan border berwarna */
            border: 3px solid var(--accent);
            /* Border 3px biru accent untuk menonjolkan setiap event */
            box-shadow: 0 0 0 4px rgba(76,155,232,0.12);
            /* Efek glow halus di sekeliling lingkaran: spread 4px, warna accent 12% transparan */
            transition: transform 0.3s ease, border-color 0.3s;
            /* Animasi perubahan ukuran dan warna border lingkaran saat hover, masing-masing 0.3 detik */
        }

        .t-event:hover::before {
            /* Efek pada lingkaran indikator saat event di-hover */
            transform: scale(1.3);
            /* Lingkaran membesar 130% dari ukuran aslinya untuk efek interaktif visual */
            border-color: var(--gold);
            /* Warna border berubah dari biru accent menjadi emas saat hover */
        }

        .t-event h3 {
            /* Gaya untuk nama institusi pendidikan (judul setiap event) */
            font-size: 15px;
            /* Ukuran teks nama institusi 15px */
            font-weight: 600;
            /* Teks semi-bold (tebal) agar nama institusi menonjol sebagai poin utama */
            color: var(--navy);
            /* Warna teks navy gelap */
            margin-bottom: 3px;
            /* Jarak bawah kecil 3px antara nama institusi dan tahun */
        }

        .t-event .year {
            /* Gaya untuk teks rentang tahun (contoh: "2005 – 2011") */
            font-size: 12px;
            /* Ukuran teks kecil, sebagai informasi pendukung */
            color: var(--muted);
            /* Warna teredam agar tahun tidak terlalu menonjol dibanding nama institusi */
            letter-spacing: 0.5px;
            /* Sedikit jarak antar karakter untuk keterbacaan lebih baik */
        }

        .t-event .badge {
            /* Gaya untuk label tingkatan pendidikan berbentuk "pill badge" (contoh: "Sekolah Dasar") */
            display: inline-block;
            /* Tampil inline-block agar badge hanya selebar kontennya dan bisa diberi padding */
            background: linear-gradient(90deg, var(--accent), #2e78cc);
            /* Gradien horizontal dari biru accent ke biru gelap */
            color: var(--white);
            /* Teks badge putih untuk kontras dengan latar biru */
            font-size: 10px;
            /* Ukuran teks sangat kecil (10px) agar badge tidak mendominasi tampilan event */
            font-weight: 600;
            /* Teks tebal agar tetap terbaca walau ukurannya kecil */
            letter-spacing: 1px;
            /* Jarak antar karakter lebar agar badge terbaca dengan baik */
            padding: 2px 8px;
            /* Padding vertikal 2px, horizontal 8px agar badge tidak terlalu mepet */
            border-radius: 20px;
            /* Sudut membulat ekstrem (20px) menciptakan tampilan "pill badge" */
            margin-top: 4px;
            /* Jarak atas 4px antara teks tahun dan badge */
            text-transform: uppercase;
            /* Semua karakter badge diubah ke huruf kapital */
        }

        /* ===== KONTAK ===== */
        /* Gaya untuk seksi kontak sosial di bagian bawah halaman */

        .kontak-section {
            /* Container section yang membungkus kartu kontak */
            max-width: 960px;
            /* Lebar maksimum sejajar dengan .main (960px) agar konten selaras */
            margin: 0 auto 60px;
            /* Tidak ada margin atas, auto kiri-kanan untuk memusatkan, bawah 60px sebelum akhir halaman */
            padding: 0 20px;
            /* Padding kiri-kanan 20px agar konten tidak menyentuh tepi layar */
            animation: fadeUp 1s ease 0.3s both;
            /* Animasi masuk dari bawah: durasi 1 detik, delay 0.3 detik agar muncul setelah kartu utama */
        }

        .kontak-card {
            /* Kartu kontak berlatar gelap dengan dekorasi lingkaran estetis */
            background: linear-gradient(135deg, var(--navy) 0%, var(--blue) 100%);
            /* Gradien diagonal dari navy ke biru, konsisten dengan navbar */
            border-radius: 20px;
            /* Sudut lebih besar (20px) dibanding kartu biasa untuk kesan premium */
            padding: 40px;
            /* Padding besar agar konten terasa lega dan tidak sesak */
            position: relative;
            /* Posisi relative agar pseudo-elemen dekoratif bisa diposisikan absolut di dalamnya */
            overflow: hidden;
            /* Menyembunyikan bagian lingkaran dekoratif yang keluar dari batas kartu */
            box-shadow: 0 8px 40px rgba(10,22,40,0.18);
            /* Bayangan lebih dalam dari kartu biasa: geser bawah 8px, blur 40px, navy 18% transparan */
        }

        .kontak-card::before {
            /* Pseudo-elemen: lingkaran dekoratif besar di sudut kanan atas kartu */
            content: '';
            /* Konten kosong agar pseudo-elemen muncul */
            position: absolute;
            /* Posisi absolut di dalam .kontak-card */
            width: 300px; height: 300px;
            /* Ukuran lingkaran 300×300px */
            border-radius: 50%;
            /* Berbentuk lingkaran */
            background: rgba(255,255,255,0.04);
            /* Putih 4% transparan, sangat samar sebagai dekorasi */
            top: -100px; right: -80px;
            /* Diposisikan sebagian di luar sudut kanan atas kartu */
            pointer-events: none;
            /* Lingkaran tidak bisa diklik/disentuh sehingga tidak menghalangi interaksi */
        }

        .kontak-card::after {
            /* Pseudo-elemen: lingkaran dekoratif lebih kecil di sudut kiri bawah kartu */
            content: '';
            /* Konten kosong agar pseudo-elemen muncul */
            position: absolute;
            /* Posisi absolut di dalam .kontak-card */
            width: 200px; height: 200px;
            /* Ukuran lingkaran 200×200px */
            border-radius: 50%;
            /* Berbentuk lingkaran */
            background: rgba(201,168,76,0.08);
            /* Warna emas 8% transparan untuk sentuhan hangat di sudut kiri bawah */
            bottom: -60px; left: -60px;
            /* Diposisikan sebagian keluar dari sudut kiri bawah kartu */
            pointer-events: none;
            /* Tidak bisa diklik/disentuh */
        }

        .kontak-title {
            /* Gaya untuk judul "Hubungi Saya" di dalam kartu kontak */
            font-family: 'Playfair Display', serif;
            /* Font Playfair Display elegan untuk judul */
            font-size: 22px;
            /* Ukuran judul 22px */
            color: var(--white);
            /* Teks putih kontras dengan latar gelap */
            margin-bottom: 8px;
            /* Jarak bawah 8px antara judul dan subjudul */
            position: relative;
            /* Posisi relative agar z-index berlaku (harus tampil di atas pseudo-elemen dekoratif) */
            z-index: 1;
            /* Berada di atas lingkaran dekoratif (z-index > default 0) */
        }

        .kontak-sub {
            /* Gaya untuk subjudul "Tersedia di platform berikut" */
            color: rgba(255,255,255,0.5);
            /* Putih 50% transparan, lebih teredam dibanding judul agar tidak bersaing */
            font-size: 13px;
            /* Ukuran teks kecil sebagai teks pendukung */
            margin-bottom: 30px;
            /* Jarak bawah 30px sebelum tombol-tombol kontak */
            position: relative;
            /* Posisi relative untuk z-index */
            z-index: 1;
            /* Berada di atas pseudo-elemen dekoratif */
        }

        .kontak-links {
            /* Container Flexbox untuk semua tombol tautan kontak */
            display: flex;
            /* Flexbox agar tombol-tombol tampil berdampingan secara horizontal */
            gap: 16px;
            /* Jarak antar tombol 16px */
            flex-wrap: wrap;
            /* Tombol berpindah ke baris baru jika lebar layar tidak mencukupi (responsif) */
            position: relative;
            /* Posisi relative untuk z-index */
            z-index: 1;
            /* Berada di atas pseudo-elemen dekoratif kartu */
        }

        .kontak-btn {
            /* Gaya dasar untuk setiap tombol link kontak (Instagram & WhatsApp) */
            display: flex;
            /* Flexbox agar ikon dan teks di dalam tombol sejajar horizontal */
            align-items: center;
            /* Menyelaraskan ikon dan teks di tengah secara vertikal */
            gap: 12px;
            /* Jarak antara kotak ikon dan teks label 12px */
            background: rgba(255,255,255,0.09);
            /* Latar belakang putih 9% transparan, menciptakan efek frosted-glass halus */
            border: 1px solid rgba(255,255,255,0.15);
            /* Border tipis putih 15% transparan sebagai outline yang samar */
            border-radius: 14px;
            /* Sudut membulat 14px untuk tampilan modern */
            padding: 14px 22px;
            /* Padding vertikal 14px, horizontal 22px untuk area tombol yang cukup besar dan mudah diklik */
            text-decoration: none;
            /* Menghapus underline bawaan tautan HTML */
            color: var(--white);
            /* Teks putih */
            font-size: 14px;
            /* Ukuran teks tombol 14px */
            font-weight: 500;
            /* Ketebalan medium agar teks cukup terbaca */
            transition: background 0.3s, transform 0.25s, border-color 0.3s;
            /* Animasi halus untuk: warna latar (0.3s), posisi vertikal (0.25s), warna border (0.3s) */
            backdrop-filter: blur(6px);
            /* Efek blur 6px pada konten di belakang tombol (glassmorphism) */
        }

        .kontak-btn:hover {
            /* Efek visual saat tombol kontak di-hover */
            background: rgba(255,255,255,0.18);
            /* Latar menjadi lebih terang (18% transparan) dari kondisi normal (9%) */
            border-color: var(--gold);
            /* Border berubah menjadi warna emas saat hover */
            transform: translateY(-3px);
            /* Tombol bergerak 3px ke atas untuk efek "terangkat" yang interaktif */
        }

        .kontak-btn .icon-wrap {
            /* Kotak container untuk ikon SVG platform (Instagram/WhatsApp) */
            width: 38px;
            height: 38px;
            /* Ukuran kotak ikon 38×38px */
            border-radius: 10px;
            /* Sudut membulat 10px agar terlihat modern */
            display: flex;
            align-items: center;
            justify-content: center;
            /* Flexbox: ikon diposisikan tepat di tengah kotak secara horizontal dan vertikal */
            flex-shrink: 0;
            /* Kotak ikon tidak akan menyusut meski ruang Flexbox terbatas */
        }

        .kontak-btn.ig .icon-wrap  { background: linear-gradient(135deg,#f09433,#e6683c,#dc2743,#cc2366,#bc1888); }
        /* Latar kotak ikon Instagram: gradien multiwarna dari kuning-oranye ke pink-merah-magenta
           (warna gradien resmi brand Instagram) */

        .kontak-btn.wa .icon-wrap  { background: #25D366; }
        /* Latar kotak ikon WhatsApp: warna hijau khas/resmi WhatsApp (#25D366) */

        .kontak-btn .icon-wrap svg { width: 20px; height: 20px; fill: white; }
        /* Ikon SVG berukuran 20×20px di dalam kotak; fill white agar putih kontras dengan latar berwarna */

        .kontak-btn .detail { display: flex; flex-direction: column; }
        /* Container teks detail platform: Flexbox kolom agar nama platform dan handle tersusun vertikal */

        .kontak-btn .platform { font-size: 11px; color: rgba(255,255,255,0.5); margin-bottom: 1px; text-transform: uppercase; letter-spacing: 0.8px; }
        /* Teks nama platform (contoh: "INSTAGRAM"): 11px, putih teredam, kapital semua, spasi karakter lebar */

        .kontak-btn .handle   { font-size: 14px; font-weight: 600; }
        /* Teks username/handle (contoh: "@pius_purba257" atau nomor): 14px, semi-bold agar menonjol */

        /* ===== AUDIO ===== */
        /* Gaya untuk pemutar audio yang muncul di bawah hero */

        .audio-wrap {
            /* Container untuk elemen audio */
            text-align: center;
            /* Pemutar audio dicentrasi secara horizontal di halaman */
            padding: 10px 20px 0;
            /* Padding atas 10px dan kiri-kanan 20px; tidak ada padding bawah */
        }

        .audio-wrap audio { height: 32px; opacity: 0.7; }
        /* Mengatur tinggi elemen audio menjadi 32px agar kompak (tidak terlalu besar);
           opacity 70% agar pemutar audio tidak terlalu mencolok dalam visual halaman */

        /* ===== ANIMATIONS ===== */
        /* Definisi keyframe untuk semua animasi yang digunakan dalam halaman */

        @keyframes fadeDown {
            /* Animasi "fadeDown": elemen muncul dari atas ke posisi normal */
            from { opacity: 0; transform: translateY(-30px); }
            /* Titik awal: sepenuhnya transparan (tidak terlihat), bergeser 30px ke atas */
            to   { opacity: 1; transform: translateY(0); }
            /* Titik akhir: sepenuhnya terlihat, di posisi asli */
        }

        @keyframes fadeUp {
            /* Animasi "fadeUp": elemen muncul dari bawah ke posisi normal */
            from { opacity: 0; transform: translateY(30px); }
            /* Titik awal: tidak terlihat, bergeser 30px ke bawah */
            to   { opacity: 1; transform: translateY(0); }
            /* Titik akhir: sepenuhnya terlihat, di posisi asli */
        }

        @keyframes fadeLeft {
            /* Animasi "fadeLeft": elemen muncul dari kiri ke posisi normal */
            from { opacity: 0; transform: translateX(-20px); }
            /* Titik awal: tidak terlihat, bergeser 20px ke kiri */
            to   { opacity: 1; transform: translateX(0); }
            /* Titik akhir: sepenuhnya terlihat, di posisi asli */
        }

        @keyframes spin {
            /* Animasi "spin": rotasi satu putaran penuh untuk cincin foto profil */
            to { transform: rotate(360deg); }
            /* Hanya mendefinisikan titik akhir (360°); browser otomatis mulai dari 0° */
        }

        /* ===== RESPONSIVE ===== */
        /* Aturan media query untuk menyesuaikan tampilan di layar kecil */

        @media (max-width: 768px) {
            /* Blok ini berlaku ketika lebar viewport ≤ 768px (ponsel dan tablet kecil) */
            .main { flex-direction: column; }
            /* Kartu About dan Timeline ditumpuk secara vertikal (bukan berdampingan) di layar kecil */
            .navbar { flex-wrap: wrap; padding: 0 10px; }
            /* Tautan navbar diizinkan membungkus ke baris baru; padding dikurangi dari 40px ke 10px */
            .navbar a { padding: 12px 14px; font-size: 13px; }
            /* Padding dan ukuran font tautan navbar diperkecil agar muat di layar sempit */
            .kontak-links { flex-direction: column; }
            /* Tombol kontak ditampilkan secara vertikal (ditumpuk) di layar kecil */
            .kontak-card { padding: 28px 20px; }
            /* Padding kartu kontak dikurangi dari 40px menjadi 28px-20px agar tidak terlalu sesak */
        }
    </style>
    {{-- Penutup tag <style>: semua CSS internal halaman telah selesai --}}
</head>
{{-- Penutup tag <head>: semua metadata dan resource telah didefinisikan --}}

<body>
{{-- Tag <body> pembuka: seluruh konten yang terlihat di halaman ditulis di dalam tag ini --}}

{{-- ===== NAVBAR ===== --}}
{{-- Komentar Blade: menandai awal komponen navigasi halaman --}}
<nav class="navbar">
{{-- Elemen semantik <nav> dengan kelas .navbar; berisi semua tautan menu halaman --}}
    <a href="{{ route('biodata') }}" class="active">Biodata Personal</a>
    {{-- Tautan ke halaman Biodata Personal:
         route('biodata') → helper Laravel yang menghasilkan URL berdasarkan nama route 'biodata'
         class="active" → memberikan gaya aktif (teks putih penuh + garis bawah emas) karena ini halaman saat ini --}}
    <a href="{{ route('penugasan') }}">Penugasan</a>
    {{-- Tautan ke halaman Penugasan; route('penugasan') menghasilkan URL route bernama 'penugasan' --}}
    <a href="{{ route('laman-pengunjung') }}">Laman Pengunjung</a>
    {{-- Tautan ke halaman Laman Pengunjung; route('laman-pengunjung') menghasilkan URL-nya --}}
    <a href="{{ route('login') }}">Log-in</a>
    {{-- Tautan ke halaman Login; route('login') menghasilkan URL route bernama 'login' --}}
</nav>
{{-- Penutup elemen <nav> --}}

{{-- ===== HERO ===== --}}
{{-- Komentar Blade: menandai awal seksi hero/header visual utama halaman --}}
<section class="hero">
{{-- Elemen semantik <section> dengan kelas .hero; berisi foto profil, tagline, nama, dan motto --}}
    <div class="hero-inner">
    {{-- Div pembungkus konten dalam hero; berfungsi untuk positioning (z-index di atas dekorasi)
         dan menjadi target animasi fadeDown --}}
        <div class="foto-wrap">
        {{-- Div pembungkus foto profil; memiliki pseudo-elemen ::before untuk cincin gradien berputar --}}
            <img src="{{ asset('images/pp.jpg') }}" alt="Foto Profil Pius">
            {{-- Tag gambar foto profil:
                 asset('images/pp.jpg') → helper Laravel menghasilkan URL publik ke file 'public/images/pp.jpg'
                 alt="Foto Profil Pius" → teks alternatif jika gambar gagal dimuat; wajib untuk aksesibilitas --}}
        </div>
        {{-- Penutup .foto-wrap --}}
        <div class="tagline">Mahasiswa Informatika</div>
        {{-- Div tagline: menampilkan peran/status pemilik profil; ditampilkan uppercase berwarna emas --}}
        <h1>Pius Hari Purba</h1>
        {{-- Heading level 1 (h1): nama lengkap pemilik profil; elemen teks terpenting di halaman untuk SEO --}}
        <p class="motto">"Faith is when we take an umbrella before praying for rain."</p>
        {{-- Paragraf motto/kutipan inspiratif pemilik profil; ditampilkan italic dan putih teredam --}}
    </div>
    {{-- Penutup .hero-inner --}}
</section>
{{-- Penutup <section class="hero"> --}}

{{-- ===== AUDIO ===== --}}
{{-- Komentar Blade: menandai area pemutar audio latar halaman --}}
<div class="audio-wrap">
{{-- Container terpusat untuk player audio; diberi padding dan opacity teredam agar tidak mencolok --}}
    <audio controls autoplay>
    {{-- Elemen audio HTML5:
         controls  → menampilkan kontrol bawaan browser (tombol play/pause, volume, progress bar)
         autoplay  → memulai pemutaran otomatis saat halaman pertama kali dimuat
                     (beberapa browser memblokir autoplay tanpa interaksi pengguna terlebih dahulu) --}}
        <source src="{{ asset('audio/instrukaro.mp3') }}" type="audio/mpeg">
        {{-- Sumber file audio:
             asset('audio/instrukaro.mp3') → URL publik ke file 'public/audio/instrukaro.mp3'
             type="audio/mpeg"             → MIME type yang memberitahu browser format file adalah MP3 --}}
    </audio>
    {{-- Penutup elemen <audio> --}}
</div>
{{-- Penutup .audio-wrap --}}

{{-- ===== MAIN: ABOUT + TIMELINE ===== --}}
{{-- Komentar Blade: menandai area konten utama dengan dua kartu berdampingan --}}
<div class="main">
{{-- Container utama Flexbox untuk dua kartu informasi;
     memiliki margin negatif (-40px) agar kartu overlap/menimpa bagian bawah hero --}}

    {{-- About Card --}}
    {{-- Komentar Blade: kartu pertama berisi tabel data biodata personal --}}
    <div class="card">
    {{-- Kartu pertama dengan kelas .card: latar putih, shadow, animasi fadeUp --}}
        <div class="card-title">About</div>
        {{-- Judul kartu "About" dengan tanda aksen garis emas di kiri (via pseudo-elemen ::before) --}}
        <table class="about-table">
        {{-- Tabel HTML untuk menampilkan data biodata dalam format baris-kolom yang rapi dan terstruktur --}}
            <tr><td>Nama</td><td>:</td><td>Pius Hari Purba</td></tr>
            {{-- Baris 1: data nama lengkap pemilik profil --}}
            <tr><td>NRP</td><td>:</td><td>241210160165</td></tr>
            {{-- Baris 2: NRP (Nomor Registrasi Pokok) atau nomor identitas mahasiswa yang unik --}}
            <tr><td>Jenis Kelamin</td><td>:</td><td>Laki-laki</td></tr>
            {{-- Baris 3: data jenis kelamin --}}
            <tr><td>Tempat / TTL</td><td>:</td><td>Medan, 09 Mei 200X</td></tr>
            {{-- Baris 4: tempat lahir dan tanggal/bulan/tahun lahir (TTL = Tempat Tanggal Lahir) --}}
            <tr><td>Agama</td><td>:</td><td>Kristen Protestan</td></tr>
            {{-- Baris 5: agama yang dianut oleh pemilik profil --}}
            <tr><td>Alamat</td><td>:</td><td>Gg Kekeyi No 47, Lamongan, Jawa Timur</td></tr>
            {{-- Baris 6: alamat tempat tinggal saat ini (jalan, kota, provinsi) --}}
        </table>
        {{-- Penutup elemen <table> biodata --}}
    </div>
    {{-- Penutup kartu About --}}

    {{-- Timeline Card --}}
    {{-- Komentar Blade: kartu kedua berisi riwayat pendidikan berbentuk timeline --}}
    <div class="card">
    {{-- Kartu kedua; muncul 0.15 detik lebih lambat dari kartu pertama karena animation-delay --}}
        <div class="card-title">Education Timeline</div>
        {{-- Judul kartu riwayat pendidikan --}}
        <div class="timeline-list">
        {{-- Container daftar timeline; memiliki garis vertikal gradien sebagai pseudo-elemen ::before --}}
            <div class="t-event">
            <h3>SD Antonius Medan</h3>
                <div class="year">2011 – 2017</div>
                <span class="badge">Sekolah Dasar</span>
                </div>
            <div class="t-event">
            <h3>SMP Putri Cahaya Medan</h3>
            <div class="year">2017 – 2020</div>
            <span class="badge">Sekolah Menengah Pertama</span>
            </div>
            <div class="t-event">
                <h3>SMA Negeri 4 Medan</h3>
                <div class="year">2020 – 2023</div>
                <span class="badge">Sekolah Menengah Atas</span>
            </div>
            </div>
        </div>
        
</div>
{{-- Penutup .main (container dua kartu informasi) --}}

{{-- ===== KONTAK ===== --}}
{{-- Komentar Blade: menandai awal seksi kontak sosial di bagian bawah halaman --}}
<section class="kontak-section">
{{-- Elemen semantik <section> untuk area kontak; terpusat dengan animasi fadeUp delay 0.3 detik --}}
    <div class="kontak-card">
    {{-- Kartu kontak berlatar gradien gelap dengan pseudo-elemen lingkaran dekoratif di sudut-sudutnya --}}
        <div class="kontak-title">Hubungi Saya</div>
        {{-- Judul seksi kontak dengan font Playfair Display berwarna putih --}}
        <div class="kontak-sub">Tersedia di platform berikut</div>
        {{-- Teks subjudul deskriptif, ditampilkan putih teredam di bawah judul --}}

        <div class="kontak-links">
        {{-- Container Flexbox untuk tombol-tombol link platform kontak --}}

            {{-- Instagram --}}
            {{-- Komentar Blade: tombol tautan ke profil Instagram --}}
            <a href="https://www.instagram.com/pius_purba257?igsh=MWFkeHptY2I2cGpwZw==" target="_blank" class="kontak-btn ig">
            {{-- Tautan ke profil Instagram:
                 href        → URL profil Instagram dengan parameter igsh (tracking share)
                 target="_blank" → membuka di tab/jendela browser baru
                 class .kontak-btn → gaya dasar tombol
                 class .ig        → menambahkan gradien warna Instagram ke kotak ikon --}}
                <div class="icon-wrap">
                {{-- Container kotak ikon; mendapat background gradien Instagram dari kelas .ig --}}
                    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    {{-- Elemen vektor SVG untuk ikon Instagram:
                         viewBox="0 0 24 24" → mendefinisikan canvas koordinat 24×24 unit
                         xmlns → namespace XML untuk SVG --}}
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                        {{-- Path SVG yang menggambar bentuk logo Instagram:
                             - Bentuk kotak berlapis (outer rectangle rounded)
                             - Lingkaran tengah (mewakili lensa kamera)
                             - Titik kecil di sudut atas kanan (flash kamera) --}}
                    </svg>
                    {{-- Penutup elemen SVG --}}
                </div>
                {{-- Penutup .icon-wrap --}}
                <div class="detail">
                {{-- Container Flex kolom untuk label nama platform dan handle username --}}
                    <span class="platform">Instagram</span>
                    {{-- Label nama platform dalam huruf kapital kecil berwarna putih teredam --}}
                    <span class="handle">@pius_purba257</span>
                    {{-- Username Instagram pemilik profil, ditampilkan lebih besar dan tebal --}}
                </div>
                {{-- Penutup .detail --}}
            </a>
            {{-- Penutup tombol tautan Instagram --}}

            {{-- WhatsApp --}}
            {{-- Komentar Blade: tombol tautan ke WhatsApp --}}
            <a href="https://wa.me/qr/URYKBAWE6FSKG1" target="_blank" class="kontak-btn wa">
            {{-- Tautan ke WhatsApp melalui QR code link:
                 wa.me/qr/... → URL resmi WhatsApp untuk tautan berbasis QR code
                 target="_blank" → membuka di tab baru
                 class .wa   → menambahkan background hijau WhatsApp ke kotak ikon --}}
                <div class="icon-wrap">
                {{-- Container kotak ikon; mendapat background hijau WhatsApp dari kelas .wa --}}
                    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    {{-- Elemen SVG untuk ikon WhatsApp; canvas koordinat 24×24 unit --}}
                        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                        {{-- Path SVG yang menggambar logo WhatsApp:
                             - Bentuk gelembung percakapan (chat bubble) dengan ekor di bawah
                             - Simbol telepon/handset di tengah gelembung --}}
                    </svg>
                    {{-- Penutup elemen SVG --}}
                </div>
                {{-- Penutup .icon-wrap --}}
                <div class="detail">
                {{-- Container Flex kolom untuk teks detail platform WhatsApp --}}
                    <span class="platform">WhatsApp</span>
                    {{-- Label nama platform "WhatsApp" dalam kapital kecil --}}
                    <span class="handle">0838-7083-2740</span>
                    {{-- Nomor telepon WhatsApp yang bisa dihubungi --}}
                </div>
                {{-- Penutup .detail --}}
            </a>
            {{-- Penutup tombol tautan WhatsApp --}}

        </div>
        {{-- Penutup .kontak-links --}}
    </div>
    {{-- Penutup .kontak-card --}}
</section>
{{-- Penutup <section class="kontak-section"> --}}

</body>
{{-- Penutup tag <body>: seluruh konten halaman telah selesai --}}
</html>
{{-- Penutup tag <html>: dokumen HTML telah selesai sepenuhnya --}}
