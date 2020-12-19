CREATE VIEW w.StimmkreisSiegerPartei AS
    WITH MaxStimmenProStimmkreis AS (
        SELECT s.landtagswahl, s.stimmkreis, MAX(s.erststimmen) as maxerststimmen, MAX(s.zweitstimmen) as maxzweitstimmen
        FROM w.StimmenProParteiStimmkreis s
        GROUP BY s.landtagswahl, s.stimmkreis
    ), StimmkreisGewinnerErststimme AS (
        SELECT s.landtagswahl, s.stimmkreis, s.partei, s.erststimmen
        FROM w.StimmenProParteiStimmkreis s
        INNER JOIN MaxStimmenProStimmkreis m
            ON m.landtagswahl = s.landtagswahl
            AND m.stimmkreis = s.stimmkreis
            AND m.maxerststimmen = s.erststimmen
    ), StimmkreisGewinnerZweitstimme AS (
        SELECT s.landtagswahl, s.stimmkreis, s.partei, s.zweitstimmen
        FROM w.StimmenProParteiStimmkreis s
        INNER JOIN MaxStimmenProStimmkreis m
            ON m.landtagswahl = s.landtagswahl
            AND m.stimmkreis = s.stimmkreis
            AND m.maxzweitstimmen = s.zweitstimmen
    )
    SELECT e.landtagswahl, e.stimmkreis, s.stimmkreisname, s.wahlkreisname, e.partei as ErststimmenSieger, e.erststimmen, z.partei as ZweitstimmenSieger, z.zweitstimmen
    FROM StimmkreisGewinnerErststimme e
    INNER JOIN StimmkreisGewinnerZweitstimme z
        ON z.landtagswahl = e.landtagswahl
        AND z.stimmkreis = e.stimmkreis
    INNER JOIN w.stimmkreis s
        ON s.landtagswahl = e.landtagswahl
        AND s.nummer = e.stimmkreis;
