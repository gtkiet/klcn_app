# Sport Plus — Flutter App

Ứng dụng đặt sân bóng đá trực tuyến, xây dựng bằng Flutter + Laravel + Supabase.

---

## Cấu trúc thư mục

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart
├── widgets/
│   └── shared_widgets.dart
├── models/
│   ├── user.dart                 # Users + Profiles
│   ├── field.dart                # Fields + FieldSlots + TimeSlots
│   ├── booking.dart              # Bookings + Details + Payments + Deposits
│   ├── review.dart               # Reviews
│   └── notification.dart        # Notifications
├── services/
│   ├── api_client.dart           # Base HTTP client
│   ├── user_session.dart         # Session local (token, user)
│   ├── auth_service.dart         # Đăng ký, đăng nhập, OTP, reset password
│   ├── field_service.dart        # Danh sách sân, lịch slot
│   ├── booking_service.dart      # Đặt sân, hủy, đổi lịch, voucher
│   ├── payment_service.dart      # Thanh toán, đặt cọc, VNPay/MoMo
│   └── user_service.dart         # Hồ sơ, thông báo, đánh giá
└── screens/
    ├── splash/splash_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── forgot_password_screen.dart
    │   ├── otp_verification_screen.dart
    │   └── reset_password_screen.dart
    ├── home/home_screen.dart
    ├── field/
    │   ├── field_list_screen.dart
    │   └── field_detail_screen.dart
    ├── booking/
    │   ├── booking_confirmation_screen.dart
    │   ├── booking_success_screen.dart
    │   ├── booking_failure_screen.dart
    │   ├── booking_history_screen.dart
    │   └── booking_detail_screen.dart
    └── profile/
        ├── profile_screen.dart
        ├── edit_profile_screen.dart
        └── change_password_screen.dart
```

---

## Luồng đặt sân (khớp Stored Procedures)

```
1. Chọn sân + ngày + giờ  → FieldService.getSlots()
2. Giữ slot 10 phút        → BookingService.holdSlots()      [sp_HoldSlots]
3. Chọn dịch vụ + voucher  → BookingService.applyPromotion() [sp_ApplyPromotion]
4. Xác nhận booking        → BookingService.confirmBooking()  [sp_ConfirmBooking]
   ├── Thanh toán online   → PaymentService.createOnlinePayment()
   └── Thanh toán sau      → Tạo Deposit → Chờ đặt cọc
5. Nộp cọc                 → PaymentService.recordDeposit()   [sp_RecordDeposit]
6. Auto hoàn thành         → sp_ReleaseExpiredSlots()         [SQL Agent - 1 phút/lần]
```

---

## Models → Database mapping

| Model | Bảng / View DB |
|---|---|
| UserModel | Users + Profiles |
| FieldModel | Fields + vw_FieldRatings |
| FieldSlotModel | vw_FieldSchedule |
| BookingModel | vw_BookingHistory |
| BookingDetailItem | BookingDetails JOIN FieldSlots |
| ServiceModel | Services |
| PaymentModel | Payments |
| DepositModel | Deposits |
| ReviewModel | Reviews |
| NotificationModel | Notifications |

---

## Booking Status

| ID | DB | Flutter Enum | Hiển thị |
|---|---|---|---|
| 1 | Chờ thanh toán | pendingPayment | Badge vàng |
| 2 | Đã xác nhận | confirmed | Badge xanh |
| 3 | Đã hủy | cancelled | Badge đỏ |
| 4 | Đã hoàn thành | completed | Badge xám |
| 5 | Chờ đặt cọc | pendingDeposit | Badge cam |

---

## Stack

- Flutter SDK ≥ 3.3.0 / Dart ≥ 3.3.0
- Backend: Laravel 11 + Supabase
- Database: SQL Server 2019 (SportPlusDB)
- Thanh toán: VNPay, MoMo