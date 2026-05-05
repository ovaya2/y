-- Seed: Minimale Länder-Daten (DE/AT/CH)
-- Idempotent: nur einfügen wenn noch nicht vorhanden
IF NOT EXISTS (SELECT 1 FROM [yam3].[d_land] WHERE [iso_code] = 'DE')
BEGIN
    INSERT INTO [yam3].[d_land] ([iso_code], [bezeichnung], [plz_regex]) VALUES
        ('DE', 'Deutschland', N'^\d{5}$'),
        ('AT', N'Österreich',  N'^\d{4}$'),
        ('CH', 'Schweiz',      N'^\d{4}$');
END
