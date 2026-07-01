/// String constants: app name, error messages, labels.
class AppStrings {
  AppStrings._();

  static const String appName = 'TaskFlow';

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String logout = 'Đăng xuất';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String fullName = 'Họ và tên';
  static const String forgotPassword = 'Quên mật khẩu?';

  // ─── Common ───────────────────────────────────────────────────────────────
  static const String save = 'Lưu';
  static const String cancel = 'Hủy';
  static const String delete = 'Xóa';
  static const String edit = 'Chỉnh sửa';
  static const String confirm = 'Xác nhận';
  static const String loading = 'Đang tải...';
  static const String retry = 'Thử lại';
  static const String noData = 'Không có dữ liệu';
  static const String success = 'Thành công';

  // ─── Error Messages ───────────────────────────────────────────────────────
  static const String errorNetwork = 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
  static const String errorServer = 'Lỗi máy chủ. Vui lòng thử lại sau.';
  static const String errorTimeout = 'Yêu cầu quá thời gian. Vui lòng thử lại.';
  static const String errorUnauthorized = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
  static const String errorUnexpected = 'Đã xảy ra lỗi. Vui lòng thử lại.';

  // ─── Validation Messages ─────────────────────────────────────────────────
  static const String validationRequired = 'Trường này không được để trống.';
  static const String validationEmail = 'Email không hợp lệ.';
  static const String validationPasswordMin = 'Mật khẩu phải có ít nhất 6 ký tự.';

  // ─── Workspace & Project ─────────────────────────────────────────────────
  static const String workspace = 'Workspace';
  static const String project = 'Dự án';
  static const String createWorkspace = 'Tạo Workspace';
  static const String createProject = 'Tạo Dự án';

  // ─── Task ─────────────────────────────────────────────────────────────────
  static const String task = 'Task';
  static const String createTask = 'Tạo Task';
  static const String assignee = 'Người thực hiện';
  static const String reporter = 'Người tạo';
  static const String reviewer = 'Người review';
  static const String deadline = 'Hạn hoàn thành';
  static const String status = 'Trạng thái';
  static const String priority = 'Độ ưu tiên';
  static const String comment = 'Bình luận';
  static const String checklist = 'Checklist';
  static const String attachment = 'Đính kèm';

  // ─── Task Statuses ───────────────────────────────────────────────────────
  static const String statusTodo = 'Cần làm';
  static const String statusDoing = 'Đang làm';
  static const String statusReview = 'Đang review';
  static const String statusDone = 'Hoàn thành';

  // ─── Task Priorities ─────────────────────────────────────────────────────
  static const String priorityLow = 'Thấp';
  static const String priorityMedium = 'Trung bình';
  static const String priorityHigh = 'Cao';
  static const String priorityCritical = 'Khẩn cấp';
}
