CREATE TABLE [yam3].[d_land]
(
    [land_id]     INT           NOT NULL IDENTITY(1,1),
    [iso_code]    CHAR(2)       NOT NULL,
    [bezeichnung] NVARCHAR(100) NOT NULL,
    [plz_regex]   NVARCHAR(100) NULL,
    CONSTRAINT [pk_d_land]     PRIMARY KEY CLUSTERED ([land_id] ASC),
    CONSTRAINT [uq_d_land_iso] UNIQUE ([iso_code])
);
