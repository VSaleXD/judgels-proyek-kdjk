<section align="center">
  <img src="assets/logo.png" alt="Judgels Logo" width="280" style="margin-bottom: 1.5rem;"/>
  <div align="center">
    <h1>Aplikasi Judgels</h1>
    <p><strong>Projek Akhir Praktikum Komunikasi Data dan Jaringan Komputer</strong><br/>
    Departemen Ilmu Komputer - IPB University<br/>
    Target Deployment: <a href="https://cp-judgels.web.id"><code>http://103.160.213.105</code>
    </a></p>
    <p>Disusun oleh:</p>
    <table align="center" style="margin-top: 1rem; text-align: left; border-collapse: collapse;">
      <tr>
        <th style="padding: 6px 16px; border: 1px solid #444;">Nama</th>
        <th style="padding: 6px 16px; border: 1px solid #444;">NIM</th>
      </tr>
      <tr>
        <td style="padding: 6px 16px; border: 1px solid #444;"><strong>Mochamad Aleandre Moulidouane</strong></td>
        <td style="padding: 6px 16px; border: 1px solid #444;"><code>M0403241105</code></td>
      </tr>
      <tr>
        <td style="padding: 6px 16px; border: 1px solid #444;"><strong>Rafael Federico Atantya</strong></td>
        <td style="padding: 6px 16px; border: 1px solid #444;"><code>M0403241108</code></td>
      </tr>
      <tr>
        <td style="padding: 6px 16px; border: 1px solid #444;"><strong>Aditya Cahyo Nugroho</strong></td>
        <td style="padding: 6px 16px; border: 1px solid #444;"><code>M0403241109</code></td>
      </tr>
      <tr>
        <td style="padding: 6px 16px; border: 1px solid #444;"><strong>Ahmad Rafif Ilmany</strong></td>
        <td style="padding: 6px 16px; border: 1px solid #444;"><code>M0403241090</code></td>
      </tr>
    </table>
  </div>
  <br/>
  <nav aria-label="Navigation">
    <a href="#sekilas-tentang">Sekilas Tentang</a> |
    <a href="#perbandingan-judgels-dengan-aplikasi-sejenis">Perbandingan</a>
  </nav>
</section>

---

## Sekilas Tentang

**Judgels** adalah platform *open-source* untuk pengelolaan kontes pemrograman kompetitif (*competitive programming*) dan pelatihan daring (*training camp*). Dikembangkan secara aktif oleh **Ikatan Alumni Tim Olimpiade Komputer Indonesia (IA-TOKI)**, platform ini menjadi fondasi utama sistem penjurian nasional di Indonesia, termasuk **TLX TOKI**, Olimpiade Sains Nasional (OSN) bidang Informatika, hingga seleksi Pelatnas Tim Olimpiade Komputer Indonesia menuju IOI.

Berbeda dari sistem berbasis monolitik konvensional, Judgels dirancang menggunakan arsitektur layanan terdistribusi (*distributed services*) untuk memastikan isolasi keamanan dan skalabilitas beban saat melayani ratusan pengiriman program secara serentak.

### Ringkasan Cepat (Executive Summary)

- **Definisi:** Platform *online judge* dan sistem manajemen kontes pemrograman *open-source* berbasis layanan terdistribusi.
- **Implementasi Nyata:** Mesin utama di balik platform **TLX TOKI** dan Olimpiade Sains Nasional (OSN) Informatika.
- **Fungsi Pokok:** Pengelolaan bank soal, penerimaan solusi peserta, eksekusi kode terisolasi (*sandbox*), penilaian otomatis (*verdict* AC/WA/TLE), dan papan skor waktu nyata (*live scoreboard*).
- **Arsitektur:** Terdiri dari antarmuka web peserta (**Judgels Client - React SPA**), layanan backend & panel juri (**Judgels Server - Java**), pekerja penilai (**Judgels Grader - Java Worker**), antrean tugas (**RabbitMQ**), serta basis data relasional (**MySQL**).
- **Format Penilaian:** Mendukung penuh format **IOI** (dengan pembobotan subtask dan skor parsial) serta format **ICPC** (penalti waktu dan skor penuh).

