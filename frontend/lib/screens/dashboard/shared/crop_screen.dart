import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mypskd/config/theme.dart';
import 'package:mypskd/config/api_config.dart';
import 'package:mypskd/services/auth_service.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const CropScreen({Key? key, required this.imageBytes}) : super(key: key);

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _controller = CropController(
    aspectRatio: 1.0, // Force 1:1 square
    defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );
  bool _isUploading = false;

  Future<void> _cropAndUpload() async {
    setState(() => _isUploading = true);
    try {
      final ui.Image image = await _controller.croppedBitmap();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();

      final token = await AuthService.getToken() ?? '';
      final userData = await AuthService.getUserData();
      final myId = userData?['id'] ?? '';

      // Upload to Cloudinary via backend
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/pengumpulan/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: 'profile_$myId.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final jsonRes = json.decode(responseData);
        final fileUrl = jsonRes['file_url'];

        // Update Firestore users collection
        await FirebaseFirestore.instance.collection('users').doc(myId).update({
          'photoUrl': fileUrl,
        });

        // Update local session
        if (userData != null) {
          userData['photoUrl'] = fileUrl;
          await AuthService.saveUserData(userData);
        }

        if (mounted) {
          Navigator.pop(context, fileUrl);
        }
      } else {
        debugPrint("Upload failed: ${response.statusCode} - $responseData");
        throw Exception("Gagal upload gambar");
      }
    } catch (e) {
      debugPrint("Crop error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}", style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Sesuaikan Foto", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textLight)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3)),
                )
              : IconButton(
                  icon: const Icon(LucideIcons.check, color: AppTheme.primary),
                  onPressed: _cropAndUpload,
                ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sesuaikan ukuran agar pas di kotak persegi.",
                style: GoogleFonts.inter(color: AppTheme.textMutedLt),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.textLight, width: 4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CropImage(
                      image: Image.memory(widget.imageBytes),
                      controller: _controller,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isUploading)
                Text(
                  "Mengunggah profil barumu...",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
