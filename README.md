# Hướng dẫn cài đặt và chạy dự án (Sổ Liên Lạc Điện Tử)

Dự án này bao gồm 3 phần chính:
1. **be-fschool**: Hệ thống máy chủ (Backend) viết bằng Java Spring Boot.
2. **prm**: Ứng dụng điện thoại (Mobile App) viết bằng Flutter dành cho học sinh/giáo viên.
3. **web-admin**: Giao diện website (Web Portal) viết bằng React/Vite dành cho admin.

---

## Bước 1: Thiết lập Cơ Sở Dữ Liệu (Database)

Hệ thống sử dụng cơ sở dữ liệu **MySQL**. Tin vui là bạn **không cần** phải chạy file SQL nào cả, hệ thống Backend sẽ tự động tạo bảng và thêm dữ liệu mẫu.

1. Tải và cài đặt phần mềm MySQL (ví dụ: qua XAMPP hoặc MySQL Workbench).
2. Mở MySQL lên và chạy một câu lệnh SQL duy nhất để tạo database trống:
   ```sql
   CREATE DATABASE befschool;
   ```
3. Mở file cấu hình database của Backend: `be-fschool/src/main/resources/application.properties`.
4. Tìm và sửa lại dòng username và password cho khớp với MySQL trên máy tính của bạn:
   ```properties
   spring.datasource.username=root
   spring.datasource.password=mat_khau_cua_ban
   ```

---

## Bước 2: Chạy Backend (`be-fschool`)

Backend là trái tim của hệ thống, **bắt buộc phải chạy Backend đầu tiên** thì App và Web mới có thể lấy dữ liệu để hoạt động.

1. Mở Terminal (dòng lệnh) trong Android Studio hoặc VS Code.
2. Di chuyển vào thư mục backend:
   ```bash
   cd be-fschool
   ```
3. Chạy lệnh sau để khởi động Backend:
   ```bash
   .\mvnw spring-boot:run
   ```
4. Đợi khoảng 1-2 phút, khi dòng cuối cùng hiển thị `Started BeFschoolApplication...` tức là Backend đã chạy thành công ở địa chỉ `http://localhost:8080`.
   *(Lưu ý: Ngay trong lần chạy đầu tiên, Backend sẽ tự động đổ danh sách Học sinh, Giáo viên, và Lịch học vào database `befschool`.)*

---

## Bước 3: Chạy Ứng Dụng Điện Thoại (`prm`)

1. Mở thư mục `prm` bằng Android Studio.
2. Đảm bảo rằng bạn đang để địa chỉ IP là `10.0.2.2` trong code (mặc định đã được sửa sẵn cho máy ảo).
3. Bật máy ảo Android (Emulator) từ Device Manager (Khuyến nghị dùng cấu hình màn hình tiêu chuẩn như Pixel 6, Pixel 7 trở lên).
4. Ấn nút **Run (▶) màu xanh** ở thanh công cụ phía trên cùng.
5. Chờ ứng dụng biên dịch và hiển thị trên màn hình điện thoại ảo.

---

## Bước 4: Chạy Website admin (`web-teacher` - Tùy chọn)

Nếu bạn muốn thao tác trên nền tảng Web thay vì điện thoại:

1. Mở một Terminal (dòng lệnh) mới (để không làm tắt Backend đang chạy).
2. Di chuyển vào thư mục web:
   ```bash
   cd web-teacher
   ```
3. Cài đặt các thư viện cần thiết (chỉ cần chạy lần đầu tiên):
   ```bash
   npm install
   ```
4. Chạy website:
   ```bash
   npm run dev
   ```
5. Mở trình duyệt Chrome và truy cập vào đường link hiển thị trên màn hình (thường là `http://localhost:5173`).

---

* Mật khẩu: `123456`

## 🔑 Thông tin đăng nhập mặc định (Dữ liệu mẫu)

Sau khi hệ thống khởi động thành công, bạn có thể đăng nhập thử ngay bằng các tài khoản đã được tạo tự động:

**Tài khoản Học sinh:**
* Số điện thoại: `0123456789`
* Mật khẩu: `123456`

**Tài khoản Giáo viên:**
* Số điện thoại: `0200000001`
* Mật khẩu: `123456`

**Tài khoản Admin:**
* Số điện thoại: `0999999999`
* Mật khẩu: `123456`


### Danh sách API
# 1.Auth API
Các phương thức liên quan tới bảo mật, phân quyền với JWT.