---
## Instalasi

Judgels dipasang pada server yang sama dengan DOMjudge (`103.160.213.105`) menggunakan **Docker Compose**, bukan playbook Ansible resmi. Alasannya, playbook `provision.yml` ditulis untuk Ubuntu dan mengubah konfigurasi sistem yang sudah dipakai DOMjudge: menghapus site Nginx `default`, mengganti kata sandi `root` MySQL, mengaktifkan UFW dengan hanya membuka beberapa port, serta mengedit GRUB untuk mematikan cgroup v2 lalu me-*reboot* server. Percobaan menjalankan Ansible langsung dari server juga gagal pada task pertama (`Permission denied (publickey,password)`) sehingga tidak ada perubahan yang terjadi pada server.

Dengan Docker Compose, MySQL, RabbitMQ, Judgels Server, dan Judgels Client berjalan sebagai kontainer terisolasi. Semua port kontainer hanya di-*bind* ke `127.0.0.1`, dan satu-satunya perubahan pada layanan host adalah penambahan satu berkas *virtual host* Nginx baru.

> **Cakupan:** bagian ini mencakup *core stack* (Client, Server, MySQL, RabbitMQ). **Grader belum dipasang** pada tahap ini. Image grader memakai Isolate v1.10.1 yang membutuhkan cgroup v1, sehingga sebaiknya dijalankan di VM terpisah. Tanpa grader, antarmuka web dan panel admin dapat dipakai, tetapi pengiriman solusi peserta belum dinilai.

### Prasyarat

| Komponen | Keterangan |
| --- | --- |
| Server | Debian GNU/Linux 13 (kernel 6.12.107), IP `103.160.213.105`, akses `root` lewat SSH (PuTTY) |
| Layanan yang sudah ada | DOMjudge (kontainer `domjudge-domserver`, MariaDB, dan *judgehost*) dengan Nginx sebagai *web server* (site `default` dan `domjudge`) |
| Docker | Docker Engine 26.1.5 dan Docker Compose 2.26.1 |
| Nginx dan Certbot | Nginx sebagai *reverse proxy*, Certbot untuk sertifikat Let's Encrypt |
| Domain | `cp-judgels.web.id` (DNS dikelola di DewaBiz) |
| Port | `5000` (client) dan `9101` (server) harus kosong; port 80 dan 443 terbuka untuk Nginx |

Kebutuhan sumber daya yang disarankan dokumentasi Judgels untuk *core VM* adalah minimal 4 GB RAM dan 2 CPU.

**Pembagian domain:**

| Domain | Fungsi |
| --- | --- |
| `cp-judgels.web.id` | Antarmuka peserta (Judgels Client) |
| `api.cp-judgels.web.id` | Endpoint API (Judgels Server) |
| `admin.cp-judgels.web.id` | Antarmuka admin (Judgels Server) |

**Komponen yang dijalankan:**

| Kontainer | Image | Akses |
| --- | --- | --- |
| `judgels-mysql` | `mysql:8.0` | Hanya jaringan internal Docker |
| `rabbitmq` | `rabbitmq:3.13.7-management-alpine` | Hanya jaringan internal Docker |
| `judgels-server-migrate` | `ghcr.io/ia-toki/judgels/server:3.0.0` | Menjalankan `db migrate` sekali, lalu berhenti |
| `judgels-server` | `ghcr.io/ia-toki/judgels/server:3.0.0` | `127.0.0.1:9101` |
| `judgels-client` | `ghcr.io/ia-toki/judgels/client:3.0.0` | `127.0.0.1:5000` |

### Langkah Instalasi

**1. Periksa kondisi server.** Login lewat SSH, lalu pastikan Docker tersedia, port tidak bentrok, dan ketahui *web server* yang dipakai:

```sh
docker --version; docker compose version
ss -ltnp | grep -E ':(5000|9101)\b'
ls /etc/nginx/sites-enabled
```

Perintah kedua harus menghasilkan keluaran kosong. Pada server ini, site Nginx yang sudah ada adalah `default` dan `domjudge`.

**2. Atur DNS.** Pada panel DNS Management DewaBiz, buat tiga *A record* berikut:

