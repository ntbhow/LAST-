# DUSTLINE — Windows / Godot 4.5.1

Game battle royale 2D top-down **chơi được, offline, một người + 20 bot**.
Map Sector 07, nhân vật và tài nguyên vector/âm thanh tổng hợp tự thiết kế.
Không cần trình duyệt, tài khoản, server hoặc kết nối Internet khi chơi.

Repository GitHub chứa source, tài liệu và kết quả kiểm thử. Engine portable,
cache, settings cá nhân và các file build không được lưu trong Git. Nếu clone
repo, hãy mở `project.godot` bằng Godot 4.5.1 hoặc tự export theo hướng dẫn dưới đây.

## Chơi ngay

Chạy `build/DUSTLINE.exe`, chọn **DEPLOY**. Hoặc giải nén
`build/DUSTLINE-Windows-x64.zip`, rồi chạy `DUSTLINE.exe`.
EXE chứa sẵn toàn bộ dữ liệu game; không cần cài Godot.

Bạn bắt đầu với dao và một bandage. Có cache súng/đạn/giáp ở phía đông nam
điểm xuất phát. Nhặt đồ, phá thùng, giao tranh, theo dõi vòng bo, sống sót cuối
cùng. Trận mẫu chạy thực tế kết thúc ở 5:51; có thể bị loại sớm hơn.

| Phím | Hành động |
|---|---|
| WASD / Shift | Di chuyển / chạy |
| Chuột / chuột trái | Ngắm / bắn hoặc chém |
| E | Nhặt món đang được chọn ở gần |
| Q / lăn chuột | Chọn giữa các món loot gần nhau |
| R | Thay đạn |
| 1 / 2 / 3 | Súng thứ nhất / thứ hai / dao |
| H / J | Bandage +25 HP trong 2s / medkit đầy HP trong 4s |
| X | Hủy hồi máu, trả lại vật phẩm |
| G | Ném grenade, nổ sau 1,5s, bị cover chặn sát thương |
| Tab | Inventory; chọn súng, dùng và thả đồ |
| M | Bản đồ lớn |
| Esc | Pause; toàn bộ mô phỏng offline dừng |
| F3 | FPS, projectile, loot, bot, seed, recoil, spread |

Inventory và bản đồ **không pause**. Trúng đạn/bo ngắt hồi máu và trả lại item.
Đổi súng hủy reload; đạn dự trữ chỉ chuyển vào băng khi reload hoàn tất.
Khi đủ hai súng, nhặt súng mới thay slot đang chọn (nếu đang cầm dao: slot 2).
Súng cũ được thả cùng đúng số đạn trong băng. Đạn dự trữ thuộc inventory,
không tự đổi loại hay nhân bản. Balô chứa 120/240 đơn vị; shell nặng 2,
vật phẩm tiêu hao nặng 8. Không thể thả balô lớn khi đồ vượt sức chứa balô thường.

Tâm ngắm nở theo spread. Chấm vàng nhỏ cho biết hướng nòng súng sau recoil.
Kéo chuột bù hướng giật; camera shake chỉ là hiệu ứng hình ảnh.

## Đã triển khai

* 100 HP, giáp 25/50 và giáp hư hỏng có thể trao đổi, mũ, balô, hai slot súng.
* Pistol, SMG, AR, shotgun (7 projectile độc lập), DMR, dao và grenade.
  Đạn có tốc độ, tầm, lifetime; segment cast chặn tunneling và nòng sát tường.
* Recoil pattern, bloom, spread khi di chuyển, reload, magazine/reserve,
  pooling 768 projectile, tracer ngắn, muzzle flash, vỏ đạn, bụi/mảnh vỡ.
* Thùng gỗ/quân nhu có HP và bảng rơi đồ có trọng số, chỉ rơi một lần.
* 20 bot dùng chung actor, vũ khí, inventory và damage; LOS, reaction delay,
  memory, bắn đón, hai mức khó, A*, loot, phá thùng, reload, cover, hồi máu và chạy bo.
* Bản đồ có nhà/cửa, mái mờ khi vào nhà, kho, đường, cây, đá và cover;
  7 giai đoạn bo, minimap, bản đồ lớn, thắng/thua, xếp hạng, kill và damage.
* Ba ngoại hình; animation bằng các lớp vector cho đứng/đi/chạy/bắn/reload/
  chém/dùng đồ/ngã; chân và phần thân trên có hướng độc lập.
* Menu, customize, settings, HUD, inventory, pause, kết quả và chơi lại.
  Master/Music/SFX, sensitivity, fullscreen, HUD scale và mức shake lưu cục bộ.

