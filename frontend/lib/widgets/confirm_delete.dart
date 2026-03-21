import 'package:flutter/material.dart';

/// Menampilkan dialog konfirmasi sebelum menghapus data.
/// Mengembalikan `true` jika user menekan "Hapus", `false` jika "Batal".
Future<bool> confirmDelete(BuildContext context, {String judul = 'Konfirmasi Hapus', String pesan = 'Yakin ingin menghapus data ini?'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text(judul, style: const TextStyle(fontSize: 18)),
        ],
      ),
      content: Text(pesan),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result ?? false;
}