| Host Name | Record Type | Address |
| --- | --- | --- |
| `@` | A | `103.160.213.105` |
| `admin` | A | `103.160.213.105` |
| `api` | A | `103.160.213.105` |

Setelah menyimpan, pastikan DNS aktif dari server:

```sh
getent hosts cp-judgels.web.id api.cp-judgels.web.id admin.cp-judgels.web.id
```

Ketiga baris harus menampilkan `103.160.213.105`. Sertifikat Let's Encrypt gagal diterbitkan jika DNS belum aktif.

**3. Unggah berkas instalasi.** Folder instalasi harus berisi `docker-compose.yml` dan [setup.sh](./setup.sh). Unggah folder tersebut ke server, misalnya dengan `pscp` atau WinSCP:

```sh
pscp -r "D:\path\ke\judgels-docker" root@103.160.213.105:/root/
```

**4. Jalankan skrip persiapan.** Skrip menerima domain utama dan versi Judgels sebagai argumen:

```sh
cd /root/judgels-docker
chmod +x setup.sh
./setup.sh cp-judgels.web.id 3.0.0
```

Skrip [setup.sh](./setup.sh) harus dijalankan sebagai `root` (atau dengan `sudo`) dan tidak menyentuh Nginx, firewall, GRUB, maupun database yang sudah ada di host. Yang dilakukannya:

1. Membuat direktori kerja di `/opt/judgels` dan menyalin `docker-compose.yml` ke sana.
2. Membuat kata sandi acak untuk MySQL, RabbitMQ, dan akun `superadmin`, lalu menyimpannya di `/opt/judgels/.env` (mode 600). Jika `.env` sudah ada, kata sandi tidak diganti; domain dan versi diperbarui.
3. Menulis konfigurasi Server (`/opt/judgels/server/var/conf/judgels-server.yml`), Client (`/opt/judgels/client/var/conf/judgels-client.js` dengan `apiUrl: 'https://api.cp-judgels.web.id/v2'`), dan contoh *virtual host* Nginx (`/opt/judgels/nginx-judgels.conf`).
4. Menampilkan kata sandi awal `superadmin` di akhir keluaran. **Catat kata sandi ini.**

Secara default skrip hanya menyiapkan berkas. Untuk langsung menjalankan Compose, gunakan `START=yes ./setup.sh cp-judgels.web.id 3.0.0`. `BASE_DIR` dapat diubah jika direktori kerja bukan `/opt/judgels`.

**5. Jalankan kontainer.**

```sh
cd /opt/judgels
docker compose up -d
docker compose ps
```

Unduhan image dari `ghcr.io` memerlukan beberapa menit pada percobaan pertama. Urutan *start* diatur oleh Compose: MySQL dan RabbitMQ harus *healthy*, kemudian `judgels-server-migrate` menjalankan migrasi database sampai selesai, baru `judgels-server` dijalankan. Status yang diharapkan adalah `judgels-mysql` dan `rabbitmq` *healthy*, `judgels-server-migrate` `Exited (0)`, serta `judgels-server` dan `judgels-client` `Up`.

```sh
docker logs judgels-server-migrate
docker logs --tail=50 judgels-server
```

**6. Uji layanan secara lokal.**

```sh
curl -I http://127.0.0.1:5000
curl -s http://127.0.0.1:9101/api/v2/user-web/config
```

Perintah kedua mengembalikan JSON berisi `appName`, `appSlogan`, dan `homeBanner`.

**7. Pasang *virtual host* Nginx.** Salin konfigurasi yang dibuat skrip sebagai site baru. Site `default` dan `domjudge` tidak diubah:

```sh
cp /opt/judgels/nginx-judgels.conf /etc/nginx/sites-available/judgels
ln -s /etc/nginx/sites-available/judgels /etc/nginx/sites-enabled/judgels
nginx -t && systemctl reload nginx
```

Berkas tersebut berisi tiga blok `server`: domain peserta meneruskan ke `127.0.0.1:5000`, sedangkan domain API dan admin meneruskan ke `127.0.0.1:9101`. Aturan `rewrite` pada domain API menambahkan awalan `/api` ke *path*.

