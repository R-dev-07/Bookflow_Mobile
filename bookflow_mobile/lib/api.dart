import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// Typed client for the BookFlow REST API (`/api/v1`).
/// Authentication: [tokenProvider] returns the current Clerk session JWT, sent as a Bearer token.
class Api {
  Api(this.baseUrl);
  final String baseUrl;
  Future<String?> Function()? tokenProvider;
  final http.Client _client = http.Client();

  String _networkMessage(Object e) {
    final hint = baseUrl.contains('10.0.2.2')
        ? ' 10.0.2.2 only works on the Android emulator. On a real phone run "adb reverse tcp:4000 tcp:4000" '
              'and use API_BASE_URL=http://localhost:4000 (or your PC\'s Wi-Fi IP).'
        : ' Check that the backend is running and reachable from this device.';
    return 'Cannot reach the server at $baseUrl.$hint';
  }

  Future<dynamic> _send(String method, String path, {Map<String, String>? query, Object? body}) async {
    var uri = Uri.parse('$baseUrl/api/v1$path');
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);

    final token = await tokenProvider?.call();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);

    http.Response res;
    final attempts = method == 'GET' ? 2 : 1; // safe to retry reads once (e.g. a sleeping server)
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final req = switch (method) {
          'POST' => _client.post(uri, headers: headers, body: encoded),
          'PATCH' => _client.patch(uri, headers: headers, body: encoded),
          _ => _client.get(uri, headers: headers),
        };
        res = await req.timeout(const Duration(seconds: 15));
        break;
      } on Exception catch (e) {
        if (attempt >= attempts) throw ApiException(0, _networkMessage(e));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = null;
      }
    }
    if (res.statusCode >= 400) {
      final msg = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Request failed (${res.statusCode})';
      throw ApiException(res.statusCode, msg);
    }
    return data;
  }

  Future<Map<String, dynamic>> _map(String m, String p, {Map<String, String>? query, Object? body}) async =>
      (await _send(m, p, query: query, body: body)) as Map<String, dynamic>;

  List<Map<String, dynamic>> _items(Map<String, dynamic> j) =>
      ((j['items'] as List?) ?? const []).cast<Map<String, dynamic>>();

  // ---- account ----
  Future<AppUser> me() async => AppUser.fromJson(await _map('GET', '/me'));
  Future<void> becomeProvider({required String businessName, String? description, String? phone}) => _send(
    'POST',
    '/become-provider',
    body: {'businessName': businessName, 'description': description, 'phoneNumber': phone},
  );
  Future<Map<String, dynamic>> providerPublicProfile(String providerId) =>
      _map('GET', '/providers/$providerId');
  Future<void> updateMe({String? firstName, String? lastName, String? imageUrl, String? businessName, String? description}) =>
      _send('PATCH', '/me', body: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (businessName != null) 'businessName': businessName,
        if (description != null) 'description': description,
      });
  Future<void> deleteAccount() => _send('DELETE', '/me');

  // ---- browse ----
  Future<ListingsPage> searchListings({String? q, String? type, int page = 1}) async {
    final j = await _map(
      'GET',
      '/listings',
      query: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (type != null) 'type': type,
        'page': '$page',
      },
    );
    return ListingsPage(_items(j).map(ListingSummary.fromJson).toList(), j['hasMore'] == true);
  }

  Future<ListingDetail> listing(String id) async =>
      ListingDetail.fromJson(await _map('GET', '/listings/$id'));

  // ---- bookings ----
  Future<List<BookingModel>> bookings() async =>
      _items(await _map('GET', '/bookings')).map(BookingModel.fromJson).toList();
  Future<BookingModel> booking(String id) async => BookingModel.fromJson(await _map('GET', '/bookings/$id'));
  Future<BookingModel> cancelBooking(String id) async =>
      BookingModel.fromJson(await _map('PATCH', '/bookings/$id', body: {'action': 'cancel'}));

  Future<BookingModel> createBooking({
    required String listingId,
    required String pricingTierId,
    required List<String> addOnIds,
    required String eventType,
    required DateTime eventDate,
    required int guestCount,
    String? notes,
  }) async => BookingModel.fromJson(
    await _map(
      'POST',
      '/bookings',
      body: {
        'eventType': eventType,
        // Noon UTC keeps the calendar day stable in every time zone.
        'eventDate': DateTime.utc(eventDate.year, eventDate.month, eventDate.day, 12).toIso8601String(),
        'guestCount': guestCount,
        'notes': notes,
        'items': [
          {'listingId': listingId, 'pricingTierId': pricingTierId, 'addOnIds': addOnIds},
        ],
      },
    ),
  );

  // ---- payments (mock) ----
  Future<PaymentsData> payments() async => PaymentsData.fromJson(await _map('GET', '/payments'));
  Future<void> payMock(String bookingItemId) =>
      _send('POST', '/payments', body: {'bookingItemId': bookingItemId});

  // ---- reviews ----
  Future<ReviewsData> reviews() async => ReviewsData.fromJson(await _map('GET', '/reviews'));
  Future<void> postReview({required String listingId, required int rating, String? comment}) =>
      _send('POST', '/reviews', body: {'listingId': listingId, 'rating': rating, 'comment': comment});

  // ---- messages ----
  Future<List<Conversation>> conversations() async =>
      _items(await _map('GET', '/messages')).map(Conversation.fromJson).toList();
  Future<ChatThread> thread(String itemId) async =>
      ChatThread.fromJson(await _map('GET', '/messages/$itemId'));
  Future<void> sendMessage(String itemId, String content) =>
      _send('POST', '/messages/$itemId', body: {'content': content});

  // ---- notifications ----
  Future<NotificationsData> notifications() async =>
      NotificationsData.fromJson(await _map('GET', '/notifications'));
  Future<void> markAllNotificationsRead() => _send('PATCH', '/notifications', body: {'all': true});

  // ---- provider ----
  Future<Map<String, dynamic>> providerSummary() => _map('GET', '/provider/summary');
  Future<List<ListingSummary>> providerListings() async =>
      _items(await _map('GET', '/provider/listings')).map(ListingSummary.fromJson).toList();
  Future<void> createListing(Map<String, dynamic> body) => _send('POST', '/provider/listings', body: body);
  Future<void> updateListing(String id, Map<String, dynamic> body) =>
      _send('PUT', '/provider/listings/$id', body: body);
  Future<void> listingAction(String id, String action) => _send('PATCH', '/provider/listings/$id', body: {'action': action});
  Future<List<ProviderRequest>> providerRequests({String? status}) async =>
      _items(await _map('GET', '/provider/bookings', query: {if (status != null) 'status': status}))
          .map(ProviderRequest.fromJson)
          .toList();
  Future<void> requestAction(String itemId, String action, {String? reason, double? quotedPrice}) => _send(
    'PATCH',
    '/provider/bookings/$itemId',
    body: {
      'action': action,
      if (reason != null) 'reason': reason,
      if (quotedPrice != null) 'quotedPrice': quotedPrice,
    },
  );
  Future<List<ReviewItem>> providerReviews() async =>
      _items(await _map('GET', '/provider/reviews')).map(ReviewItem.fromJson).toList();

  // ---- admin ----
  Future<Map<String, dynamic>> adminSummary() => _map('GET', '/admin/summary');
  Future<List<ListingSummary>> adminListings({String status = 'PENDING_REVIEW'}) async =>
      _items(await _map('GET', '/admin/listings', query: {'status': status}))
          .map(ListingSummary.fromJson)
          .toList();
  Future<void> adminListingAction(String id, String action, {String? reason}) =>
      _send('PATCH', '/admin/listings/$id', body: {'action': action, if (reason != null) 'reason': reason});
  Future<List<AdminUser>> adminUsers({String? q}) async =>
      _items(await _map('GET', '/admin/users', query: {if (q != null && q.trim().isNotEmpty) 'q': q.trim()}))
          .map(AdminUser.fromJson)
          .toList();
  Future<void> setUserRole(String id, String role) =>
      _send('PATCH', '/admin/users/$id', body: {'role': role});
}
