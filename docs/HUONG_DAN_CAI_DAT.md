# Hướng dẫn cài đặt và chạy ScanGuard (GraphFusionDetect)

ScanGuard gồm ba thành phần:

| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| `backend` | FastAPI (Python 3.10), PyTorch + DGL, CodeBERT, Slither + solc | Phân tích hợp đồng, quét lỗ hổng timestamp và reentrancy, giải thích bằng LLM, kiểm tra bản sửa |
| `frontend` | React 18 + Vite, phục vụ bằng nginx | Giao diện web, gọi `/api` qua nginx |
| `mongodb` | MongoDB 7 | Tài khoản, phiên phân tích, đánh giá của chuyên gia, bản sửa |

Cách chạy được hỗ trợ là **Docker Compose**. Image backend đã xử lý sẵn các phần khó cài tay: bản `dgl` tương thích, Slither 0.9.6 và toàn bộ các phiên bản `solc` mà Slither cần.

---

## 1. Yêu cầu

- Linux x86-64, Docker 24+ và Docker Compose v2.24+ (cần cho cú pháp `!override` trong `docker-compose.local.yml`).
- Khoảng 15 GB ổ đĩa (image backend, các bản solc, cache model HuggingFace).
- RAM 8 GB trở lên.
- **Tuỳ chọn:** GPU NVIDIA và [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/). Không có GPU thì vẫn chạy được trên CPU (xem mục 3.3).
- Một khoá API LLM tương thích OpenAI (Gemini hoặc nhà cung cấp khác) để có phần giải thích lỗ hổng và RefactorBot.
- **Tuỳ chọn:** khoá Etherscan, để dùng tính năng tìm token theo tên.

## 2. Lấy mã nguồn và các file model

```bash
git clone https://github.com/Hieurezdev/GraphFusionVulDetect.git
cd GraphFusionVulDetect
```

Các model nằm ở `src/infrastructure/analysis_model/`:

| File | Có trong git? | Dùng cho |
|---|---|---|
| `best_model_GCN_2L_max.pt` | có | Timestamp, mức hợp đồng |
| `best_node_classifier_model.pt` | có | Timestamp, mức hàm |
| `best_model_GAT_2L_max_reentrancy.pt` (211 MB) | **không**, vượt giới hạn 100 MB của GitHub | Reentrancy, mức hợp đồng |
| `best_node_classifier_model_reentrancy.pt` | **không** | Reentrancy, mức hàm |

Hai file reentrancy phải chép thủ công từ server hoặc từ nhóm phát triển vào đúng thư mục trên. Thiếu hai file này thì backend vẫn khởi động, nhưng **chỉ quét timestamp** và bỏ qua reentrancy.

Encoder CodeBERT (`Quangnguyen711/codebert-solidity-time-dep`, `Quangnguyen711/codebert-solidity-re-entrancy`) được tải tự động từ HuggingFace trong lần chạy đầu.

## 3. Chạy bằng Docker Compose

### 3.1. Tạo file `.env`

```bash
cp .env.example .env
chmod 600 .env   # file chứa khoá bí mật: chỉ chủ sở hữu được đọc
```

Các biến **bắt buộc** (backend sẽ không khởi động nếu thiếu):

```dotenv
# Model
EMBEDDING_MODEL_PATH="Quangnguyen711/codebert-solidity-time-dep"
GRAPH_VUL_MODEL_PATH="src/infrastructure/analysis_model/best_model_GCN_2L_max.pt"
NODE_VUL_MODEL_PATH="src/infrastructure/analysis_model/best_node_classifier_model.pt"

# LLM (API tương thích OpenAI). Không cần nếu đặt LOCAL_LLM_MODEL (xem bảng dưới)
BASE_URL="https://<địa chỉ API>/v1"
MODEL_NAME="<tên model>"
GEMINI_API_KEY1="<khoá API>"      # lưu ý: tên biến có số 1 ở cuối

# Database (docker-compose.prod.yml tự đặt lại hai biến này cho container)
MONGODB_URL="mongodb://localhost:27017"
MONGODB_DATABASE="graphfusion"

# Bảo mật: sinh ngẫu nhiên, KHÔNG dùng giá trị mẫu
SECRET_KEY="<openssl rand -hex 32>"
JWT_SECRET="<openssl rand -hex 32>"
```

Các biến tuỳ chọn:

| Biến | Mặc định | Ghi chú |
|---|---|---|
| `ETHERSCAN_API_KEY` | (trống) | Cần cho tính năng tìm token (chỉ hỗ trợ Ethereum) |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | 30 | Thời hạn phiên đăng nhập |
| `CHATBOT_TEMPERATURE` / `CHATBOT_MAX_TOKENS` | 0.7 / 4096 | Tham số LLM |
| `REENTRANCY_*_MODEL_PATH` | đường dẫn ở mục 2 | Chỉ đổi khi đặt model reentrancy ở chỗ khác |
| `LOCAL_LLM_MODEL` | (trống) | Đặt tên model Hugging Face, ví dụ `suzeai/Qwen2.5-Coder-1.5B-explain-vul-wo-system`, để **chạy LLM ngay trên server thay cho API**. Khi đặt biến này, `BASE_URL`, `MODEL_NAME`, `GEMINI_API_KEY1` không cần nữa. Để trống thì dùng API như cũ |
| `LOCAL_LLM_MAX_NEW_TOKENS` / `LOCAL_LLM_MAX_INPUT_TOKENS` | 1024 / 8192 | Độ dài câu trả lời / độ dài đầu vào tối đa của LLM chạy trên server |

Sinh khoá bí mật:

```bash
sed -i "s|^SECRET_KEY=.*|SECRET_KEY=\"$(openssl rand -hex 32)\"|; s|^JWT_SECRET=.*|JWT_SECRET=\"$(openssl rand -hex 32)\"|" .env
```

> `.env.example` ghi `GEMINI_API_KEY`, nhưng backend đọc `GEMINI_API_KEY1`. Hãy đặt đúng tên `GEMINI_API_KEY1`.
> Đổi `JWT_SECRET` sẽ đăng xuất toàn bộ người dùng.

### 3.2. Chạy thử trên máy (stack local)

`docker-compose.local.yml` dựng một bộ độc lập gồm database và storage riêng, frontend ở cổng 18511 và chỉ nghe trên `127.0.0.1`.

```bash
# Lần đầu: dùng chung cache model với production. Nếu chưa từng chạy production thì tạo volume trống:
docker volume create scanguard_hf_cache

docker compose -p scanguard-local -f docker-compose.prod.yml -f docker-compose.local.yml up -d --build
```

Mở http://localhost:18511. Nếu Docker chạy trên server từ xa, mở đường hầm SSH từ máy của bạn:

```bash
ssh -L 18511:127.0.0.1:18511 <user>@<server>
```

`docker-compose.local.yml` cố định subnet `10.254.151.0/24`, vì server phát triển đã dùng hết dải IP mặc định của Docker. Nếu subnet này trùng với mạng trên máy bạn, đổi sang một dải khác hoặc xoá khối `networks:`.

Dừng stack:

```bash
docker compose -p scanguard-local -f docker-compose.prod.yml -f docker-compose.local.yml down      # giữ dữ liệu
docker compose -p scanguard-local -f docker-compose.prod.yml -f docker-compose.local.yml down -v   # xoá luôn DB và file upload
```

### 3.3. Chạy không có GPU

Tạo `docker-compose.cpu.yml`:

```yaml
services:
  backend:
    environment:
      - DEVICE=cpu
    deploy: !reset {}
```

Rồi thêm `-f docker-compose.cpu.yml` vào cuối mọi lệnh `docker compose` ở trên. Trên CPU, CodeBERT chậm hơn nhiều: hợp đồng vài trăm dòng mất cỡ một phút thay vì vài giây.

### 3.4. Triển khai production

Production chạy sau một nginx trên host có TLS: `https://<domain>` → nginx host → `127.0.0.1:18510` (frontend) → `/api` → backend.

1. Sửa domain trong `docker-compose.prod.yml` (build arg `VITE_API_BASE_URL`) và trong `docker/scanguard.ptitai.org.nginx`.
2. Cài site nginx và lấy chứng chỉ Let's Encrypt (cần quyền sudo):
   ```bash
   sudo bash docker/install-nginx-site.sh
   ```
3. Build và chạy:
   ```bash
   docker compose -p scanguard -f docker-compose.prod.yml up -d --build
   ```
4. Kiểm tra:
   ```bash
   curl https://<domain>/api/v1/health   # {"status":"ready",...}
   ```

Cập nhật code mới thì chạy lại bước 3. Database và file upload nằm trong các volume `scanguard_mongodb_data` và `scanguard_storage`, nên không mất khi build lại.

Nginx trong container (`docker/nginx.conf`) đã giới hạn tần suất theo IP: đăng nhập/đăng ký 10 lần/phút; `/analyze`, `/refactor`, `/token` 20 lần/phút. Giới hạn này dựa vào header `X-Real-IP` do nginx host đặt.

## 4. Tài khoản và phân quyền

Người dùng tự đăng ký trên trang `/register`. Username chỉ gồm chữ, số và `_ . -` (không có `@`), và đăng nhập được bằng username hoặc email.

Có hai vai trò:

| Vai trò | Quyền |
|---|---|
| `user` (mặc định) | Phân tích hợp đồng của mình; đề xuất bản sửa, biên dịch và kiểm tra lại |
| `expert` | Xem phân tích của mọi người (trang "Chuyên gia rà soát"); xác nhận hoặc bác bỏ cảnh báo; chấp nhận hoặc từ chối bản sửa |