**8. Pasang sertifikat HTTPS.**

```sh
apt install -y certbot python3-certbot-nginx
certbot --nginx -d cp-judgels.web.id -d api.cp-judgels.web.id -d admin.cp-judgels.web.id
```

Certbot menambahkan konfigurasi HTTPS dan pengalihan HTTP ke HTTPS pada blok *server* yang sesuai.

**9. Verifikasi.**

| Pengujian | Hasil yang diharapkan |
| --- | --- |
| `curl -si https://api.cp-judgels.web.id/v2/user-web/config` | `HTTP/1.1 200 OK` dengan JSON konfigurasi aplikasi |
| Buka `https://admin.cp-judgels.web.id` | Halaman admin dapat dibuka; login sebagai `superadmin` dengan kata sandi dari langkah 4 |
| Buka `https://cp-judgels.web.id` | Halaman utama Judgels tampil |
| `docker ps` | Kontainer DOMjudge tetap berjalan seperti sebelum instalasi |

**10. Amankan kredensial.** Berkas `/opt/judgels/.env` dan `/opt/judgels/server/var/conf/judgels-server.yml` berisi kata sandi. Jangan masukkan keduanya ke repositori Git. Ganti kata sandi `superadmin` setelah login pertama, lalu simpan salinan `.env` di tempat yang aman.

### Instalasi Grader (belum dikerjakan)

Grader akan dipasang pada VM Ubuntu 24.04 terpisah agar pengaturan cgroup v1 yang dibutuhkan Isolate tidak mengubah server DOMjudge. Grader terhubung ke RabbitMQ pada Core untuk menerima tugas penilaian dan mengambil *test case* dari Judgels Server. Langkah ini akan ditambahkan setelah dikerjakan.

### Pemecahan Masalah

| Gejala | Penyebab dan solusi |
| --- | --- |
| Ansible: `Permission denied (publickey,password)` | Ansible berjalan tanpa interaksi sehingga tidak dapat memakai kata sandi SSH, sedangkan kunci SSH belum terdaftar. Jalur ini tidak dipakai karena alasan yang dijelaskan di awal bagian ini. |
| Halaman peserta menampilkan "Something went wrong"; Console browser: `blocked by CORS policy`, `/user-web/config` | Pastikan `apiUrl` di `judgels-client.js` berakhiran `/v2`: `https://api.cp-judgels.web.id/v2`. Image client v3.0.0 memanggil `${apiUrl}/user-web/config`. Setelah mengubahnya, muat ulang dengan Ctrl+Shift+R. |
| `setup.sh` berhenti dengan pesan port 5000 atau 9101 terpakai | Port dipakai proses lain. Cari prosesnya dengan `ss -ltnp | grep :<port>`. |
| Certbot gagal memverifikasi domain | DNS belum aktif atau belum mengarah ke `103.160.213.105`. Periksa dengan `getent hosts <domain>` dan tunggu propagasi. |
| `judgels-server` tidak mau *start* | Migrasi belum selesai atau gagal. Periksa `docker logs judgels-server-migrate` dan status kontainer `judgels-mysql`. |

## Maintenance

