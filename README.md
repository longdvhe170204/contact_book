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

**Tài khoản Giáo viên:**
* Số điện thoại: `0200000001`
* Mật khẩu: `123456`
# Contact Book
