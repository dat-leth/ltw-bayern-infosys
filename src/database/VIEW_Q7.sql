-- DIESE DATEI ENTHÄLT ALLE VIEWS FÜR DIE AUFGABE Q7;
-- ALLE HIER DEFINIERTEN VIEWS SIND ALSO NON MATERIALIZED

CREATE VIEW w.ErststimmenProKandiat_NONMAT(landtagswahl, kandidat, anzahl) AS
SELECT e.landtagswahl, e.kandidat, COUNT(*)
FROM w.erststimme e
WHERE e.gueltig = true
GROUP BY e.landtagswahl, e.kandidat;

CREATE VIEW w.ZweitstimmenProKandidatStimmkreis_NONMAT(landtagswahl, kandidat, stimmkreis, anzahl) AS
SELECT z.landtagswahl, z.kandidat, z.stimmkreis, COUNT(*)
FROM w.zweitstimmekandidat z
WHERE z.gueltig = true
GROUP BY z.landtagswahl, z.kandidat, z.stimmkreis;

CREATE VIEW w.ZweitstimmenProParteiStimmkreis_NONMAT(landtagswahl, partei, stimmkreis, anzahl) AS
SELECT z.landtagswahl, z.partei, z.stimmkreis, COUNT(*)
FROM w.zweitstimmepartei z
WHERE z.gueltig = true
GROUP BY z.landtagswahl, z.partei, z.stimmkreis;

CREATE VIEW w.ErststimmenProKandidatStimmkreis_NONMAT(stimmkreis, wahlkreis, landtagswahl, persnr, partei, anzahl) AS
SELECT k.direktkandidatinstimmkreis, k.listenkandidatinwahlkreis, k.landtagswahl, k.persnr, k.partei, COUNT(*) as anzahl
FROM w.erststimme s
         INNER JOIN w.kandidat k
                    ON k.persnr = s.kandidat
                        AND k.landtagswahl = s.landtagswahl
WHERE s.gueltig = true
GROUP BY k.direktkandidatinstimmkreis, k.landtagswahl, k.persnr, k.partei;

CREATE VIEW w.StimmenProWahlkreis_NONMAT AS
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


CREATE VIEW w.StimmenProParteiStimmkreis_NONMAT(landtagswahl, partei, stimmkreis, zweitstimmen, erststimmen) AS
WITH ZweitstimmenProPartei(landtagswahl, partei, stimmkreis, anzahl) AS (
    SELECT s.landtagswahl, k.partei, s.stimmkreis, SUM(s.anzahl)
    FROM w.ZweitstimmenProKandidatStimmkreis_NONMAT s
             INNER JOIN w.kandidat k
                        ON k.landtagswahl = s.landtagswahl
                            AND k.persnr = s.kandidat
    GROUP BY s.landtagswahl, k.partei, s.stimmkreis
    UNION ALL
    SELECT s.landtagswahl, s.partei, s.stimmkreis, s.anzahl
    FROM w.ZweitstimmenProParteiStimmkreis_NONMAT s
), ErststimmenProPartei(landtagswahl, partei, stimmkreis, anzahl) AS (
    SELECT s.landtagswahl, k.partei, k.direktkandidatinstimmkreis, SUM(s.anzahl)
    FROM w.ErststimmenProKandiat_NONMAT s
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

CREATE VIEW w.StimmkreisVergleichVorjahr_NONMAT(stimmkreis, partei, gesamtstimmen2018, prozent2018, gesamtstimmen2013, prozent2013) AS
WITH StimmenProStimmkreis AS (
    SELECT s.landtagswahl, s.stimmkreis, SUM(s.erststimmen + s.zweitstimmen) as anzahl
    FROM w.StimmenProParteiStimmkreis_NONMAT s
    GROUP BY s.landtagswahl, s.stimmkreis
), GesamtStimmenProzent AS (
    SELECT s.landtagswahl, s.stimmkreis, x.stimmkreisname, x.wahlkreisname, s.partei,
           coalesce(s.erststimmen + s.zweitstimmen, 0) as GesamtStimmen,
           coalesce(s.erststimmen + s.zweitstimmen, 0) / sps.anzahl as Prozent
    FROM w.StimmenProParteiStimmkreis_NONMAT s
             INNER JOIN StimmenProStimmkreis sps
                        ON sps.landtagswahl = s.landtagswahl
                            AND sps.stimmkreis = s.stimmkreis
             INNER JOIN w.stimmkreis x
                        ON x.landtagswahl = s.landtagswahl
                            AND x.nummer = s.stimmkreis
), StimmkreisVergleichVorjahr AS (
    SELECT g2018.stimmkreis, g2018.partei,
           g2018.GesamtStimmen as GesamtStimmen2018, g2018.Prozent as Prozent2018,
           g2013.GesamtStimmen as GesamtStimmen2013, g2013.Prozent as Prozent2013
    FROM GesamtStimmenProzent g2018
             LEFT JOIN GesamtStimmenProzent g2013
                       ON g2013.stimmkreisname = g2018.stimmkreisname
                           AND g2013.partei = g2018.partei
                           AND g2013.landtagswahl = g2018.landtagswahl - 5
    WHERE g2018.landtagswahl = 2018
)
SELECT * FROM StimmkreisVergleichVorjahr;

CREATE VIEW w.StimmkreisDetails_NONMAT(landtagswahl, stimmkreis, stimmkreisname, wahlkreisname, stimmberechtigte, waehler, parteierststimme, direktmandat) AS
WITH MaxStimmenProStimmkreis AS (
    SELECT x.landtagswahl, x.stimmkreis, MAX(x.anzahl) as max
    FROM w.ErststimmenProKandidatStimmkreis_NONMAT x
    GROUP BY x.landtagswahl, x.stimmkreis
)
SELECT s.landtagswahl, s.nummer, s.stimmkreisname, s.wahlkreisname, s.stimmberechtigte, s.waehler, k.partei as ParteiErststimme, k.name as Direktmandat
FROM w.stimmkreis s
         INNER JOIN MaxStimmenProStimmkreis m
                    ON m.landtagswahl = s.landtagswahl
                        AND m.stimmkreis = s.nummer
         INNER JOIN w.ErststimmenProKandidatStimmkreis_NONMAT e
                    ON e.landtagswahl = m.landtagswahl
                        AND e.stimmkreis = m.stimmkreis
                        AND e.anzahl = m.max
         INNER JOIN w.kandidat k
                    ON k.landtagswahl = e.landtagswahl
                        AND k.persnr = e.persnr;