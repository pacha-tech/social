import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Cloudinary config
const String cloudName = 'dkoc01x1b';
const String uploadPreset = 'flutter_unsigned';

Future<String?> uploadFileToCloudinary(
    File file,
    String folderPath, {
      required String resourceType,
    }) async {
  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
  );

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..fields['folder'] = folderPath
    ..files.add(await http.MultipartFile.fromPath('file', file.path));

  final response = await request.send();
  final resStr = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(resStr);
    print('✅ Cloudinary response body: $jsonResponse');
    return jsonResponse['secure_url'] as String;
  } else {
    print('❌ Cloudinary response status: ${response.statusCode}');
    print('❌ Cloudinary response body: $resStr');
    return null;
  }
}


Future<String?> uploadProfilePicture(File imageFile, String userId) {
  return uploadFileToCloudinary(
    imageFile,
    'profile_pictures/$userId',
    resourceType: 'image',
  );
}

Future<String?> uploadStoryImageToCloudinary(File imageFile, String userId) {
  return uploadFileToCloudinary(
    imageFile,
    'stories/$userId/images',
    resourceType: 'image',
  );
}

Future<String?> uploadStoryVideoToCloudinary(File videoFile, String userId) {
  return uploadFileToCloudinary(
    videoFile,
    'stories/$userId/videos',
    resourceType: 'video',
  );
}
