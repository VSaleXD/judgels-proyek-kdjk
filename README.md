<section align="center">
  <img src="assets/logo.png" alt="Judgels Logo" width="280" style="margin-bottom: 1.5rem;"/>
  <div align="center">
    <h1>Aplikasi Judgels</h1>
    <p><strong>Projek Akhir Praktikum Komunikasi Data dan Jaringan Komputer</strong><br/>
    Departemen Ilmu Komputer - IPB University<br/>
    Target Deployment: <a href="http://103.160.213.105"><code>http://103.160.213.105</code></a> (<code>cp.codetoday</code>)</p>
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
## Konfigurasi

Konfigurasi pada [**Judgels**](https://www.google.com/search?q=https%3A%2F%2Fjudgels.toki.id%2Fdocs%2Fdeployment%2Finstallation%2F) dikelola secara terpusat melalui direktori *environment* Ansible (`~/judgels-env` yang ditautkan ke `env/`), berkas konfigurasi kontainer pada `/opt/judgels/`, serta *reverse proxy* Nginx.

### 1. Inventaris Server (`hosts.ini`) dan Variabel Lingkungan (`vars.yml`)

Pada arsitektur Judgels, berkas `hosts.ini` mendefinisikan pembagian alamat IP untuk **Core VM** (menjalankan `judgels-client`, `judgels-server`, MySQL, RabbitMQ, dan Nginx) serta **Grader VM** (menjalankan worker `judgels-grader`). Untuk deployment pada satu server (`103.160.213.105`), kedua peran diarahkan ke alamat IP yang sama:

```
[core]
103.160.213.105

[grader]
103.160.213.105

```

Selanjutnya, berkas `vars.yml` menyimpan versi aplikasi, kredensial basis data MySQL, kata sandi awal akun `superadmin`, serta kredensial antrean pesan RabbitMQ:

```
app_version: '3.0.0'

# Kredensial MySQL
db_root_password: '<PASSWORD_ROOT_MYSQL>'
db_username: 'judgels'
db_password: '<PASSWORD_DB_JUDGELS>'

# Kredensial awal akun superadmin
superadmin_initialPassword: '<PASSWORD_AWAL_SUPERADMIN>'

# Kredensial antrean pesan RabbitMQ (komunikasi Server <-> Grader)
rabbitmq_username: 'judgels'
rabbitmq_password: '<PASSWORD_RABBITMQ>'

```

### 2. Konfigurasi Domain dan Reverse Proxy (Nginx)

Judgels memisahkan akses antarmuka menjadi tiga endpoint yang diteruskan oleh Nginx di Core VM: domain peserta (`cp.codetoday`), endpoint API (`api.cp.codetoday`), dan panel admin/juri (`admin.cp.codetoday`). Pengaturan domain ditetapkan di `vars.yml`:

```
nginx_domain_judgels_client: cp.codetoday
nginx_domain_judgels_server_api: api.cp.codetoday
nginx_domain_judgels_server_admin: admin.cp.codetoday
nginx_certbot_email: admin@cp.codetoday

```

Saat *playbook* dijalankan, konfigurasi *virtual host* Nginx otomatis dibuat pada lokasi berikut:

* `/etc/nginx/sites-available/judgels-client`

* `/etc/nginx/sites-available/judgels-server-api`

* `/etc/nginx/sites-available/judgels-server-admin`

* `/etc/nginx/sites-available/letsencrypt`

Jika dilakukan penyesuaian manual pada berkas Nginx (seperti pengaturan `client_max_body_size` untuk batas ukuran unggahan paket soal/*test case*), uji konfigurasi lalu muat ulang layanan:

```
sudo nginx -t
sudo systemctl reload nginx

```

### 3. Konfigurasi Layanan Komponen (Client, Server, dan Grader)

Setiap komponen Judgels berjalan di dalam kontainer Docker dengan *mounted volume* pada direktori `/opt/judgels/` ([Dokumentasi Cheatsheet Judgels](https://www.google.com/search?q=https%3A%2F%2Fjudgels.toki.id%2Fdocs%2Fdeployment%2Fcheatsheet%2F)):

| Komponen | Lokasi Berkas Konfigurasi | Fungsi Pengaturan | 
| ----- | ----- | ----- | 
| **Judgels Client** | `/opt/judgels/client/var/conf/judgels-client.js` | Mengatur judul aplikasi dan alamat endpoint API (`apiUrl`) yang diakses oleh React SPA | 
| **Judgels Server** | `/opt/judgels/server/var/conf/judgels-server.yml` | Mengatur koneksi JDBC MySQL, kredensial RabbitMQ, direktori penyimpanan lokal (`/opt/judgels/server/var/data/`), serta pasangan kunci `judgels-grader` | 
| **Judgels Grader** | `/opt/judgels/grader/var/conf/judgels-grader.yml` | Mengatur koneksi pengambilan *test case* dari Server, antrean RabbitMQ, serta parameter *sandbox* **Isolate** (`/judgels/isolate/bin`) | 

Setelah mengubah berkas konfigurasi secara langsung di server, terapkan perubahan dengan me-*restart* kontainer terkait:

```
docker restart judgels-client judgels-server judgels-grader

```

### 4. Pembatasan Memori dan CPU Kontainer (Resource Limit)

Agar proses kompilasi kode peserta atau lonjakan trafik saat kontes berlangsung tidak menghabiskan seluruh memori host, batas penggunaan memori (`--memory`) dapat diterapkan pada masing-masing kontainer Docker:

```
# Membatasi memori judgels-server maksimal 2 GB dan judgels-grader maksimal 1.5 GB
docker update --memory="2g" --memory-swap="2g" judgels-server
docker update --memory="1536m" --memory-swap="1536m" judgels-grader

```

Untuk memeriksa apakah batas memori sudah diterapkan serta memantau pemakaian sumber daya kontainer:

```
docker inspect judgels-server --format='MemoryLimit: {{.HostConfig.Memory}}'
docker stats --no-stream

```

### 5. Identitas Aplikasi (App Identity) dan Penambahan Worker Grader

* **Pengaturan Identitas Web:** Nama platform, slogan pada *header*, pengumuman global (*Announcement*), dan *banner* halaman depan disimpan di dalam database sehingga dapat diubah kapan saja tanpa *redeploy*. Login sebagai `superadmin` pada antarmuka web (`http://103.160.213.105` / `cp.codetoday`), lalu buka menu **Admin → System → Settings** dan ubah bagian **App settings** serta **Home settings**.

* **Penambahan Worker Grader Baru:** Jika kapasitas penjurian perlu ditingkatkan dengan menambah VM Grader baru, tambahkan alamat IP Grader baru di bawah bagian `[grader]` pada `hosts.ini`, kemudian jalankan *playbook* terbatas pada IP baru tersebut:

```
ansible-playbook -e @env/vars.yml playbooks/provision.yml --limit=<IP_GRADER_BARU>
ansible-playbook -e @env/vars.yml playbooks/deploy.yml --limit=<IP_GRADER_BARU>

```

## Maintenance

Berbeda dengan aplikasi statis, [**Judgels**](https://www.google.com/search?q=https%3A%2F%2Fjudgels.toki.id%2Fdocs%2Fdeployment%2Fconcepts%2F) menyimpan data kontes, akun pengguna, soal, dan hasil penilaian di dalam database **MySQL** (`judgels`), sedangkan berkas pengiriman kode peserta (*submission files*), *test case*, serta foto profil disimpan pada disk lokal (`/opt/judgels/server/var/data/`). Oleh karena itu, prosedur pemeliharaan mencakup pencadangan basis data dan berkas data, pembersihan log, serta pemantauan layanan dan antrean penjurian.

### 1. Backup Database MySQL, Berkas Data, dan Konfigurasi (Mingguan)

Buat skrip `~/backup-judgels.sh` pada Core VM untuk mencadangkan database MySQL sekaligus berkas data dan konfigurasi aplikasi. Sesuaikan nilai `DB_PASS` dengan nilai `db_password` pada `vars.yml`:

```
#!/bin/bash
BACKUP_DIR="$HOME/backup-judgels"
DATE=$(date +%F)
DB_USER="judgels"
DB_PASS="<PASSWORD_DB_JUDGELS>"
DB_NAME="judgels"

mkdir -p "$BACKUP_DIR"

# 1. Backup database MySQL
mysqldump -u "$DB_USER" -p"$DB_PASS" --single-transaction --quick "$DB_NAME" \
  | gzip > "$BACKUP_DIR/judgels-db-$DATE.sql.gz"

# 2. Backup direktori data (submissions, test cases, avatars) dan konfigurasi
sudo tar -czf "$BACKUP_DIR/judgels-data-$DATE.tar.gz" \
  /opt/judgels/server/var/data \
  /opt/judgels/server/var/conf \
  /opt/judgels/client/var/conf \
  /opt/judgels/grader/var/conf

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
gunzip < ~/backup-judgels/judgels-db-<tanggal>.sql.gz | mysql -u judgels -p judgels

# Pulihkan berkas data dan konfigurasi, lalu restart kontainer
sudo tar -xzf ~/backup-judgels/judgels-data-<tanggal>.tar.gz -C /
docker restart judgels-server judgels-client judgels-grader

```

### 2. Pembersihan Log dan Image Kontainer (Harian)

Judgels Server dan Grader menulis log operasional di `/opt/judgels/server/var/log/` dan `/opt/judgels/grader/var/log/`. Gunakan `sudo crontab -e` untuk menjadwalkan pembersihan *systemd journal* (menyimpan 14 hari terakhir), penghapusan log aplikasi yang berusia lebih dari 14 hari, serta pembersihan *image* Docker tak terpakai setiap hari pukul 03.00:

```
0 3 * * * /usr/bin/journalctl --vacuum-time=14d && /usr/bin/find /opt/judgels/*/var/log/ -type f -mtime +14 -delete && /usr/bin/docker image prune -f

```

### 3. Pemantauan Layanan, Antrean Penilaian, dan Sandbox

Periksa kesehatan kontainer Docker, layanan pendukung (MySQL & Nginx), antrean RabbitMQ, serta *sandbox* Isolate secara berkala:

1. **Pemeriksaan Kontainer dan Log Aplikasi:**
   Pastikan kontainer `judgels-client`, `judgels-server`, `rabbitmq`, dan `judgels-grader` berstatus *Up*:

   ```
   docker ps
   docker logs --tail=100 -f judgels-server
   docker logs --tail=100 -f judgels-grader
   
   ```

2. **Pemeriksaan Layanan MySQL dan Nginx:**

   ```
   sudo systemctl status mysql
   sudo systemctl status nginx
   
   ```

3. **Pemantauan Antrean Penilaian (RabbitMQ) dan Database (phpMyAdmin):**

   * **RabbitMQ Management UI:** Akses `http://103.160.213.105:15672`, login dengan `rabbitmq_username` dan `rabbitmq_password` dari `vars.yml`, lalu buka tab **Queues** untuk memantau apakah terdapat *grading request* yang macet atau menumpuk.

   * **phpMyAdmin (Opsional):** Dapat diakses melalui `http://103.160.213.105:8080` untuk inspeksi tabel database `judgels` (kontainer `phpmyadmin` dapat dihentikan saat tidak digunakan demi keamanan).

4. **Pemeriksaan Kotak Isolasi (Isolate Sandbox) pada Grader:**
   Untuk memeriksa direktori kotak eksekusi aktif di dalam kontainer Grader:

   ```
   docker exec -it judgels-grader ls /var/local/lib/isolate
   
   ```

### 4. Pembaruan Sistem dan Upgrade Versi Judgels

Perbarui paket sistem operasi Ubuntu pada server secara berkala:

```
sudo apt update && sudo apt upgrade -y

```

Jika muncul pesan *System restart required*, jalankan `sudo reboot`. Seluruh layanan systemd (Docker, MySQL, Nginx) beserta kontainer Judgels akan aktif kembali secara otomatis setelah server menyala.

Apabila ingin memperbarui Judgels ke versi rilis baru dari [GitHub Releases Judgels](https://www.google.com/search?q=https%3A%2F%2Fgithub.com%2Fia-toki%2Fjudgels%2Freleases), perbarui nilai `app_version` pada `env/vars.yml` di *workstation* deployment, lalu jalankan kembali *playbook* deploy:

```
ansible-playbook -e @env/vars.yml playbooks/deploy.yml

```

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

## Referensi

1. https://github.com/ia-toki/judgels

2. https://judgels.toki.id/docs/introduction/

3. https://judgels.toki.id/docs/deployment/concepts/

4. https://judgels.toki.id/docs/deployment/installation/

5. https://judgels.toki.id/docs/deployment/cheatsheet/