Berbeda dengan aplikasi statis, [**Judgels**](https://www.google.com/search?q=https%3A%2F%2Fjudgels.toki.id%2Fdocs%2Fdeployment%2Fconcepts%2F) menyimpan data kontes, akun pengguna, soal, dan hasil penilaian di dalam database **MySQL** (`judgels`), sedangkan berkas pengiriman kode peserta (*submission files*), *test case*, serta foto profil disimpan pada disk lokal (`/opt/judgels/server/var/data/`). Oleh karena itu, prosedur pemeliharaan mencakup pencadangan basis data dan berkas data, pembersihan log, serta pemantauan layanan dan antrean penjurian.

### 1. Backup Database MySQL, Berkas Data, dan Konfigurasi (Mingguan)

Buat skrip `~/backup-judgels.sh` pada Core VM untuk mencadangkan database MySQL sekaligus berkas data dan konfigurasi aplikasi. Baca `DB_PASSWORD` dari `/opt/judgels/.env` dan jangan menyalin nilainya ke repositori:

```
#!/bin/bash
BACKUP_DIR="$HOME/backup-judgels"
DATE=$(date +%F)
DB_USER="judgels"
DB_PASS="$(sed -n 's/^DB_PASSWORD=//p' /opt/judgels/.env)"
DB_NAME="judgels"

mkdir -p "$BACKUP_DIR"

# 1. Backup database MySQL
docker exec judgels-mysql mysqldump -u "$DB_USER" -p"$DB_PASS" --single-transaction --quick "$DB_NAME" \
  | gzip > "$BACKUP_DIR/judgels-db-$DATE.sql.gz"

# 2. Backup direktori data (submissions, test cases, avatars) dan konfigurasi
sudo tar -czf "$BACKUP_DIR/judgels-data-$DATE.tar.gz" \
  /opt/judgels/server/var/data \
  /opt/judgels/server/var/conf \
  /opt/judgels/client/var/conf \
  /opt/judgels/.env \
  /opt/judgels/nginx-judgels.conf

# 3. Hapus arsip backup yang lebih lama dari 28 hari
find "$BACKUP_DIR" -name 'judgels-*.gz' -mtime +28 -delete

```

Beri izin eksekusi pada skrip:

```
chmod +x ~/backup-judgels.sh

```

Jadwalkan pencadangan otomatis setiap hari Minggu pukul 02.00 dini hari menggunakan `crontab -e`:

```
0 2 * * 0 /home/<username>/backup-judgels.sh

```

Untuk memulihkan (*restore*) data dari cadangan saat terjadi kendala:

```
# Pulihkan database MySQL
DB_PASS="$(sed -n 's/^DB_PASSWORD=//p' /opt/judgels/.env)"
gunzip < ~/backup-judgels/judgels-db-<tanggal>.sql.gz | docker exec -i judgels-mysql mysql -u judgels -p"$DB_PASS" judgels

# Pulihkan berkas data dan konfigurasi, lalu restart kontainer
sudo tar -xzf ~/backup-judgels/judgels-data-<tanggal>.tar.gz -C /
docker compose -f /opt/judgels/docker-compose.yml restart judgels-server judgels-client

```

### 2. Pembersihan Log dan Image Kontainer (Harian)

Judgels Server menulis log operasional di `/opt/judgels/server/var/log/`. Gunakan `sudo crontab -e` untuk menjadwalkan pembersihan *systemd journal* (menyimpan 14 hari terakhir), penghapusan log aplikasi yang berusia lebih dari 14 hari, serta pembersihan *image* Docker tak terpakai setiap hari pukul 03.00:

```
0 3 * * * /usr/bin/journalctl --vacuum-time=14d && /usr/bin/find /opt/judgels/*/var/log/ -type f -mtime +14 -delete && /usr/bin/docker image prune -f

```

### 3. Pemantauan Layanan dan Antrean Penilaian

Periksa kesehatan kontainer Docker, layanan pendukung (MySQL & Nginx), dan antrean RabbitMQ secara berkala:

1. **Pemeriksaan Kontainer dan Log Aplikasi:**
   Pastikan kontainer `judgels-client`, `judgels-server`, `judgels-mysql`, dan `rabbitmq` berstatus *Up*:

   ```
   docker ps
   docker logs --tail=100 -f judgels-server
   
   ```

2. **Pemeriksaan Layanan Nginx:**

   ```
   sudo systemctl status nginx
   
   ```

3. **Pemantauan Antrean Penilaian (RabbitMQ):**

   * **RabbitMQ Management UI:** Jika port management dipublikasikan oleh `docker-compose.yml`, akses UI sesuai port yang didefinisikan Compose. Kredensial RabbitMQ ada di `/opt/judgels/.env`.

### 4. Pembaruan Sistem dan Upgrade Versi Judgels

Perbarui paket sistem operasi Debian pada server secara berkala:

```
sudo apt update && sudo apt upgrade -y

```

Jika muncul pesan *System restart required*, jalankan `sudo reboot`. Layanan Docker dan Nginx beserta kontainer Judgels akan aktif kembali secara otomatis setelah server menyala.

Apabila ingin memperbarui Judgels ke versi rilis baru dari [GitHub Releases Judgels](https://www.google.com/search?q=https%3A%2F%2Fgithub.com%2Fia-toki%2Fjudgels%2Freleases), ubah `JUDGELS_VERSION` pada `/opt/judgels/.env` (atau jalankan kembali `setup.sh` dengan versi baru), lalu tarik image dan jalankan ulang Compose:

```
cd /opt/judgels
docker compose pull
docker compose up -d
```

## Perbandingan Judgels dengan Aplikasi Sejenis

| Aspek | Judgels | DOMjudge | CMS (Contest Management System) | DMOJ |
|---|---|---|---|---|
| **Pengembang** | Ikatan Alumni TOKI | Komunitas DOMjudge | Komunitas CMS | Komunitas DMOJ |
| **Konsep Utama** | Sistem pengelolaan soal dan kontes pemrograman | Sistem penjurian kontes pemrograman, terutama bergaya ICPC | Sistem terdistribusi untuk menyelenggarakan kontes pemrograman, terutama bergaya IOI | *Online judge* sekaligus platform kontes dan arsip soal |
| **Model Deployment** | *Self-hosted*; Docker Compose dan skrip `setup.sh` | *Self-hosted*; server kontes dan satu atau lebih *judgehost* | *Self-hosted* di Linux; tersedia opsi Docker | *Self-hosted*; situs dan server penjurian dipasang sebagai komponen terpisah |
| **Jenis Soal** | *Batch*, interaktif, *output-only*, dan *functional/grader*; mendukung subtask | Penjurian otomatis dengan bahasa dan validator yang dapat dikonfigurasi | Beragam jenis tugas, termasuk *batch*, *output-only*, dan interaktif | Soal berbasis input/output, interaktif, dan *signature-graded*; mendukung validator khusus |
| **Format Kontes** | IOI dan ICPC; mendukung kontes virtual | ICPC dan penilaian parsial bergaya IOI | Beragam format tugas dan penilaian; dirancang untuk kebutuhan IOI | ICPC, IOI, AtCoder, dan ECOO; mendukung partisipasi virtual |
| **Fitur Pengelolaan** | Versi soal, pengumuman, klarifikasi, papan skor, serta peran pengelola dan pengawas | Antarmuka juri dan tim, klarifikasi, papan skor, serta penjurian ulang | Antarmuka administrasi, impor kontes dan soal, serta layanan papan skor | Arsip soal, editorial, papan skor, rating opsional, dan pengelolaan pengguna |
| **Skalabilitas** | Bergantung pada kapasitas dan konfigurasi deployment | Kapasitas penjurian dapat ditambah dengan *judgehost* | Arsitektur terdistribusi dengan layanan dan pekerja penjurian | Mendukung banyak server penjurian |
| **Kebutuhan Pengelolaan** | Administrator menyiapkan dan memelihara deployment serta server | Administrator menyiapkan server kontes, basis data, dan *judgehost* | Administrator menyiapkan layanan CMS, PostgreSQL, dan lingkungan penjurian | Administrator menyiapkan situs, basis data, dan server penjurian |
| **Biaya Perangkat Lunak** | Open Source, GPL-2.0; tetap memerlukan biaya infrastruktur | Open Source; tetap memerlukan biaya infrastruktur | Open Source; tetap memerlukan biaya infrastruktur | Open Source, AGPL-3.0; tetap memerlukan biaya infrastruktur |

Judgels cocok bila dibutuhkan pengelolaan soal yang kaya fitur sekaligus kontes IOI dan ICPC. DOMjudge kuat untuk operasional kontes ICPC, CMS untuk kebutuhan olimpiade bergaya IOI, sedangkan DMOJ menggabungkan kontes dengan situs latihan dan arsip soal. Perbandingan ini didasarkan pada dokumentasi resmi Judgels, DOMjudge, CMS, dan DMOJ.

## Referensi

1. https://github.com/ia-toki/judgels

2. https://judgels.toki.id/docs/introduction/

3. https://judgels.toki.id/docs/deployment/concepts/

4. https://judgels.toki.id/docs/deployment/installation/

5. https://judgels.toki.id/docs/deployment/cheatsheet/
