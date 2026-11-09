using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);
// Nghe trên mọi địa chỉ mạng để điện thoại thật gọi được
builder.WebHost.UseUrls("http://0.0.0.0:5000");
var app = builder.Build();

var connectionString = app.Configuration.GetConnectionString("Default")!;

async Task<SqlConnection> MoKetNoi()
{
    var conn = new SqlConnection(connectionString);
    await conn.OpenAsync();
    return conn;
}

app.MapGet("/api/ping", () => Results.Ok(new { ok = true }));

// ================ SINH VIÊN ================
app.MapGet("/api/sinhvien", async () =>
{
    await using var conn = await MoKetNoi();
    await using var cmd = new SqlCommand(
        "SELECT MSSV, HoTen, CASE WHEN Anh IS NULL THEN 0 ELSE 1 END FROM SinhVien ORDER BY MSSV", conn);
    await using var reader = await cmd.ExecuteReaderAsync();

    var ds = new List<SinhVienDto>();
    while (await reader.ReadAsync())
        ds.Add(new SinhVienDto(reader.GetString(0), reader.GetString(1), reader.GetInt32(2) == 1));
    return Results.Ok(ds);
});

// Nhập danh sách: từ đã có thì bỏ qua, không ghi đè
app.MapPost("/api/sinhvien/nhap", async (List<NhapSinhVien> ds) =>
{
    await using var conn = await MoKetNoi();
    int them = 0, trung = 0;
    foreach (var sv in ds)
    {
        if (string.IsNullOrWhiteSpace(sv.Mssv) || string.IsNullOrWhiteSpace(sv.HoTen)) continue;

        await using var cmd = new SqlCommand(
            @"IF NOT EXISTS (SELECT 1 FROM SinhVien WHERE MSSV = @mssv)
              INSERT SinhVien (MSSV, HoTen) VALUES (@mssv, @hoTen)", conn);
        cmd.Parameters.AddWithValue("@mssv", sv.Mssv.Trim());
        cmd.Parameters.AddWithValue("@hoTen", sv.HoTen.Trim());
        if (await cmd.ExecuteNonQueryAsync() > 0) them++; else trung++;
    }
    return Results.Ok(new { them, trung });
});

app.MapDelete("/api/sinhvien/{mssv}", async (string mssv) =>
{
    await using var conn = await MoKetNoi();
    await using var cmd = new SqlCommand("DELETE FROM SinhVien WHERE MSSV = @mssv", conn);
    cmd.Parameters.AddWithValue("@mssv", mssv);
    return await cmd.ExecuteNonQueryAsync() > 0 ? Results.NoContent() : Results.NotFound();
});

// Ảnh chụp từ camera lưu trong cột VARBINARY
app.MapGet("/api/sinhvien/{mssv}/anh", async (string mssv) =>
{
    await using var conn = await MoKetNoi();
    await using var cmd = new SqlCommand("SELECT Anh FROM SinhVien WHERE MSSV = @mssv", conn);
    cmd.Parameters.AddWithValue("@mssv", mssv);
    var anh = await cmd.ExecuteScalarAsync() as byte[];
    return anh == null ? Results.NotFound() : Results.File(anh, "image/jpeg");
});

app.MapPut("/api/sinhvien/{mssv}/anh", async (string mssv, CapNhatAnh body) =>
{
    byte[] anh;
    try
    {
        anh = Convert.FromBase64String(body.AnhBase64);
    }
    catch (FormatException)
    {
        return Results.BadRequest(new { loi = "Ảnh không hợp lệ" });
    }

    await using var conn = await MoKetNoi();
    await using var cmd = new SqlCommand("UPDATE SinhVien SET Anh = @anh WHERE MSSV = @mssv", conn);
    cmd.Parameters.AddWithValue("@mssv", mssv);
    cmd.Parameters.Add("@anh", System.Data.SqlDbType.VarBinary, -1).Value = anh;
    return await cmd.ExecuteNonQueryAsync() > 0 ? Results.NoContent() : Results.NotFound();
});

// ================ MÔN HỌC ================
app.MapGet("/api/monhoc", async () =>
{
    await using var conn = await MoKetNoi();
    await using var cmd = new SqlCommand("SELECT MaMon, TenMon, CoSo, GioHoc FROM MonHoc ORDER BY MaMon", conn);
    await using var reader = await cmd.ExecuteReaderAsync();

    var ds = new List<MonHocDto>();
    while (await reader.ReadAsync())
        ds.Add(new MonHocDto(
            reader.GetString(0),
            reader.GetString(1),
            reader.GetString(2),
            reader.IsDBNull(3) ? null : reader.GetDateTime(3)));
    return Results.Ok(ds);
});

// Đã có mã môn thì cập nhật, chưa có thì thêm
app.MapPost("/api/monhoc", async (MonHocDto mon) =>
{
    if (string.IsNullOrWhiteSpace(mon.MaMon) || string.IsNullOrWhiteSpace(mon.TenMon))
        return Results.BadRequest(new { loi = "Thiếu mã môn hoặc tên môn" });

    await using var conn = await MoKetNoi();
    await using var cmd = new SqlCommand(
        @"IF EXISTS (SELECT 1 FROM MonHoc WHERE MaMon = @ma)
              UPDATE MonHoc SET TenMon = @ten, CoSo = @coSo, GioHoc = @gio WHERE MaMon = @ma
          ELSE
              INSERT MonHoc (MaMon, TenMon, CoSo, GioHoc) VALUES (@ma, @ten, @coSo, @gio)", conn);
    cmd.Parameters.AddWithValue("@ma", mon.MaMon.Trim());
    cmd.Parameters.AddWithValue("@ten", mon.TenMon.Trim());
    cmd.Parameters.AddWithValue("@coSo", mon.CoSo);
    cmd.Parameters.AddWithValue("@gio", (object?)mon.GioHoc ?? DBNull.Value);
    await cmd.ExecuteNonQueryAsync();
    return Results.Ok(mon);
});

app.MapDelete("/api/monhoc/{maMon}", async (string maMon) =>
{
    await using var conn = await MoKetNoi();
    await using var cmd = new SqlCommand("DELETE FROM MonHoc WHERE MaMon = @ma", conn);
    cmd.Parameters.AddWithValue("@ma", maMon);
    return await cmd.ExecuteNonQueryAsync() > 0 ? Results.NoContent() : Results.NotFound();
});

app.Run();

record SinhVienDto(string Mssv, string HoTen, bool CoAnh);
record NhapSinhVien(string Mssv, string HoTen);
record CapNhatAnh(string AnhBase64);
record MonHocDto(string MaMon, string TenMon, string CoSo, DateTime? GioHoc);
