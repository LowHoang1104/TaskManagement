import 'package:task_management/feature/domain/entities/entities.dart';

class MockData {
  MockData._();

  // ─── Users ────────────────────────────────────────────────────────────────
  static final currentUser = UserEntity(
    id: 'user_1',
    fullName: 'Hoàng Long',
    email: 'long@taskflow.com',
    passwordHash: 'hashed',
    avatarUrl: 'https://ui-avatars.com/api/?name=Hoang+Long&background=6366f1&color=fff&size=150',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  static final userHuy = UserEntity(
    id: 'user_2',
    fullName: 'Minh Huy',
    email: 'huy@taskflow.com',
    passwordHash: 'hashed',
    avatarUrl: 'https://ui-avatars.com/api/?name=Minh+Huy&background=10b981&color=fff&size=150',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now(),
  );

  static final userLinh = UserEntity(
    id: 'user_3',
    fullName: 'Khánh Linh',
    email: 'linh@taskflow.com',
    passwordHash: 'hashed',
    avatarUrl: 'https://ui-avatars.com/api/?name=Khanh+Linh&background=f43f5e&color=fff&size=150',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now(),
  );

  static final userTuan = UserEntity(
    id: 'user_4',
    fullName: 'Anh Tuấn',
    email: 'tuan@taskflow.com',
    passwordHash: 'hashed',
    avatarUrl: 'https://ui-avatars.com/api/?name=Anh+Tuan&background=f59e0b&color=fff&size=150',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now(),
  );

  // ─── Workspaces ───────────────────────────────────────────────────────────
  static final workspaces = [
    WorkspaceEntity(
      id: 'ws_1',
      name: 'Alpha Team (Design)',
      description: 'Chuyên thiết kế UI/UX và Branding',
      ownerId: currentUser.id,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now(),
    ),
    WorkspaceEntity(
      id: 'ws_2',
      name: 'Omega Dev',
      description: 'Development team cho tất cả dự án Mobile & Web',
      ownerId: currentUser.id,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
  ];

  // ─── Projects ─────────────────────────────────────────────────────────────
  static final projects = [
    ProjectEntity(
      id: 'proj_1',
      workspaceId: 'ws_2',
      name: 'TaskFlow Mobile App',
      description: 'Phát triển ứng dụng quản lý công việc siêu xịn trên nền tảng Flutter.',
      ownerId: currentUser.id,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
    ProjectEntity(
      id: 'proj_2',
      workspaceId: 'ws_2',
      name: 'Admin CMS',
      description: 'Bảng điều khiển cho quản trị viên.',
      ownerId: currentUser.id,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
  ];

  // ─── Tags ─────────────────────────────────────────────────────────────────
  static final tags = [
    const TagEntity(id: 'tag_1', projectId: 'proj_1', name: 'UI/UX', color: '#E879F9'),
    const TagEntity(id: 'tag_2', projectId: 'proj_1', name: 'Backend', color: '#38BDF8'),
    const TagEntity(id: 'tag_3', projectId: 'proj_1', name: 'Bug', color: '#FB7185'),
    const TagEntity(id: 'tag_4', projectId: 'proj_1', name: 'Feature', color: '#34D399'),
    const TagEntity(id: 'tag_5', projectId: 'proj_1', name: 'Urgent', color: '#EF4444'),
  ];

  // ─── Tasks ────────────────────────────────────────────────────────────────
  static final tasks = [
    TaskEntity(
      id: 'task_1',
      projectId: 'proj_1',
      title: 'Đập đi xây lại giao diện Kanban Board',
      description: 'Khách hàng chê giao diện cũ xấu quá, yêu cầu làm lại đẹp như Linear hoặc Notion. Cần bổ sung các hiệu ứng glassmorphism, đổ bóng sâu, micro-animations và avatar xịn xò.',
      status: TaskStatus.doing,
      priority: TaskPriority.critical,
      assigneeId: currentUser.id,
      reporterId: userHuy.id,
      deadline: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
    TaskEntity(
      id: 'task_2',
      projectId: 'proj_1',
      title: 'Thiết kế hệ thống Design Tokens',
      description: 'Lên chuẩn màu sắc, font chữ, spacing cho toàn bộ team sử dụng.',
      status: TaskStatus.done,
      priority: TaskPriority.high,
      assigneeId: userLinh.id,
      reporterId: currentUser.id,
      deadline: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TaskEntity(
      id: 'task_3',
      projectId: 'proj_1',
      title: 'Cài đặt Firebase Cloud Messaging',
      description: 'Tích hợp push notification cho app iOS và Android.',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      assigneeId: userTuan.id,
      reporterId: userHuy.id,
      deadline: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TaskEntity(
      id: 'task_4',
      projectId: 'proj_1',
      title: 'Fix lỗi crash mạng trên máy khách',
      description: 'Exception ném ra quá nhiều khi mạng chậm, cần thêm retry logic.',
      status: TaskStatus.review,
      priority: TaskPriority.high,
      assigneeId: userHuy.id,
      reporterId: currentUser.id,
      reviewerId: currentUser.id,
      deadline: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    TaskEntity(
      id: 'task_5',
      projectId: 'proj_1',
      title: 'Viết Unit Test cho thư mục Domain',
      description: 'Đảm bảo code coverage đạt 80% trở lên cho các UseCase.',
      status: TaskStatus.todo,
      priority: TaskPriority.low,
      assigneeId: currentUser.id,
      reporterId: userLinh.id,
      deadline: DateTime.now().add(const Duration(days: 14)),
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now(),
    ),
  ];

  // Helper for mock UI: Getting user by ID
  static UserEntity getUserById(String? id) {
    if (id == null) return currentUser;
    final allUsers = [currentUser, userHuy, userLinh, userTuan];
    return allUsers.firstWhere((u) => u.id == id, orElse: () => currentUser);
  }

  // Helper for mock UI: Getting tags by ID
  static List<TagEntity> getTags(List<String> tagIds) {
    return tags.where((t) => tagIds.contains(t.id)).toList();
  }

  // Define some mock relationships (Since we don't have DB)
  static final taskTagsMap = {
    'task_1': ['tag_1', 'tag_5'],
    'task_2': ['tag_1'],
    'task_3': ['tag_2', 'tag_4'],
    'task_4': ['tag_3', 'tag_5'],
    'task_5': ['tag_2'],
  };

  static final taskCommentsMap = {
    'task_1': 5,
    'task_2': 12,
    'task_3': 0,
    'task_4': 3,
    'task_5': 1,
  };

  static final taskAttachmentsMap = {
    'task_1': 2,
    'task_2': 0,
    'task_3': 1,
    'task_4': 4,
    'task_5': 0,
  };
}
