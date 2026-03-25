CREATE TABLE SanPham (
    MaSP VARCHAR(10) PRIMARY KEY,
    TenSP NVARCHAR(100),
    GiaBanLeNuoc DECIMAL(15,2),
    GiaNhapNuoc DECIMAL(15,2),
    GiaTriVo DECIMAL(15,2)
);
GO

CREATE TABLE KhachHang (
    MaKH VARCHAR(10) PRIMARY KEY,
    TenKH NVARCHAR(100),
    DiaChi NVARCHAR(200),
    SDT VARCHAR(15),
    SoVoDangGiu INT DEFAULT 0
);
GO

CREATE TABLE NhaCungCap (
    MaNCC VARCHAR(10) PRIMARY KEY,
    TenNCC NVARCHAR(100),
    SDT VARCHAR(15),
    CongNoTienNhap DECIMAL(15,2) DEFAULT 0,
    SoVoNoNCC INT DEFAULT 0
);
GO

CREATE TABLE Kho (
    MaKho VARCHAR(10) PRIMARY KEY,
    MaSP VARCHAR(10) FOREIGN KEY REFERENCES SanPham(MaSP),
    SoLuongBinhDay INT DEFAULT 0,
    SoLuongVoRong INT DEFAULT 0
);
GO

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
GO

CREATE TABLE HoaDonNhap (
    MaHDN VARCHAR(10) PRIMARY KEY,
    MaNCC VARCHAR(10) FOREIGN KEY REFERENCES NhaCungCap(MaNCC),
    MaSP VARCHAR(10) FOREIGN KEY REFERENCES SanPham(MaSP),
    NgayNhap DATE DEFAULT GETDATE(),
    SL_NhapMoi INT,
    SL_VoTraNCC INT,
    TongTienNhap DECIMAL(15,2)
);
GO

CREATE TRIGGER trg_SauKhiBanHang
ON HoaDonBan
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE h
    SET h.TienNuoc = i.SL_LayMoi * s.GiaBanLeNuoc,
        h.TienVo = (i.SL_LayMoi - i.SL_VoTra) * s.GiaTriVo,
        h.TongTien = (i.SL_LayMoi * s.GiaBanLeNuoc) + ((i.SL_LayMoi - i.SL_VoTra) * s.GiaTriVo)
    FROM HoaDonBan h
    JOIN inserted i ON h.MaHD = i.MaHD
    JOIN SanPham s ON i.MaSP = s.MaSP;

    UPDATE k
    SET k.SoLuongBinhDay = k.SoLuongBinhDay - i.SL_LayMoi,
        k.SoLuongVoRong = k.SoLuongVoRong + i.SL_VoTra
    FROM Kho k
    JOIN inserted i ON k.MaSP = i.MaSP;

    UPDATE kh
    SET kh.SoVoDangGiu = kh.SoVoDangGiu + (i.SL_LayMoi - i.SL_VoTra)
    FROM KhachHang kh
    JOIN inserted i ON kh.MaKH = i.MaKH;
END;
GO

CREATE TRIGGER trg_SauKhiNhapHang
ON HoaDonNhap
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE k
    SET k.SoLuongBinhDay = k.SoLuongBinhDay + i.SL_NhapMoi,
        k.SoLuongVoRong = k.SoLuongVoRong - i.SL_VoTraNCC
    FROM Kho k
    JOIN inserted i ON k.MaSP = i.MaSP;

    UPDATE ncc
    SET ncc.SoVoNoNCC = ncc.SoVoNoNCC + (i.SL_NhapMoi - i.SL_VoTraNCC),
        ncc.CongNoTienNhap = ncc.CongNoTienNhap + (i.SL_NhapMoi * s.GiaNhapNuoc) + ((i.SL_NhapMoi - i.SL_VoTraNCC) * s.GiaTriVo)
    FROM NhaCungCap ncc
    JOIN inserted i ON ncc.MaNCC = i.MaNCC
    JOIN SanPham s ON i.MaSP = s.MaSP;
END;
GO

CREATE PROCEDURE sp_LayDanhSachNoKhach
AS
BEGIN
    SELECT MaKH, TenKH, SDT, SoVoDangGiu FROM KhachHang WHERE SoVoDangGiu <> 0;
END;
GO

CREATE PROCEDURE sp_XemTonKho
AS
BEGIN
    SELECT s.TenSP, k.SoLuongBinhDay, k.SoLuongVoRong
    FROM Kho k
    JOIN SanPham s ON k.MaSP = s.MaSP;
END;
GO
