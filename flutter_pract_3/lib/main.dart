import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final getIt = GetIt.instance;

class TokenInterceptor extends Interceptor {
  static String? token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

void setup() {
final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5016/api'));
  dio.interceptors.add(TokenInterceptor());
  dio.interceptors.add(PrettyDioLogger(requestHeader: true, responseHeader: true));
  getIt.registerSingleton<Dio>(dio);
}

void main() {
  setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AuthPage());
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _message = '';

  Future<void> _register() async {
    final dio = getIt<Dio>();
    try {
      final r = await dio.post('/auth/register', data: {
        'login': _loginCtrl.text,
        'email': '${_loginCtrl.text}@example.com',
        'password': _passCtrl.text,
      });
      TokenInterceptor.token = r.data['token'];
      setState(() => _message = 'Регистрация успешна, токен получен');
    } on DioException catch (e) {
      setState(() => _message = 'Ошибка ${e.response?.statusCode}: ${e.response?.data}');
    }
  }

  Future<void> _login() async {
    final dio = getIt<Dio>();
    try {
      final r = await dio.post('/auth/login', data: {
        'login': _loginCtrl.text,
        'password': _passCtrl.text,
      });
      TokenInterceptor.token = r.data['token'];
      setState(() => _message = 'Вход выполнен, токен получен');
    } on DioException catch (e) {
      setState(() => _message = 'Ошибка ${e.response?.statusCode}: ${e.response?.data}');
    }
  }

  Future<void> _protectedRequest() async {
    final dio = getIt<Dio>();
    try {
      final r = await dio.get('/purchases');
      final list = r.data as List;
      setState(() => _message = 'Запрос к /purchases успешен, записей: ${list.length}');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        setState(() => _message = '401: требуется авторизация');
      } else if (code == 403) {
        setState(() => _message = '403: доступ запрещён');
      } else if (code == 429) {
        setState(() => _message = '429: слишком много попыток входа');
      } else {
        setState(() => _message = 'Ошибка $code: ${e.response?.data}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('apishka client')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _loginCtrl,
              decoration: const InputDecoration(labelText: 'Login'),
            ),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text('Войти')),
            ElevatedButton(onPressed: _register, child: const Text('Зарегистрироваться')),
            ElevatedButton(onPressed: _protectedRequest, child: const Text('Запрос к /purchases')),
            const SizedBox(height: 16),
            Text(_message),
          ],
        ),
      ),
    );
  }
}