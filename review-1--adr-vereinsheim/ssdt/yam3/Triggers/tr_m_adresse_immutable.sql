CREATE TRIGGER [yam3].[tr_m_adresse_immutable]
ON [yam3].[m_adresse]
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- CONTEXT_INFO() kann NULL sein (Initialzustand) → explizit prüfen,
    -- sonst wäre NULL <> 'adresse_korrektur' = NULL (= kein Fehler, Trigger bypassed)
    DECLARE @ctx VARBINARY(128) = CONTEXT_INFO();
    IF @ctx IS NULL OR @ctx <> CAST('adresse_korrektur' AS VARBINARY(128))
    BEGIN
        RAISERROR('m_adresse ist immutable. Korrekturen nur über sp_adresse_korrigieren.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE a
    SET    [strasse]      = i.[strasse],
           [hausnummer]   = i.[hausnummer],
           [adresszusatz] = i.[adresszusatz],
           [ort_id]       = i.[ort_id]
    FROM   [yam3].[m_adresse] a
    INNER JOIN inserted i ON a.[adresse_id] = i.[adresse_id];
END;
