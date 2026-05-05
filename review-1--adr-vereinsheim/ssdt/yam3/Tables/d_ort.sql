CREATE TABLE [yam3].[d_ort]
(
    [ort_id]     INT           NOT NULL IDENTITY(1,1),
    [land_id]    INT           NOT NULL,
    [plz]        VARCHAR(10)   NOT NULL,
    [ort]        NVARCHAR(100) NOT NULL,
    [bundesland] NVARCHAR(50)  NULL,
    CONSTRAINT [pk_d_ort]      PRIMARY KEY CLUSTERED ([ort_id] ASC),
    CONSTRAINT [fk_d_ort_land] FOREIGN KEY ([land_id]) REFERENCES [yam3].[d_land] ([land_id]),
    CONSTRAINT [uq_d_ort_kombi] UNIQUE ([land_id], [plz], [ort])
);

CREATE INDEX [ix_d_ort_plz] ON [yam3].[d_ort] ([plz]);
