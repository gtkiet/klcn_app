// lib/shared/models/paging_model.dart

class PagingInfo {
  final int pageNumber;
  final int pageSize;
  final int totalItems;

  /// Server có thể không trả về — tính từ totalItems + pageSize.
  final int? totalPages;

  const PagingInfo({
    required this.pageNumber,
    required this.pageSize,
    required this.totalItems,
    this.totalPages,
  });

  factory PagingInfo.fromJson(Map<String, dynamic> json) => PagingInfo(
    pageNumber: json['pageNumber'] as int? ?? 1,
    pageSize: json['pageSize'] as int? ?? 10,
    totalItems: json['totalItems'] as int? ?? 0,
    totalPages: json['totalPages'] as int?,
  );

  int get _effectiveTotalPages =>
      totalPages ?? (pageSize > 0 ? (totalItems / pageSize).ceil() : 0);

  bool get hasNextPage => pageNumber < _effectiveTotalPages;
  bool get hasMore => pageNumber * pageSize < totalItems;
}

class PagedResult<T> {
  final List<T> items;
  final PagingInfo pagingInfo;

  const PagedResult({required this.items, required this.pagingInfo});

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedResult(
      items: rawItems.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      pagingInfo: PagingInfo.fromJson(
        json['pagingInfo'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  bool get hasNextPage => pagingInfo.hasNextPage;
  bool get hasMore => pagingInfo.hasMore;
  int get totalItems => pagingInfo.totalItems;
  int get pageNumber => pagingInfo.pageNumber;
  int get pageSize => pagingInfo.pageSize;
}
