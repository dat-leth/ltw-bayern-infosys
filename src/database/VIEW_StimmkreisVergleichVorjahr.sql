CREATE VIEW w.StimmkreisVergleichVorjahr(stimmkreis, partei, gesamtstimmen2018, prozent2018, gesamtstimmen2013, prozent2013) AS
    WITH StimmenProStimmkreis AS (
        SELECT s.landtagswahl, s.stimmkreis, SUM(s.erststimmen + s.zweitstimmen) as anzahl
        FROM w.StimmenProParteiStimmkreis s
        GROUP BY s.landtagswahl, s.stimmkreis
    ), GesamtStimmenProzent AS (
        SELECT s.landtagswahl, s.stimmkreis, x.stimmkreisname, x.wahlkreisname, s.partei,
           coalesce(s.erststimmen, 0) + coalesce(s.zweitstimmen, 0) as GesamtStimmen,
           (coalesce(s.erststimmen, 0) + coalesce(s.zweitstimmen, 0)) / sps.anzahl as Prozent
        FROM w.StimmenProParteiStimmkreis s
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
