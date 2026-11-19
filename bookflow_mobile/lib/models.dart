// Plain data classes mirroring the JSON returned by /api/v1.

double _d(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;
double? _dn(dynamic v) => v == null ? null : double.tryParse(v.toString());
int _i(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;
String _s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;
String? _sn(dynamic v) => v?.toString();
DateTime _local(dynamic v) => DateTime.tryParse(_s(v))?.toLocal() ?? DateTime.now();

/// Event dates are calendar days: keep UTC fields so the day never shifts.
DateTime _day(dynamic v) => DateTime.tryParse(_s(v))?.toUtc() ?? DateTime.now().toUtc();
List<Map<String, dynamic>> _list(dynamic v) => ((v as List?) ?? const []).cast<Map<String, dynamic>>();
List<String> _strings(dynamic v) => ((v as List?) ?? const []).map((e) => e.toString()).toList();

class ProviderProfile {
  final String businessName;
  final String? description;
  final bool isVerified;
  ProviderProfile.fromJson(Map<String, dynamic> j)
    : businessName = _s(j['businessName']),
      description = _sn(j['description']),
      isVerified = j['isVerified'] == true;
}

class AppUser {
  final String id, email, role;
  final String? firstName, lastName, imageUrl;
  final ProviderProfile? providerProfile;
  AppUser.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      email = _s(j['email']),
      role = _s(j['role'], 'USER'),
      firstName = _sn(j['firstName']),
      lastName = _sn(j['lastName']),
      imageUrl = _sn(j['imageUrl']),
      providerProfile = j['providerProfile'] == null ? null : ProviderProfile.fromJson(j['providerProfile']);

  String get displayName {
    final n = [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');
    return n.isEmpty ? email.split('@').first : n;
  }

  bool get isAdmin => role == 'ADMIN';
}

class ListingSummary {
  final String id, type, title, status, providerName, providerId;
  final String? city, state, image, category, description, rejectionReason;
  final double? minPrice, avgRating;
  final int reviewCount;
  final int? capacity;
  final bool verified;

  ListingSummary.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      providerId = _s(j['providerId']),
      type = _s(j['type']),
      title = _s(j['title']),
      status = _s(j['status']),
      providerName = _s(j['providerName']),
      city = _sn(j['city']),
      state = _sn(j['state']),
      image = _sn(j['image']),
      category = _sn(j['category']),
      description = _sn(j['description']),
      rejectionReason = _sn(j['rejectionReason']),
      minPrice = _dn(j['minPrice']),
      avgRating = _dn(j['avgRating']),
      reviewCount = _i(j['reviewCount']),
      capacity = j['capacity'] == null ? null : _i(j['capacity']),
      verified = j['verified'] == true;

  bool get isVenue => type == 'VENUE';
  String get place => [city, state].where((e) => e != null && e.isNotEmpty).join(', ');
}

class PricingTier {
  final String id, name;
  final String? description;
  final double price;
  final int? duration;
  PricingTier.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      name = _s(j['name']),
      description = _sn(j['description']),
      price = _d(j['price']),
      duration = j['duration'] == null ? null : _i(j['duration']);
}

class AddOn {
  final String id, name;
  final String? description;
  final double price;
  final bool isRequired;
  AddOn.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      name = _s(j['name']),
      description = _sn(j['description']),
      price = _d(j['price']),
      isRequired = j['isRequired'] == true;
}

class ReviewItem {
  final String id, listingId, listingTitle, reviewerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  ReviewItem.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      listingId = _s(j['listingId']),
      listingTitle = _s(j['listingTitle']),
      reviewerName = _s(j['reviewerName']),
      rating = _i(j['rating']),
      comment = _sn(j['comment']),
      createdAt = _local(j['createdAt']);
}

class DateRange {
  final DateTime start, end;
  DateRange(this.start, this.end);
}

class ListingDetail {
  final ListingSummary summary;
  final String? location, providerDescription;
  final List<String> photos, amenities, serviceArea;
  final int? travelRadius, minimumLeadTime;
  final List<PricingTier> tiers;
  final List<AddOn> addOns;
  final List<ReviewItem> reviews;
  final List<DateRange> blocked;

  ListingDetail.fromJson(Map<String, dynamic> j)
    : summary = ListingSummary.fromJson(j),
      location = _sn(j['location']),
      providerDescription = _sn(j['providerDescription']),
      photos = _strings(j['photos']),
      amenities = _strings(j['amenities']),
      serviceArea = _strings(j['serviceArea']),
      travelRadius = j['travelRadius'] == null ? null : _i(j['travelRadius']),
      minimumLeadTime = j['minimumLeadTime'] == null ? null : _i(j['minimumLeadTime']),
      tiers = _list(j['tiers']).map(PricingTier.fromJson).toList(),
      addOns = _list(j['addOns']).map(AddOn.fromJson).toList(),
      reviews = _list(j['reviews']).map(ReviewItem.fromJson).toList(),
      blocked = _list(j['blockedRanges'])
          .map((r) => DateRange(_day(r['startDate']), _day(r['endDate'])))
          .toList();

  /// True when [d] (a calendar day) falls inside a blocked range.
  bool isBlocked(DateTime d) {
    final day = DateTime.utc(d.year, d.month, d.day);
    return blocked.any((r) {
      final s = DateTime.utc(r.start.year, r.start.month, r.start.day);
      final e = DateTime.utc(r.end.year, r.end.month, r.end.day);
      return !day.isBefore(s) && !day.isAfter(e);
    });
  }
}

class BookingItemModel {
  final String id, status, listingId, listingTitle, providerName;
  final String? image, tierName, rejectionReason;
  final double? quotedPrice;
  BookingItemModel.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      status = _s(j['status']),
      listingId = _s(j['listingId']),
      listingTitle = _s(j['listingTitle']),
      providerName = _s(j['providerName']),
      image = _sn(j['image']),
      tierName = _sn(j['tierName']),
      rejectionReason = _sn(j['rejectionReason']),
      quotedPrice = _dn(j['quotedPrice']);
}

class BookingModel {
  final String id, eventType, status;
  final DateTime eventDate, createdAt;
  final int guestCount;
  final String? notes;
  final double total;
  final List<BookingItemModel> items;
  BookingModel.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      eventType = _s(j['eventType']),
      status = _s(j['status']),
      eventDate = _day(j['eventDate']),
      createdAt = _local(j['createdAt']),
      guestCount = _i(j['guestCount']),
      notes = _sn(j['notes']),
      total = _d(j['total']),
      items = _list(j['items']).map(BookingItemModel.fromJson).toList();

  String get headline => items.isEmpty ? eventType : items.first.listingTitle;
  String? get image => items.isEmpty ? null : items.first.image;
  bool get canCancel => status == 'PENDING' || status == 'APPROVED';
}

class ProviderRequest {
  final String itemId, bookingId, status, listingTitle, customerName, eventType;
  final DateTime eventDate;
  final int guestCount;
  final String? notes, tierName, rejectionReason;
  final double? quotedPrice;
  ProviderRequest.fromJson(Map<String, dynamic> j)
    : itemId = _s(j['itemId']),
      bookingId = _s(j['bookingId']),
      status = _s(j['status']),
      listingTitle = _s(j['listingTitle']),
      customerName = _s(j['customerName']),
      eventType = _s(j['eventType']),
      eventDate = _day(j['eventDate']),
      guestCount = _i(j['guestCount']),
      notes = _sn(j['notes']),
      tierName = _sn(j['tierName']),
      rejectionReason = _sn(j['rejectionReason']),
      quotedPrice = _dn(j['quotedPrice']);
}

class PaymentItem {
  final String bookingItemId, bookingId, title;
  final double amount;
  final DateTime eventDate;
  final bool paid;
  PaymentItem.fromJson(Map<String, dynamic> j)
    : bookingItemId = _s(j['bookingItemId']),
      bookingId = _s(j['bookingId']),
      title = _s(j['title']),
      amount = _d(j['amount']),
      eventDate = _day(j['eventDate']),
      paid = j['paid'] == true;
}

class PaymentsData {
  final List<PaymentItem> items;
  final double totalPaid, totalDue;
  PaymentsData.fromJson(Map<String, dynamic> j)
    : items = _list(j['items']).map(PaymentItem.fromJson).toList(),
      totalPaid = _d(j['totalPaid']),
      totalDue = _d(j['totalDue']);
}

class PendingReview {
  final String listingId, listingTitle;
  PendingReview.fromJson(Map<String, dynamic> j)
    : listingId = _s(j['listingId']),
      listingTitle = _s(j['listingTitle']);
}

class ReviewsData {
  final List<ReviewItem> given;
  final List<PendingReview> pending;
  ReviewsData.fromJson(Map<String, dynamic> j)
    : given = _list(j['given']).map(ReviewItem.fromJson).toList(),
      pending = _list(j['pending']).map(PendingReview.fromJson).toList();
}

class Conversation {
  final String bookingItemId, title, otherName;
  final String? lastMessage;
  final DateTime lastAt;
  final int unread;
  Conversation.fromJson(Map<String, dynamic> j)
    : bookingItemId = _s(j['bookingItemId']),
      title = _s(j['title']),
      otherName = _s(j['otherName']),
      lastMessage = _sn(j['lastMessage']),
      lastAt = _local(j['lastAt']),
      unread = _i(j['unread']);
}

class ChatMessage {
  final String id, content;
  final DateTime createdAt;
  final bool mine;
  ChatMessage.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      content = _s(j['content']),
      createdAt = _local(j['createdAt']),
      mine = j['mine'] == true;
}

class ChatThread {
  final String title, otherName;
  final List<ChatMessage> messages;
  ChatThread.fromJson(Map<String, dynamic> j)
    : title = _s(j['title']),
      otherName = _s(j['otherName']),
      messages = _list(j['messages']).map(ChatMessage.fromJson).toList();
}

class NotificationItem {
  final String id, type, title, message;
  final bool isRead;
  final DateTime createdAt;
  NotificationItem.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      type = _s(j['type']),
      title = _s(j['title']),
      message = _s(j['message']),
      isRead = j['isRead'] == true,
      createdAt = _local(j['createdAt']);
}

class NotificationsData {
  final List<NotificationItem> items;
  final int unread;
  NotificationsData.fromJson(Map<String, dynamic> j)
    : items = _list(j['items']).map(NotificationItem.fromJson).toList(),
      unread = _i(j['unread']);
}

class AdminUser {
  final String id, name, email, role;
  final DateTime createdAt;
  AdminUser.fromJson(Map<String, dynamic> j)
    : id = _s(j['id']),
      name = _s(j['name']),
      email = _s(j['email']),
      role = _s(j['role']),
      createdAt = _local(j['createdAt']);
}

class ListingsPage {
  final List<ListingSummary> items;
  final bool hasMore;
  ListingsPage(this.items, this.hasMore);
}
