CREATE VIEW w.ProzentProBruttoBedarf AS
    WITH GesamtStimmen AS (
        SELECT s.landtagswahl, s.stimmkreis, x.stimmkreisname, x.wahlkreisname, s.partei,
               coalesce(s.erststimmen + s.zweitstimmen, 0) as GesamtStimmen
        FROM w.StimmenProParteiStimmkreis s
        INNER JOIN w.stimmkreis x
            ON x.landtagswahl = s.landtagswahl
            AND x.nummer = s.stimmkreis
        WHERE s.landtagswahl = 2018
    ), StimmenProKreis AS (
        SELECT s.partei, s.GesamtStimmen, g.kreisschluessel
        FROM GesamtStimmen s
        INNER JOIN w.gemeinde g
            ON g.stimmkreis = s.stimmkreis
        GROUP BY s.partei, s.GesamtStimmen, g.kreisschluessel
    ), ParteiStimmenBedarfWindow AS (
        SELECT s.partei, s.GesamtStimmen, b.bruttobedarf / 15 * 15 as bWindowed
        FROM StimmenProKreis s
        INNER JOIN w.Bedarf b
            ON b.kreisschluessel = s.kreisschluessel
    ), ParteiStimmenBedarfWindowGrouped AS (
        SELECT b.partei, b.bWindowed, SUM(b.GesamtStimmen) as GesamtStimmen
        FROM ParteiStimmenBedarfWindow b
        GROUP BY b.partei, b.bWindowed
    ), GesamtStimmenProWindow AS (
        SELECT p.bWindowed, SUM(p.GesamtStimmen) as WindowGesamt
        FROM ParteiStimmenBedarfWindowGrouped p
        GROUP BY p.bWindowed
    ), ParteiProzentBedarfWindowGrouped AS (
        SELECT x.partei, x.bWindowed, x.GesamtStimmen / y.WindowGesamt as Prozent
        FROM ParteiStimmenBedarfWindowGrouped x, GesamtStimmenProWindow y
        WHERE x.bWindowed = y.bWindowed
    )
    SELECT *
    FROM ParteiProzentBedarfWindowGrouped
    ORDER BY bWindowed, partei;
