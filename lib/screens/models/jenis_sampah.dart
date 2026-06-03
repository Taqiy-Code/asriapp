class JenisSampah {

  final int id;
  final String nama;
  final String kodeIcon;
  final double harga;

  JenisSampah({
    required this.id,
    required this.nama,
    required this.kodeIcon,
    required this.harga,
  });


  factory JenisSampah.fromJson(Map<String, dynamic> json) {
    return JenisSampah(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? json['nama_jenis'] ?? '-',
      kodeIcon: json['kode_icon'] ?? '',
      harga: double.tryParse(json['harga_per_kg']?.toString() ?? '0') ?? 0.0,
    );
  }
}
