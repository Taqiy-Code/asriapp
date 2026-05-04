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
      id: json['id'],
      nama: json['nama'],
      kodeIcon: json['kode_icon'],
      harga: double.parse(
        json['harga_per_kg'].toString(),
      ),
    );
  }
}