Settings: `%APPDATA%\Godot\app_userdata\DUSTLINE\settings.cfg`.
Không có telemetry. Khi test trong sandbox, script có thể đổi APPDATA của
riêng process sang `tools/profile` để tránh ghi ngoài workspace.

## Mở source / chạy trong editor

1. Dùng Godot **4.5.1 Standard** (GDScript, không cần .NET).
2. Import `project.godot` ở thư mục gốc, mở project và nhấn **F6/F5** theo scene/project.
3. Hoặc `powershell -ExecutionPolicy Bypass -File tools/run.ps1 -Editor`.
   Script này cần Godot portable trong `tools/godot/`, không đưa vào Git/ZIP release.
   Khi clone repo, tải bản Windows x64 Standard từ
   https://github.com/godotengine/godot/releases/tag/4.5.1-stable
   và giải nén hai file EXE vào thư mục đó nếu muốn dùng các script PowerShell.

Chạy source không mở editor:

```powershell
& '.\tools\godot\Godot_v4.5.1-stable_win64_console.exe' --path .
```

## Test và tái hiện

```powershell
powershell -ExecutionPolicy Bypass -File tools/run.ps1 -Tests
& '.\tools\godot\Godot_v4.5.1-stable_win64_console.exe' --path . -- --seed=44621
& '.\tools\godot\Godot_v4.5.1-stable_win64_console.exe' --headless --path . -- --autoplay --soak --speed=8 --seed=44621 --quit-result
```

`--autoplay` giao scout cho cùng AI để kiểm thử. `--soak` tiếp tục theo dõi
đến khi chỉ còn một bot/scout, kể cả scout chết trước. Đây là cờ QA, không phải
chế độ chơi mặc định. Seed cố định tái hiện bố cục/loot, không hứa replay
bit-identical giữa tốc độ mô phỏng hoặc thứ tự physics khác nhau.

Kết quả: `tests/results.json`, `tests/match_report_*.json`, ảnh PNG trong
`tests/`. Ảnh `--capture` dùng loadout QA để kiểm tra HUD/inventory; chế độ
chơi bình thường vẫn bắt đầu bằng dao. Chi tiết ở `docs/TEST_REPORT.md`.
Lượt kiểm tra cuối: **52 pass / 0 fail**. EXE đã chạy riêng, smoke test exit 0.

## Export Windows

```powershell
python tools/fetch_templates.py
powershell -ExecutionPolicy Bypass -File tools/build.ps1
```

Script tải riêng template Windows x64 từ archive chính thức (HTTP ranges,
kiểm tra CRC ZIP), import, export EXE nhúng PCK và đóng ZIP kèm license.
Trong sandbox dùng `tools/build.ps1 -UseWorkspaceProfile`.

Nếu tự cài Godot khác vị trí: **Project → Export → Windows Desktop**,
xóa đường dẫn Custom Template để dùng templates cùng phiên bản đã cài,
chọn Export Project. Preset hiện tại dùng templates cục bộ ở `tools/templates`.
Release chưa được ký code-signing; chưa có installer hoặc auto-update.

## Giới hạn / ưu tiên tiếp theo

1. **P1 — cân bằng/AI:** có trận bot bị loại hàng loạt sớm; trận mẫu 1x kết thúc
   sau 5:51 nhưng không bảo đảm mọi seed kéo dài 5–10 phút. Cover/tactical AI
   còn đơn giản; chưa có chiến thuật đội hoặc dùng grenade chủ động cho bot.
2. **P1 — hiệu năng:** lượt 1080p trên RTX 4060 Laptop đạt khoảng 58 FPS trung bình,
   p95 20,37 ms trong lúc môi trường phát triển cũng chạy tác vụ khác. Chưa đo
   máy phổ thông/iGPU, chưa cam kết 60 FPS ổn định trên mọi cấu hình.
3. **P2 — art/audio:** phong cách vector có chi tiết và phân lớp, chưa phải
   bộ sprite vẽ tay/animation xương. Audio là tổng hợp; cần artist/audio pass
   và playtest người thật để đạt chất lượng phát hành thương mại.
4. **P2 — UX:** UI tiếng Anh, chưa có remap phím, controller, accessibility
   chuyên sâu hoặc độ phân giải siêu rộng được kiểm thử. UI/HUD scale đã có.
5. Multiplayer chưa triển khai đúng phạm vi. Muốn bổ sung cần authority,
   replication, prediction và reconciliation; tách module hiện tại chỉ là nền tảng.

Kiến trúc: `docs/ARCHITECTURE.md`. Nguồn và giấy phép: `docs/ART_AND_ASSETS.md`.
