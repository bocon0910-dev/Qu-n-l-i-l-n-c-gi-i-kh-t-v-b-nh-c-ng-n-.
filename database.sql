
CREATE TABLE SanPham (
    MaSP VARCHAR(10) PRIMARY KEY,
    TenSP NVARCHAR(100),
    GiaBanLeNuoc DECIMAL(15,2),
    GiaNhapNuoc DECIMAL(15,2),
    GiaTriVo DECIMAL(15,2)
);


CREATE TABLE KhachHang (
    MaKH VARCHAR(10) PRIMARY KEY,
    TenKH NVARCHAR(100),
    DiaChi NVARCHAR(200),
    SDT VARCHAR(15),
    SoVoDangGiu INT DEFAULT 0
);


CREATE TABLE NhaCungCap (
    MaNCC VARCHAR(10) PRIMARY KEY,
    TenNCC NVARCHAR(100),
    SDT VARCHAR(15),
    CongNoTienNhap DECIMAL(15,2) DEFAULT 0,
    SoVoNoNCC INT DEFAULT 0
);


CREATE TABLE Kho (
    MaKho VARCHAR(10) PRIMARY KEY,
    MaSP VARCHAR(10) FOREIGN KEY REFERENCES SanPham(MaSP),
    SoLuongBinhDay INT DEFAULT 0,
    SoLuongVoRong INT DEFAULT 0
);


CREATE TABLE HoaDonBan (
    MaHD VARCHAR(10) PRIMARY KEY,
    MaKH VARCHAR(10) FOREIGN KEY REFERENCES KhachHang(MaKH),
    MaSP VARCHAR(10) FOREIGN KEY REFERENCES SanPham(MaSP),
    NgayLap DATE DEFAULT GETDATE(),
    SL_LayMoi INT,
    SL_VoTra INT,
    TienNuoc DECIMAL(15,2),
    TienVo DECIMAL(15,2),
    TongTien DECIMAL(15,2)
);


CREATE TABLE HoaDonNhap (
    MaHDN VARCHAR(10) PRIMARY KEY,
    MaNCC VARCHAR(10) FOREIGN KEY REFERENCES NhaCungCap(MaNCC),
    MaSP VARCHAR(10) FOREIGN KEY REFERENCES SanPham(MaSP),
    NgayNhap DATE DEFAULT GETDATE(),
    SL_NhapMoi INT,
    SL_VoTraNCC INT,
    TongTienNhap DECIMAL(15,2)
);

CREATE TRIGGER trg_SauKhiBanHang
ON HoaDonBan
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaHD VARCHAR(10), @MaKH VARCHAR(10), @MaSP VARCHAR(10);
    DECLARE @P INT, @Q INT, @GiaNuoc DECIMAL(15,2), @GiaVo DECIMAL(15,2);

    SELECT @MaHD = MaHD, @MaKH = MaKH, @MaSP = MaSP, @P = SL_LayMoi, @Q = SL_VoTra 
    FROM inserted;

    SELECT @GiaNuoc = GiaBanLeNuoc, @GiaVo = GiaTriVo FROM SanPham WHERE MaSP = @MaSP;

    UPDATE HoaDonBan
    SET TienNuoc = @P * @GiaNuoc,
        TienVo = (@P - @Q) * @GiaVo,
        TongTien = (@P * @GiaNuoc) + ((@P - @Q) * @GiaVo)
    WHERE MaHD = @MaHD;

    UPDATE Kho 
    SET SoLuongBinhDay = SoLuongBinhDay - @P,
        SoLuongVoRong = SoLuongVoRong + @Q
    WHERE MaSP = @MaSP;

    UPDATE KhachHang SET SoVoDangGiu = SoVoDangGiu + (@P - @Q) WHERE MaKH = @MaKH;
END;

CREATE TRIGGER trg_SauKhiNhapHang
ON HoaDonNhap
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaHDN VARCHAR(10), @MaNCC VARCHAR(10), @MaSP VARCHAR(10);
    DECLARE @Z INT, @Alpha INT, @GiaNhap DECIMAL(15,2), @GiaVo DECIMAL(15,2);

    SELECT @MaHDN = MaHDN, @MaNCC = MaNCC, @MaSP = MaSP, @Z = SL_NhapMoi, @Alpha = SL_VoTraNCC 
    FROM inserted;

    SELECT @GiaNhap = GiaNhapNuoc, @GiaVo = GiaTriVo FROM SanPham WHERE MaSP = @MaSP;

    UPDATE Kho 
    SET SoLuongBinhDay = SoLuongBinhDay + @Z,
        SoLuongVoRong = SoLuongVoRong - @Alpha
    WHERE MaSP = @MaSP;

    UPDATE NhaCungCap 
    SET SoVoNoNCC = SoVoNoNCC + (@Z - @Alpha),
        CongNoTienNhap = CongNoTienNhap + (@Z * @GiaNhap) + ((@Z - @Alpha) * @GiaVo)
    WHERE MaNCC = @MaNCC;
END;