const express = require('express');
const sql = require('mssql/msnodesqlv8');
const config = require('./config.json');

const app = express();
// Ảnh gửi lên dạng base64 nên phải nới giới hạn mặc định 100 KB
app.use(express.json({ limit: '20mb' }));

// Máy có bản driver ODBC nào thì dùng bản đó
const DRIVERS = [
  'ODBC Driver 18 for SQL Server',
  'ODBC Driver 17 for SQL Server',
  'SQL Server',
];

function chuoiKetNoi(driver) {
  const dangNhap = process.env.DB_USER
    ? `UID=${process.env.DB_USER};PWD=${process.env.DB_PASSWORD};`
    : 'Trusted_Connection=yes;';
  return `Driver={${driver}};Server=${config.server};Database=${config.database};${dangNhap}TrustServerCertificate=yes;`;
}

async function moKetNoi() {
  let loiCuoi;
  for (const driver of DRIVERS) {
    try {
      const pool = await new sql.ConnectionPool({
        connectionString: chuoiKetNoi(driver),
      }).connect();
      console.log(`Da ket noi SQL Server bang driver: ${driver}`);
      return pool;
    } catch (e) {
      loiCuoi = e;
    }
  }
  throw loiCuoi;
}

let pool;

app.get('/api/ping', (req, res) => res.json({ ok: true }));

// ================ SINH VIÊN ================
app.get('/api/sinhvien', async (req, res) => {
  const kq = await pool.request().query(
    'SELECT MSSV, HoTen, CASE WHEN Anh IS NULL THEN 0 ELSE 1 END AS CoAnh FROM SinhVien ORDER BY MSSV',
  );
  res.json(
    kq.recordset.map((r) => ({
      mssv: r.MSSV,
      hoTen: r.HoTen,
      coAnh: r.CoAnh === 1,
    })),
  );
});

// Nhập danh sách: MSSV đã có thì bỏ qua, không ghi đè
app.post('/api/sinhvien/nhap', async (req, res) => {
  let them = 0;
  let trung = 0;
  for (const sv of req.body) {
    const mssv = (sv.mssv ?? '').trim();
    const hoTen = (sv.hoTen ?? '').trim();
    if (!mssv || !hoTen) continue;

    const kq = await pool
      .request()
      .input('mssv', sql.NVarChar(20), mssv)
      .input('hoTen', sql.NVarChar(100), hoTen)
      .query(
        'INSERT SinhVien (MSSV, HoTen) SELECT @mssv, @hoTen WHERE NOT EXISTS (SELECT 1 FROM SinhVien WHERE MSSV = @mssv)',
      );
    if (kq.rowsAffected[0] > 0) them++;
    else trung++;
  }
  res.json({ them, trung });
});

app.delete('/api/sinhvien/:mssv', async (req, res) => {
  const kq = await pool
    .request()
    .input('mssv', sql.NVarChar(20), req.params.mssv)
    .query('DELETE FROM SinhVien WHERE MSSV = @mssv');
  res.sendStatus(kq.rowsAffected[0] > 0 ? 204 : 404);
});

// Ảnh chụp từ camera lưu trong cột VARBINARY
app.get('/api/sinhvien/:mssv/anh', async (req, res) => {
  const kq = await pool
    .request()
    .input('mssv', sql.NVarChar(20), req.params.mssv)
    .query('SELECT Anh FROM SinhVien WHERE MSSV = @mssv');
  const anh = kq.recordset[0]?.Anh;
  if (!anh) return res.sendStatus(404);
  res.type('image/jpeg').send(anh);
});

app.put('/api/sinhvien/:mssv/anh', async (req, res) => {
  const base64 = req.body.anhBase64 ?? '';
  if (!base64 || !/^[A-Za-z0-9+/]+={0,2}$/.test(base64)) {
    return res.status(400).json({ loi: 'Ảnh không hợp lệ' });
  }

  const kq = await pool
    .request()
    .input('mssv', sql.NVarChar(20), req.params.mssv)
    .input('anh', sql.VarBinary(sql.MAX), Buffer.from(base64, 'base64'))
    .query('UPDATE SinhVien SET Anh = @anh WHERE MSSV = @mssv');
  res.sendStatus(kq.rowsAffected[0] > 0 ? 204 : 404);
});

// ================ MÔN HỌC ================
app.get('/api/monhoc', async (req, res) => {
  // Trả giờ dạng chuỗi không múi giờ để app đọc đúng giờ Việt Nam
  const kq = await pool.request().query(
    'SELECT MaMon, TenMon, CoSo, CONVERT(varchar(19), GioHoc, 126) AS GioHoc FROM MonHoc ORDER BY MaMon',
  );
  res.json(
    kq.recordset.map((r) => ({
      maMon: r.MaMon,
      tenMon: r.TenMon,
      coSo: r.CoSo,
      gioHoc: r.GioHoc,
    })),
  );
});

// Đã có mã môn thì cập nhật, chưa có thì thêm
app.post('/api/monhoc', async (req, res) => {
  const maMon = (req.body.maMon ?? '').trim();
  const tenMon = (req.body.tenMon ?? '').trim();
  if (!maMon || !tenMon) {
    return res.status(400).json({ loi: 'Thiếu mã môn hoặc tên môn' });
  }

  await pool
    .request()
    .input('ma', sql.NVarChar(20), maMon)
    .input('ten', sql.NVarChar(200), tenMon)
    .input('coSo', sql.NVarChar(50), req.body.coSo)
    .input('gio', sql.VarChar(30), req.body.gioHoc ?? null)
    .query(`IF EXISTS (SELECT 1 FROM MonHoc WHERE MaMon = @ma)
              UPDATE MonHoc SET TenMon = @ten, CoSo = @coSo, GioHoc = @gio WHERE MaMon = @ma
            ELSE
              INSERT MonHoc (MaMon, TenMon, CoSo, GioHoc) VALUES (@ma, @ten, @coSo, @gio)`);
  res.json(req.body);
});

app.delete('/api/monhoc/:maMon', async (req, res) => {
  const kq = await pool
    .request()
    .input('ma', sql.NVarChar(20), req.params.maMon)
    .query('DELETE FROM MonHoc WHERE MaMon = @ma');
  res.sendStatus(kq.rowsAffected[0] > 0 ? 204 : 404);
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ loi: 'Lỗi máy chủ' });
});

moKetNoi()
  .then((p) => {
    pool = p;
    // Nghe trên mọi địa chỉ mạng để điện thoại thật gọi được
    // Express 5 báo lỗi qua callback, không xử lý thì trùng cổng vẫn tưởng là chạy được
    app.listen(config.port, '0.0.0.0', (err) => {
      if (err) {
        console.error(`Khong mo duoc cong ${config.port}: ${err.message}`);
        process.exit(1);
      }
      console.log(`API dang chay tai http://0.0.0.0:${config.port}`);
    });
  })
  .catch((e) => {
    console.error('Khong ket noi duoc SQL Server. Kiem tra config.json va database KtraFlutter.');
    console.error(e.message);
    process.exit(1);
  });
