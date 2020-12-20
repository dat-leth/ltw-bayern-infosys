CREATE VIEW w.StimmkreisDetails(landtagswahl, stimmkreis, stimmkreisname, wahlkreisname, stimmberechtigte, waehler, parteierststimme, direktmandat) AS
    WITH MaxStimmenProStimmkreis AS (
        SELECT x.landtagswahl, x.stimmkreis, MAX(x.anzahl) as max
        FROM w.ErststimmenProKandidatStimmkreis x
        GROUP BY x.landtagswahl, x.stimmkreis
    )
    SELECT s.landtagswahl, s.nummer, s.stimmkreisname, s.wahlkreisname, s.stimmberechtigte, s.waehler, k.partei as ParteiErststimme, k.name as Direktmandat
    FROM w.stimmkreis s
    INNER JOIN MaxStimmenProStimmkreis m
        ON m.landtagswahl = s.landtagswahl
        AND m.stimmkreis = s.nummer
    INNER JOIN w.ErststimmenProKandidatStimmkreis e
        ON e.landtagswahl = m.landtagswahl
        AND e.stimmkreis = m.stimmkreis
        AND e.anzahl = m.max
    INNER JOIN w.kandidat k
        ON k.landtagswahl = e.landtagswahl
        AND k.persnr = e.persnr;
