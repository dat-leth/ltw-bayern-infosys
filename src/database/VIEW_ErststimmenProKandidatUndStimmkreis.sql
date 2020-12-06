    -- Alle Erststimmen eines Kandidaten pro Stimmkreis
    -- Mitausgegeben werden Wahlkreis und die Partei
CREATE MATERIALIZED VIEW w.ErststimmenProKandidatStimmkreis(stimmkreis, wahlkreis, landtagswahl, persnr, partei, anzahl) AS
    SELECT k.direktkandidatinstimmkreis, k.listenkandidatinwahlkreis, k.landtagswahl, k.persnr, k.partei, COUNT(*) as anzahl
    FROM w.erststimme s
    INNER JOIN w.kandidat k
        ON k.persnr = s.kandidat
        AND k.landtagswahl = s.landtagswahl
    WHERE s.gueltig = true
    GROUP BY k.direktkandidatinstimmkreis, k.landtagswahl, k.persnr, k.partei;