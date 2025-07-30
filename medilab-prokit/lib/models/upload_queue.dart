class UploadQueueItem {
  final String id;
  final String filepath;
  final String status;
  final String createdAt;

  UploadQueueItem({
    required this.id,
    required this.filepath,
    required this.status,
    required this.createdAt,
  });

  factory UploadQueueItem.fromMap(Map<String, dynamic> map) =>
      UploadQueueItem(
        id: map['id'],
        filepath: map['filepath'],
        status: map['status'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'filepath': filepath,
    'status': status,
    'created_at': createdAt,
  };
}
