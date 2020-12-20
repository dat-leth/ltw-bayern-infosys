CREATE MATERIALIZED VIEW w.ErststimmenProKandiat(landtagswahl, kandidat, anzahl) AS
    SELECT e.landtagswahl, e.kandidat, COUNT(*)
    FROM w.erststimme e
    WHERE e.gueltig = true
    GROUP BY e.landtagswahl, e.kandidat;

CREATE MATERIALIZED VIEW w.ZweitstimmenProKandidatStimmkreis(landtagswahl, kandidat, stimmkreis, anzahl) AS
    SELECT z.landtagswahl, z.kandidat, z.stimmkreis, COUNT(*)
    FROM w.zweitstimmekandidat z
    WHERE z.gueltig = true
    GROUP BY z.landtagswahl, z.kandidat, z.stimmkreis;

CREATE MATERIALIZED VIEW w.ZweitstimmenProParteiStimmkreis(landtagswahl, partei, stimmkreis, anzahl) AS
    SELECT z.landtagswahl, z.partei, z.stimmkreis, COUNT(*)
    FROM w.zweitstimmepartei z
    WHERE z.gueltig = true
    GROUP BY z.landtagswahl, z.partei, z.stimmkreis;