Không có cách tự nâng quyền lên chuyên gia. Quản trị viên đặt quyền trực tiếp trong database:

```bash
docker compose -p scanguard -f docker-compose.prod.yml exec mongodb \
  mongosh graphfusion --eval 'db.users.updateOne({username:"<tên>"},{$set:{role:"expert"}})'
```

Với stack local, thay `-p scanguard -f docker-compose.prod.yml` bằng `-p scanguard-local -f docker-compose.prod.yml -f docker-compose.local.yml`.

## 5. Phát triển frontend với hot reload

Khi chỉ sửa giao diện, có thể chạy Vite trực tiếp và trỏ vào một backend đang chạy:

```bash
cd web_react
npm ci
VITE_API_BASE_URL=http://localhost:18511 npm run dev   # http://localhost:8080
```

Backend cho phép CORS từ `http://localhost:8080` và `http://localhost:3000` (thay đổi trong `src/api/app.py`).

## 6. Chạy test

Test backend chạy trong image backend, không cần cài gì trên máy:

```bash
docker compose -p scanguard -f docker-compose.prod.yml build backend
docker run --rm -v "$PWD":/repo:ro --entrypoint sh scanguard-backend -c \
  "cp -r /repo /tmp/r && cd /tmp/r && uv pip install -q --python /graphfusion/.venv/bin/python pytest httpx \
   && /graphfusion/.venv/bin/python -m pytest -q tests"
```

Kiểm tra kiểu TypeScript của frontend:

```bash
cd web_react && npm ci && npx tsc --noEmit -p tsconfig.app.json
```

## 7. Dùng thử nhanh

1. Đăng ký tài khoản, vào **New Analysis**, tải lên một file `.sol`. Có sẵn mẫu trong `demo/EtherStore.sol` và `assets/datasets/`.
2. Kết quả hiện theo từng bước. Kết luận chung có cho cả hai loại lỗ hổng; các hàm bị gắn cờ có số dòng, giải thích và IDE đánh dấu đỏ.
3. Đăng nhập tài khoản `expert`, vào **Chuyên gia rà soát** để xác nhận cảnh báo.
4. Quay lại tài khoản thường, dùng RefactorBot hoặc IDE để đề xuất bản sửa, rồi bấm **Compile & re-check (solc + Slither)**.
5. Chuyên gia duyệt bản sửa ở bảng **Fix workflow**.
6. Tải **SARIF** để mở trong VS Code (SARIF Viewer) hoặc đẩy lên GitHub code scanning. Mẫu workflow CI có ở `integrations/github-actions/scanguard.yml`.

Có thể chạy lại toàn bộ luồng trên bằng script:

```bash
BASE=http://localhost:18511 USER_LOGIN=<user>:<mật khẩu> EXPERT_LOGIN=<expert>:<mật khẩu> python demo/run_demo.py
```

## 8. Xử lý sự cố

| Hiện tượng | Nguyên nhân và cách xử lý |
|---|---|
| Backend thoát ngay, log báo `ValidationError ... Field required` | Thiếu biến bắt buộc trong `.env` (mục 3.1), thường là `GEMINI_API_KEY1` |
| Chỉ quét timestamp, không có reentrancy | Thiếu hai file model reentrancy (mục 2) |
| "Could not build the call graph…" | Hợp đồng không biên dịch được với phiên bản solc trong `pragma`, có `import` tới file không được tải lên, hoặc dùng tính năng Solidity mới hơn Slither hỗ trợ. Cần rà soát thủ công |
| `all predefined address pools have been fully subnetted` | Docker hết dải IP mặc định: đặt subnet riêng như trong `docker-compose.local.yml` |
| `CUDA out of memory` | GPU đang dùng chung với tiến trình khác: chạy chế độ CPU (mục 3.3) hoặc giải phóng GPU |
| HTTP 429 | Vượt giới hạn tần suất của nginx (mục 3.4), hoặc CoinGecko đang quá tải khi tìm token: chờ một phút |
| Sau khi đổi `JWT_SECRET` mọi người bị đăng xuất | Đây là hành vi đúng: token cũ không còn hợp lệ |

## 9. Sao lưu

Hiện chưa có sao lưu tự động. Nên sao lưu định kỳ hai volume `scanguard_mongodb_data` và `scanguard_storage`. Ví dụ, sao lưu thủ công:

```bash
docker compose -p scanguard -f docker-compose.prod.yml exec -T mongodb mongodump --archive --gzip > backup_$(date +%F).archive.gz
docker run --rm -v scanguard_storage:/s:ro -v "$PWD":/b alpine tar czf /b/storage_$(date +%F).tgz -C /s .
```
