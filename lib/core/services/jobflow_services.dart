import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'auth_service.dart';

class JobflowApiServices {
  final Dio _dio;

  JobflowApiServices({
    required String accessToken,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: '${ApiConstants.baseUrl}/',
            headers: {
              'Authorization': 'Bearer $accessToken',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
              'Accept': 'application/json, text/plain, */*',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            final refreshResult = await AuthService.refreshToken();
            if (refreshResult.success && refreshResult.token != null) {
              final newToken = refreshResult.token!;
              final requestOptions = e.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newToken';

              try {
                final cloneDio = Dio(BaseOptions(
                  baseUrl: requestOptions.baseUrl,
                  headers: requestOptions.headers,
                ));
                final response = await cloneDio.request(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: Options(
                    method: requestOptions.method,
                    contentType: requestOptions.contentType,
                  ),
                );
                return handler.resolve(response);
              } catch (retryError) {
                return handler.next(e);
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<String> uploadFile(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      ApiConstants.uploadFile,
      data: formData,
    );

    return response.data['file_id'];
  }

  Future<String> createJob({
    required String toolSlug,
    required Map<String, dynamic> requestBody,
  }) async {
    final response = await _dio.post(
      ApiConstants.createJob(toolSlug),
      data: requestBody,
    );

    return response.data['job_id'];
  }

Future<Map<String, dynamic>> getJobStatus(
  String jobId,
) async {
  final response = await _dio.get(
    ApiConstants.jobStatus(jobId),
  );

  return response.data;
}

Future<Map<String, dynamic>> waitForJob(
  String jobId,
) async {
  while (true) {
    final result = await getJobStatus(jobId);

    final status = result['status'];

    if (status == 'completed') {
      return result;
    }

    if (status == 'failed') {
      throw Exception('Plainscan job failed');
    }

    await Future.delayed(
      const Duration(seconds: 2),
    );
  }
}
Future<File> downloadFile({
  required String fileId,
  required String savePath,
}) async {
  await _dio.download(
    ApiConstants.downloadFile(fileId),
    savePath,
  );

  return File(savePath);
}
}