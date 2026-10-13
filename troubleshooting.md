
# Báo cáo khắc phục sự cố CI/CD

Workflow hoạt động nằm tại `.github/workflows/broken-pipeline.yml` ở gốc
dự án. Workflow chạy khi push lên nhánh `main`, dùng checkout v5 và setup-java
v5 với Temurin 21, phù hợp với Java toolchain trong `build.gradle`.

## 1. Permission Denied

**Nguyên nhân:** Gradle Wrapper không có quyền thực thi
trên GitHub Actions Runner. Bước chạy test trước đây gọi trực tiếp `./gradlew`
mà không cấp quyền.

**Khắc phục:** Thêm bước `chmod +x gradlew` ngay trước bước test. Dockerfile
cũng cấp quyền trước khi gọi wrapper.

**Kết quả kiểm tra:** `gradlew` hiện có quyền thực thi tại workspace và
`./gradlew test --no-daemon` hoàn tất thành công tại máy phát triển. Gradle báo
`test NO-SOURCE`, nên dự án hiện chưa có mã nguồn/test Java để thực thi.

## 2. Authentication Failed

**Nguyên nhân:** Workflow tham chiếu `secrets.REGISTRY_TOKN`, tên secret sai
chính tả và không có căn cứ cho thấy secret tùy chỉnh này đã được cấu hình.

**Khắc phục:** Dùng secret tích hợp `secrets.GITHUB_TOKEN` cùng
`github.actor`; workflow khai báo `permissions.packages: write` và
`permissions.contents: read`. Không cần tạo secret tùy chỉnh cho bước đăng nhập
GHCR.

**Kết quả kiểm tra:** Cấu hình YAML đã tham chiếu đúng token và quyền. Đăng nhập
GHCR thực tế chỉ được xác nhận khi GitHub Actions chạy.

## 3. Build Context Error

**Nguyên nhân:** Dockerfile thực tế ở `./Dockerfile`, nhưng workflow dùng
context `./docker` và file `./docker/Dockerfile`, hai đường dẫn không tồn tại.

**Khắc phục:** Đặt `context: .` và `file: ./Dockerfile`. Dockerfile gọi
`./gradlew clean build --no-daemon` để build Gradle project và đóng gói
artifact.

**Giới hạn hiện tại:** Dự án không có thư mục `src/` hay mã nguồn Java; lần chạy
Gradle xác nhận `compileJava` và `test` đều `NO-SOURCE`. Dockerfile có thể build
Gradle project, nhưng không thể xác nhận hoặc chạy một ứng dụng Java thực tế
cho đến khi có mã nguồn/điểm vào ứng dụng. Lệnh cuối của image hiện chỉ in
phiên bản Java, không khởi động ứng dụng.

## Xác minh và trạng thái

- Đã chạy `./gradlew test --no-daemon`: `BUILD SUCCESSFUL`, nhưng không có test.
- Cần chạy `docker build -t ci-cd-troubleshooting:local .` để xác minh Docker
  build tại máy có Docker daemon.
- Chưa có kết quả chạy GitHub Actions trong lần kiểm tra này; không thể kết luận
  workflow đã tích xanh hoặc xác nhận push image thành công.
- Trước khi có ứng dụng Java, cần bổ sung mã nguồn và cấu hình cách chạy ứng
  dụng trong container; không tạo secret giả.