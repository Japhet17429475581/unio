import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:unio_app/services/direct_portal_client.dart';

const portalLoginHtml =
    '<form id="login-form" action="/login"><input type="hidden" name="_csrf" value="csrf-test"><input type="password"></form>';
const portalLoggedInHtml = '<form action="/auth/logout" method="post"></form>';
const portalListHtml = '''
<select id="category-selector"><option value="4">Обучение</option></select>
<select id="type-selector" disabled><option value="">Укажите тип заявления</option></select>
<div class="list-view"><div class="requestItem" data-key="101">
<a class="requestItem-Info" href="/request/101/edit"><h3 class="requestItem-title">Заказ справок об обучении</h3>
<div class="requestItem-Info-Descr"><h5>Обучение</h5><div class="requestItem-Info-Descr-Status">
<div class="Ach-Status pre">получение информации</div><p>Обновлено: 01.01.2026</p>
</div></div></a></div></div>''';

// Reduced, anonymized structure from the provided portal HTML: all six fields
// are outside the submit form; labels are h2 and help text is h3.
const portalFormHtml = '''
<div class="Cont">
<div class="text-item"><p>Срок подготовки справки об обучении 3 рабочих дня.</p></div>
<div class="list-item"><h2>Место требования (обязателен для заполнения)</h2>
<select name="field_30" data-transfer="1"><option value="1">Пенсионный фонд</option><option value="2">Иная организация</option></select></div>
<div class="text-item"><h2>Наименование организации (обязателен для заполнения)</h2><h3>Укажите официальное наименование организации.</h3><textarea name="field_31" data-transfer="1"></textarea></div>
<div class="list-item"><h2>Количество экземпляров (обязателен для заполнения)</h2><h3>Не более 3-х в одну организацию</h3>
<select name="field_32" data-transfer="1"><option value="1">1</option><option value="2">2</option><option value="3">3</option></select></div>
<div class="list-item"><h2>Способ получения (обязателен для заполнения)</h2><select name="field_33" data-transfer="1"><option value="1">Лично</option><option value="2">По электронной почте</option><option value="3">По почте России</option></select></div>
<div class="text-item"><h2>Адрес</h2><h3>Укажите адрес доставки</h3><textarea name="field_34" data-transfer="1"></textarea></div>
<div class="text-item"><h2>Комментарий</h2><textarea name="field_35" data-transfer="1"></textarea></div>
<form id="approve-request-form" method="post" action="/request/101/edit"><button>Отправить на обработку</button></form></div>''';

// Income form structure from the supplied HTML, without student information.
const incomeFormHtml = '''
<meta name="csrf-param" content="_csrf"><meta name="csrf-token" content="upload-csrf">
<script>window.fileinput_test = {"allowedFileExtensions":["doc","docx","pdf","jpg","jpeg"],"required":true,"uploadUrl":"/request/101/upload","uploadExtraData":{"field_id":147}};</script>
<div class="Cont"><a href="https://portal.vspu.ru/request/101/template">Скачать шаблон заявления</a>
<div class="text-item"><p>Справка о доходах</p></div>
<div class="list-item"><h2>Способ получения (обязателен для заполнения)</h2>
<select name="field_143" data-transfer="1"><option value="1">Лично</option><option value="2">По почте России</option></select></div>
<div class="string-item"><h2>Дата с (обязателен для заполнения)</h2><input type="text" name="field_144" value="" data-transfer="1"></div>
<div class="string-item"><h2>Дата по (обязателен для заполнения)</h2><input type="text" name="field_145" value="" data-transfer="1"></div>
<div class="text-item"><h2>Адрес</h2><h3>При выборе «По почте России» - укажите адрес для доставки.</h3><textarea name="field_146" data-transfer="1"></textarea></div>
<div class="uploader-item"><h2>Заявление (обязателен для загрузки)</h2><input type="file" class="file-uploader" name="attachment" data-krajee-fileinput="fileinput_test"></div>
<div class="string-item"><h2>Количество</h2><h3>Количество справок</h3><input type="text" name="field_166" value="" data-transfer="1"></div>
<form id="approve-request-form" method="post" action="/request/101/edit"><button>Отправить на обработку</button></form></div>''';

class PortalAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handle;
  PortalAdapter(this.handle);
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      handle(options);
  @override
  void close({bool force = false}) {}
}

DirectPortalClient fakePortal(
    FutureOr<ResponseBody> Function(RequestOptions) handler) {
  final dio = Dio()..httpClientAdapter = PortalAdapter(handler);
  return DirectPortalClient(transport: dio, diagnosticsEnabled: false);
}

ResponseBody page(String text,
        {int status = 200, Map<String, List<String>>? headers}) =>
    ResponseBody.fromString(text, status,
        headers: headers ??
            {
              'content-type': ['text/html; charset=utf-8']
            });
