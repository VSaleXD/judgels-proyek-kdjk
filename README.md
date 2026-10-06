<div align="center">

<img src="assets/logo.png" alt="Judgels Logo" width="280" />

# Aplikasi Judgels

**Projek Akhir Praktikum Komunikasi Data dan Jaringan Komputer**  
Departemen Ilmu Komputer - IPB University 
Target Deployment: `http://103.160.213.105` (`cp.codetoday`)

<br/>

**Disusun oleh:**

| Nama | NIM |
| :--- | :---: |
| **Aditya Cahyo Nugroho** | M0403241109 |
| **Mochamad Aleandre Moulidouane** | M0403241105 |
| **Rafael Federico Atantya** | M0403241108 |
| **Ahmad Rafif Ilmany** | M0403241090 |

</div>

---

## Sekilas Tentang

### Ringkasan Cepat (Executive Summary)

- **Definisi:** Platform *online judge* dan sistem manajemen kontes pemrograman *open-source* yang dikembangkan oleh **Ikatan Alumni TOKI (IA-TOKI)**.
- **Implementasi Nyata:** Menjadi mesin utama di balik platform **TLX TOKI**, Olimpiade Sains Nasional (OSN) Informatika, dan seleksi Pelatnas IOI Indonesia.
- **Fungsi Pokok:** Mengelola soal, menerima pengiriman kode peserta, mengeksekusi kode di dalam lingkungan terisolasi (*sandbox*), memberikan penilaian otomatis (*verdict* AC/WA/TLE), dan menyajikan papan skor (*scoreboard*) waktu nyata.
- **Arsitektur:** Berbasis layanan terdistribusi (Frontend **React**, Backend API & Admin **Java**, Penilai **Java Grader Worker**, Antrean **RabbitMQ**, dan Basis Data **MySQL**).
- **Format Kontes:** Mendukung aturan **IOI** (dengan subtask dan skor parsial) serta aturan **ICPC** (sistem penalti waktu).

---

### Latar Belakang & Peran Sistem

Berbeda dari sistem berbasis monolitik sederhana, Judgels dirancang menggunakan arsitektur terdistribusi (*distributed services*) untuk menjamin isolasi keamanan dan skalabilitas saat melayani ratusan peserta secara simultan. Platform ini memisahkan secara ketat antarmuka pengguna, logika bisnis kontes, dan eksekusi kode program kiriman peserta.

---

## Perbandingan Judgels dengan Aplikasi Sejenis

| Aspek | Judgels | DOMjudge | CMS (Contest Management System) | DMOJ |
|---|---|---|---|---|
| **Pengembang** | Ikatan Alumni TOKI | Komunitas DOMjudge | Komunitas CMS | Komunitas DMOJ |
| **Konsep Utama** | Sistem pengelolaan soal dan kontes pemrograman | Sistem penjurian kontes pemrograman, terutama bergaya ICPC | Sistem terdistribusi untuk menyelenggarakan kontes pemrograman, terutama bergaya IOI | *Online judge* sekaligus platform kontes dan arsip soal |
| **Model Deployment** | *Self-hosted*; tersedia image Docker dan skrip Ansible | *Self-hosted*; server kontes dan satu atau lebih *judgehost* | *Self-hosted* di Linux; tersedia opsi Docker | *Self-hosted*; situs dan server penjurian dipasang sebagai komponen terpisah |
| **Jenis Soal** | *Batch*, interaktif, *output-only*, dan *functional/grader*; mendukung subtask | Penjurian otomatis dengan bahasa dan validator yang dapat dikonfigurasi | Beragam jenis tugas, termasuk *batch*, *output-only*, dan interaktif | Soal berbasis input/output, interaktif, dan *signature-graded*; mendukung validator khusus |
| **Format Kontes** | IOI dan ICPC; mendukung kontes virtual | ICPC dan penilaian parsial bergaya IOI | Beragam format tugas dan penilaian; dirancang untuk kebutuhan IOI | ICPC, IOI, AtCoder, dan ECOO; mendukung partisipasi virtual |
| **Fitur Pengelolaan** | Versi soal, pengumuman, klarifikasi, papan skor, serta peran pengelola dan pengawas | Antarmuka juri dan tim, klarifikasi, papan skor, serta penjurian ulang | Antarmuka administrasi, impor kontes dan soal, serta layanan papan skor | Arsip soal, editorial, papan skor, rating opsional, dan pengelolaan pengguna |
| **Skalabilitas** | Bergantung pada kapasitas dan konfigurasi deployment | Kapasitas penjurian dapat ditambah dengan *judgehost* | Arsitektur terdistribusi dengan layanan dan pekerja penjurian | Mendukung banyak server penjurian |
| **Kebutuhan Pengelolaan** | Administrator menyiapkan dan memelihara deployment serta server | Administrator menyiapkan server kontes, basis data, dan *judgehost* | Administrator menyiapkan layanan CMS, PostgreSQL, dan lingkungan penjurian | Administrator menyiapkan situs, basis data, dan server penjurian |
| **Biaya Perangkat Lunak** | Open Source, GPL-2.0; tetap memerlukan biaya infrastruktur | Open Source; tetap memerlukan biaya infrastruktur | Open Source; tetap memerlukan biaya infrastruktur | Open Source, AGPL-3.0; tetap memerlukan biaya infrastruktur |

Judgels cocok bila dibutuhkan pengelolaan soal yang kaya fitur sekaligus kontes IOI dan ICPC. DOMjudge kuat untuk operasional kontes ICPC, CMS untuk kebutuhan olimpiade bergaya IOI, sedangkan DMOJ menggabungkan kontes dengan situs latihan dan arsip soal. Perbandingan ini didasarkan pada dokumentasi resmi Judgels, DOMjudge, CMS, dan DMOJ.
