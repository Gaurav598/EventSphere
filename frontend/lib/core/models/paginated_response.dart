class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class PaginatedResponse<T> {
  final bool success;
  final String message;
  final List<T> data;
  final Pagination? pagination;

  PaginatedResponse({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final dataList = json['data'] as List?;
    final items = dataList != null
        ? dataList.map((item) => fromJsonT(item as Map<String, dynamic>)).toList()
        : <T>[];

    return PaginatedResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: items,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}