| Method | Endpoint | Chức năng | Phân quyền |
|---|---|---|---|
| POST | `/api/auth/login` | Đăng nhập, lấy access token | Public |

**Request Body - POST /api/auth/login**
```json
{
  "phoneNumber": "0123456789",
  "password": "Password123"
}
```
**Response JSON - 200 OK**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOi...",
    "user": {
      "id": 1,
      "fullName": "Nguyễn Văn A",
      "role": "Teacher"
    }
  }
}
```

# 2.Teacher API
Quản lý thông tin, lịch trình, học sinh và bài tập của giáo viên.

| Method | Endpoint | Chức năng | Phân quyền |
|---|---|---|---|
| GET | `/api/teachers` | Lấy danh sách giáo viên | Admin |
| GET | `/api/teachers/{teacherId}` | Xem chi tiết giáo viên | Admin, Teacher |
| GET | `/api/teachers/{teacherId}/classes` | Danh sách lớp giáo viên phụ trách | Teacher |
| GET | `/api/teachers/{teacherId}/students?className=10A1` | Danh sách học sinh theo lớp | Teacher |
| GET | `/api/teachers/{teacherId}/schedules` | Xem lịch dạy của giáo viên | Teacher |
| GET | `/api/teachers/{teacherId}/assignments` | Danh sách bài tập giáo viên đã giao | Teacher |
| POST | `/api/teachers/{teacherId}/assignments` | Giao bài tập mới | Teacher |
| GET | `/api/teachers/{teacherId}/grades?className=10A1&semester=1&subject=Toán` | Xem điểm của lớp | Teacher |
| PUT | `/api/teachers/{teacherId}/grades` | Cập nhật điểm cho học sinh | Teacher |

**Request Body - POST /api/teachers/{teacherId}/assignments**
```json
{
  "className": "10A1",
  "subject": "Toán",
  "title": "Bài tập Đại số chương 1",
  "description": "Làm bài tập 1 đến 5 trang 12 SGK",
  "dueDate": "2026-08-15T23:59:59Z"
}
```

**Request Body - PUT /api/teachers/{teacherId}/grades**
```json
{
  "className": "10A1",
  "subject": "Toán",
  "semester": 1,
  "grades": [
    {
      "studentId": 101,
      "scoreType": "15Phut",
      "score": 8.5
    },
    {
      "studentId": 102,
      "scoreType": "15Phut",
      "score": 9.0
    }
  ]
}
```

# 3.Student & Grade API
Quản lý thông tin học sinh và kết quả học tập.

| Method | Endpoint | Chức năng | Phân quyền |
|---|---|---|---|
| GET | `/api/students/{id}` | Lấy chi tiết thông tin học sinh | All |
| GET | `/api/grades/student/{studentId}/semester/{semester}` | Lấy bảng điểm của học sinh theo kỳ | Student, Parent, Teacher |

**Response JSON - GET /api/grades/student/101/semester/1**
```json
{
  "success": true,
  "data": [
    {
      "subject": "Toán",
      "scores": {
        "mieng": [8, 9],
        "15Phut": [7.5, 8.5],
        "1Tiet": [8.0],
        "cuoiKy": 8.5,
        "trungBinh": 8.2
      }
    }
  ]
}
```

# 4.Schedule API
Quản lý thời khóa biểu.

| Method | Endpoint | Chức năng | Phân quyền |
|---|---|---|---|
| GET | `/api/schedules/class/{className}` | Thời khóa biểu toàn bộ trong tuần của lớp | Student, Parent, Teacher |
| GET | `/api/schedules/class/{className}/day/{dayOfWeek}` | Thời khóa biểu theo thứ trong tuần | Student, Parent, Teacher |

# 5.Notification API
Hệ thống thông báo đẩy (nhắc nhở, học phí, kỷ luật).

| Method | Endpoint | Chức năng | Phân quyền |
|---|---|---|---|
| GET | `/api/notifications` | Lấy danh sách thông báo của người dùng | All |
| GET | `/api/notifications/category/{category}` | Lọc thông báo theo danh mục (VD: HocPhi, SuKien) | All |

# 6. Assignment API
Quản lý bài tập dành cho học sinh.

| Method | Endpoint | Chức năng | Phân quyền |
|---|---|---|---|
| GET | `/api/assignments/class/{className}` | Lấy danh sách bài tập của lớp | Student, Parent, Teacher |
