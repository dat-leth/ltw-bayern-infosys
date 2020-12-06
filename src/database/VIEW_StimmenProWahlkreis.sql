    -- Alle Stimmen einer Partei pro Wahlkreis (Erst und Zweitstimme)
CREATE MATERIALIZED VIEW w.StimmenProWahlkreis AS
WITH
ZweitstimmenKandidatProParteiUndWahlkreis(partei, wahlkreis, landtagswahl, anzahl) AS(
    SELECT k.partei, k.listenkandidatinwahlkreis, k.landtagswahl, COUNT(*) as anzahl
    FROM w.zweitstimmekandidat zk
    INNER JOIN w.kandidat k
        ON zk.kandidat = k.persnr
        AND zk.landtagswahl = k.landtagswahl
    WHERE zk.gueltig = true
    GROUP BY k.partei, k.listenkandidatinwahlkreis, k.landtagswahl
),
ZweitstimmenParteiProParteiUndWahlkreis(partei, wahlkreis, landtagswahl, anzahl) AS(
    SELECT wp.partei, wp.wahlkreisname, wp.landtagswahl, COUNT(*)
    FROM w.zweitstimmepartei wp
    WHERE wp.gueltig = true
    GROUP BY wp.partei, wp.wahlkreisname, wp.landtagswahl
),
ErstimmenProParteiUndWahlkreis(partei, wahlkreis, landtagswahl, anzahl) AS(
    SELECT k.partei, k.listenkandidatinwahlkreis, k.landtagswahl, COUNT(*) as anzahl
    FROM w.erststimme e
    INNER JOIN w.kandidat k
        ON e.kandidat = k.persnr
        AND e.landtagswahl = k.landtagswahl
    WHERE e.gueltig = true
    GROUP BY k.partei, k.listenkandidatinwahlkreis, k.landtagswahl
)
    SELECT X.partei, X.wahlkreis, X.landtagswahl, SUM(X.anzahl) as anzahl
    FROM (
        SELECT * FROM ZweitstimmenKandidatProParteiUndWahlkreis
    UNION ALL
        SELECT * FROM ZweitstimmenParteiProParteiUndWahlkreis
    UNION ALL
        SELECT * FROM ErstimmenProParteiUndWahlkreis) X
    GROUP BY X.partei, X.wahlkreis, X.landtagswahl;