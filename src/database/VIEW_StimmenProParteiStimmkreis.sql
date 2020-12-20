CREATE VIEW w.StimmenProParteiStimmkreis(landtagswahl, partei, stimmkreis, zweitstimmen, erststimmen) AS
    WITH ZweitstimmenProPartei(landtagswahl, partei, stimmkreis, anzahl) AS (
            SELECT s.landtagswahl, k.partei, s.stimmkreis, SUM(s.anzahl)
            FROM w.ZweitstimmenProKandidatStimmkreis s
            INNER JOIN w.kandidat k
                ON k.landtagswahl = s.landtagswahl
                AND k.persnr = s.kandidat
            GROUP BY s.landtagswahl, k.partei, s.stimmkreis
        UNION ALL
            SELECT s.landtagswahl, s.partei, s.stimmkreis, s.anzahl
            FROM w.ZweitstimmenProParteiStimmkreis s
    ), ErststimmenProPartei(landtagswahl, partei, stimmkreis, anzahl) AS (
        SELECT s.landtagswahl, k.partei, k.direktkandidatinstimmkreis, SUM(s.anzahl)
        FROM w.ErststimmenProKandiat s
        INNER JOIN w.kandidat k
            ON k.landtagswahl = s.landtagswahl
            AND k.persnr = s.kandidat
        GROUP BY s.landtagswahl, k.partei, k.direktkandidatinstimmkreis
    ), StimmenProParteiStimmkreis(landtagswahl, partei, stimmkreis, zweitstimmen, erstimmen) AS (
        SELECT z.landtagswahl, z.partei, z.stimmkreis, SUM(z.anzahl) as Zweitstimmen, e.anzahl as Erststimmen
        FROM w.stimmkreis s
        LEFT JOIN ZweitstimmenProPartei z
            ON z.landtagswahl = s.landtagswahl
            AND z.stimmkreis = s.nummer
        LEFT JOIN ErststimmenProPartei e
            ON z.landtagswahl = e.landtagswahl
            AND z.stimmkreis = e.stimmkreis
            AND z.partei = e.partei
        GROUP BY z.landtagswahl, z.partei, z.stimmkreis, e.anzahl
    )
    SELECT * FROM StimmenProParteiStimmkreis s;
