CREATE VIEW w.Sitzplatzverteilung(landtagswahl, wahlkreis, partei, ausgleich, sitze, gesamt, ueberhang, minsitze) AS
WITH RECURSIVE
    -- Alle (gültigen) Stimmen (Erst + Zweitstimme) die eine Partei pro Landtagswahl gesammelt hat.
StimmenProPartei(partei, landtagswahl, anzahl) AS(
    SELECT s.partei, s.landtagswahl, SUM(s.anzahl)
    FROM w.StimmenProWahlkreis s
    GROUP BY s.partei, s.landtagswahl
),
    -- Alle Parteien die bei einer Landtagswahl die 5% Hürde überwunden haben.
ParteienUeber5Prozent(partei, landtagswahl) AS (
    SELECT s.partei, s.landtagswahl
    FROM StimmenProPartei s
    WHERE s.anzahl > (SELECT SUM(s2.anzahl)*0.05 FROM StimmenProPartei s2 WHERE s2.landtagswahl = s.landtagswahl)
),
     -- Gesamtanzahl aller Stimmen (Erst + Zweitstimmen) bei einer Landtagswahl in einem Wahlkreis abgegeben wurden.
     -- Gezählt werden nur die Stimmen von Parteien über 5%.
     -- Anzahl ist Grundlage zur Berechnung der Anteile jeder Partei pro Wahlkreis.
GesammtStimmenProWahlkreis(wahlkreis, landtagswahl, anzahl) AS(
    SELECT s.wahlkreis, s.landtagswahl, SUM(s.anzahl)
    FROM w.StimmenProWahlkreis s
    INNER JOIN ParteienUeber5Prozent p
        ON s.partei = p.partei
        AND s.landtagswahl = p.landtagswahl
    GROUP BY s.wahlkreis, s.landtagswahl
),
     -- Berechnung der Sitzanteile mittels Ganzzahlig und Rest.
     -- Hierbei werden nur mehr Parteien über 5% zurückgegeben.
     -- Diese Berechnung berechnet nur den Prozentualen Anteil, die danachfolgende die Ganzzahlig und Rest Werte.
AnteileOhneSitze(partei, wahlkreis, landtagswahl, anzahl, anteil) AS (
    SELECT s.partei, s.wahlkreis, s.landtagswahl, s.anzahl,
           CAST(s.anzahl as numeric(13, 6)) / g.anzahl as anteil
    FROM w.StimmenProWahlkreis s
    INNER JOIN GesammtStimmenProWahlkreis g
        ON g.wahlkreis = s.wahlkreis
        AND g.landtagswahl = s.landtagswahl
    INNER JOIN w.wahlkreis w
        ON w.wahlkreisname = s.wahlkreis
        AND w.landtagswahl = s.landtagswahl
    INNER JOIN ParteienUeber5Prozent p
        ON p.partei = s.partei
        AND p.landtagswahl = s.landtagswahl
),
     -- Berechnung der Sitzanteile mittels Ganzzahlig und Rest.
     -- Hierbei werden nur mehr Parteien über 5% zurückgegeben (durch AnteileOhneSitze sichergestellt).
Anteile(partei, wahlkreis, landtagswahl, anzahl, anteil, ganzzahlig, rest) AS (
    SELECT a.partei, a.wahlkreis, a.landtagswahl, a.anzahl,
           a.anteil,
           floor(a.anteil * w.sitze) as ganzzahlig,
           a.anteil * w.sitze - floor(a.anteil * w.sitze) as rest
    FROM AnteileOhneSitze a
    INNER JOIN w.wahlkreis w
        ON w.wahlkreisname = a.wahlkreis
        AND w.landtagswahl = a.landtagswahl
),
     -- Berechnung der noch nicht durch den Ganzzahligen Anteil vergebenen Sitze pro Wahlkreis (und Landtagswahl).
     -- Der überbleibende Rest muss dann auf die Parteien nach größem Rest verteilt werden.
SitzeNichtVergebenProWahlkreis(wahlkreis, landtagswahl, anzahl) AS (
    SELECT a.wahlkreis, a.landtagswahl, w.sitze - SUM(a.ganzzahlig)
    FROM Anteile a
    INNER JOIN w.wahlkreis w
        ON w.wahlkreisname = a.wahlkreis
        AND w.landtagswahl = a.landtagswahl
    GROUP BY a.wahlkreis, a.landtagswahl, w.sitze
),
     -- Die Reste aus 'Anteile' werden hier pro Wahlkreis (und Landtagswahl) absteigend sortiert und mit einer rownumber versehen.
     -- Alle Parteien deren rownumber dann kleiner als die Anzahl der noch nicht vergebenen Sitze (SitzeNichtVergebenProWahlkreis) ist,
     --  müssen dann einen weiteren Sitz erhalten.
AnteilSortiert(partei, wahlkreis, landtagswahl, anzahl, anteil, ganzzahlig, rest, o) AS(
    SELECT *, row_number() over (
        partition by wahlkreis, landtagswahl
        order by rest desc) as o
    FROM Anteile a
),
     -- In Wahlkreisen in denen nicht alle Sitze durch den Ganzzahligen Anteil vergeben wurden,
     --  werden die verbleibenden Sitze (SitzeNichtVergebenProWahlkreis) auf die Parteien aufgeteilt.
     --  Dabei erhält jede Partei einen Sitz deren Rest am größten ist, solang noch nicht vergebene Sitze existieren.
     -- Die Reste wurden in 'AnteilSortiert' absteigend sortiert und mit einer rownumber versehen.
     -- Jetzt erhalten alle Parteien deren rownumber <= AnzahlNichtVergebenerSitze ist einen weiteren Sitz.
SitzeMitRest(partei, wahlkreis, landtagswahl, ganzzahlig, rest, gesamt) AS (
    SELECT a.partei, a.wahlkreis, a.landtagswahl, a.ganzzahlig,
           CASE WHEN a.o <= n.anzahl THEN 1 ELSE 0 END as rest,
           a.ganzzahlig + CASE WHEN a.o <= n.anzahl THEN 1 ELSE 0 END as gesamt
    FROM AnteilSortiert a
    INNER JOIN SitzeNichtVergebenProWahlkreis n
        ON n.wahlkreis = a.wahlkreis
        AND n.landtagswahl = a.landtagswahl
),
     -- Kontextwechsel, hier werden die Erststimmengewinner pro Stimmkreis ermittelt.
     -- Ein Kandidat muss dafür die maximale Anzahl an Erstimmen in einem Stimmkreis besitzen.
     -- Der Grenzfall dass zwei Kandidaten die maximale Anzahl an Erststimmen erhalten haben ist nicht berücksichtigt.
ErststimmenGewinnerProStimmkreis(stimmkreis, wahlkreis, landtagswahl, persnr, partei, anzahl) AS (
    SELECT s.stimmkreis, s.wahlkreis, s.landtagswahl, s.persnr, s.partei, s.anzahl
    FROM w.ErststimmenProKandidatStimmkreis s
    INNER JOIN (
        SELECT s2.landtagswahl, s2.stimmkreis, MAX(s2.anzahl) as max        -- Hier: Ermittlung der Maximalen Erstimmen
        FROM w.ErststimmenProKandidatStimmkreis s2                          -- pro Stimmkreis
        GROUP BY s2.landtagswahl, s2.stimmkreis                             --
    ) as MaxErststimmen
        ON MaxErststimmen.landtagswahl = s.landtagswahl
        AND MaxErststimmen.stimmkreis = s.stimmkreis
        AND MaxErststimmen.max = s.anzahl                                   -- Selektion der Zeilen mit der maximalen Erststimmenanzahl
),
     -- Berechnung der Überhangmandate.
     -- Eine Partei erhält Überhandmandate wenn sie in einem Stimmkreis weniger Sitze nach Zweitstimme erhalten hat (SitzeMitRest)
     --  als sie Stimmkreise über die Erststimme gewinnen konnte.
UeberhandMandate(partei, wahlkreis, landtagswahl, ganzzahlig, rest, ueberhang, gesamt) AS (
    SELECT s.partei, s.wahlkreis, s.landtagswahl, s.ganzzahlig, s.rest,                             -- Übernommene Daten aus SitzeMitRest
           CASE WHEN s.gesamt < COUNT(*) THEN COUNT(*) - s.gesamt ELSE 0 END as ueberhang,          -- Anzahl der Überhangmandate
           s.gesamt + CASE WHEN s.gesamt < COUNT(*) THEN COUNT(*) - s.gesamt ELSE 0 END as gesamt   -- Gesamtzahl mit Überhangmandaten
    FROM SitzeMitRest s
    LEFT JOIN ErststimmenGewinnerProStimmkreis e
        ON e.wahlkreis = s.wahlkreis
        AND e.landtagswahl = s.landtagswahl
        AND e.partei = s.partei
    GROUP BY s.partei, s.wahlkreis, s.landtagswahl, s.ganzzahlig, s.rest, s.gesamt
),
     -- Diese cte "korrigiert" die Anzahl der Sitze pro Wahlkreis auf die Zahl mit Überhangmandaten.
     -- Hat eine Partei in einem Wahlkreis Überhangmandate erhalten, hat der Wahlkreis immer automatisch so viele Sitz mehr.
     -- Dies wird für die berechnung der Ausgleichsmandate durch die rekursive cte benötigt
SitzeProWahlkreisKorrigiert(wahlkreis, landtagswahl, sitze) AS (
    SELECT m.wahlkreis, m.landtagswahl, SUM(m.gesamt) as sitze
    FROM UeberhandMandate m
    GROUP BY m.wahlkreis, m.landtagswahl
),
     -- Der Ausgangspunkt für die rekursive cte.
     -- Hier wird das "normale" Sitzplatzergebnis um die Sitze pro Wahlkreis erweitert
     -- MinProPartei deshlab, da jede Partei nach hinzufügen von Ausgleichsmandaten mindestens diese Anzahl an Sitzen erhalten soll
MinProPartei(partei, wahlkreis, landtagswahl, gesamt, sitze, ueberhang) AS (
    SELECT u.partei, u.wahlkreis, u.landtagswahl, u.gesamt, s.sitze, u.ueberhang
    FROM UeberhandMandate u
    INNER JOIN SitzeProWahlkreisKorrigiert s
        ON s.landtagswahl = u.landtagswahl
        AND s.wahlkreis = u.wahlkreis
),
     -- Rekursive CTE zur Berechnung der Sitzplatzverteilung
     -- Je Rekursionsschritt wird ein Ausgleichsmandat hinnzugezählt (und die Sitzplatzkapazität ebenfalls um 1 erweitert)
     -- Das Abbruchkriterium lautet wir folgt: 'abort' ist gesetzt
     -- Abort wird gesetzt, wenn in einem Wahlkreis jede Partei mindestens die Zahl an Sitze wie in 'MinProPartei' erhalten hat
     -- Es kommt also immer ein ganzer Wahlkreis 'weiter' wenn er Parteien enthält,
     --  die durch die Ausgleichsmandate weniger Sitze erhalten haben als ihnen zustehen würden
Ausgleichsmandate(partei, wahlkreis, landtagswahl, ausgleich, gesamt, sitze, ueberhang, minsitze, abort) AS (
    SELECT m.partei, m.wahlkreis, m.landtagswahl, -1 as ausgleich, m.gesamt, m.sitze - 1, m.ueberhang, m.gesamt, false
    FROM MinProPartei m
    UNION ALL (
        WITH
             -- Schlüssel von AusgleichUndSitzePlusOne = {Partei, Wahlkreis, Landtagswahl}
             -- Der nachfolgende Teil ist analog zur "Basis" Berechnung ohne
        _AusgleichUndSitzePlusOne(partei, wahlkreis, landtagswahl, ausgleich, gesamt, sitze, ueberhang, minsitze, abort) AS (
            SELECT a.partei, a.wahlkreis, a.landtagswahl, a.ausgleich + 1, a.gesamt, a.sitze + 1, a.ueberhang, a.minsitze, a.abort FROM Ausgleichsmandate a
        ),
             -- Analog Anteile
        _Anteile(partei, wahlkreis, landtagswahl, anzahl, anteil, ganzzahlig, rest) AS (
            SELECT a.partei, a.wahlkreis, a.landtagswahl, a.anzahl,
                   a.anteil,
                   floor(a.anteil * w.sitze) as ganzzahlig,
                   a.anteil * w.sitze - floor(a.anteil * w.sitze) as rest
            FROM AnteileOhneSitze a
            INNER JOIN _AusgleichUndSitzePlusOne w
                ON w.wahlkreis = a.wahlkreis
                AND w.landtagswahl = a.landtagswahl
                AND w.partei = a.partei
        ),
             -- Analog SitzeNichtVergebenProWahlkreis
        _SitzeNichtVergebenProWahlkreis(wahlkreis, landtagswahl, anzahl) AS (
            SELECT a.wahlkreis, a.landtagswahl, w.sitze - SUM(a.ganzzahlig)
            FROM _Anteile a
            INNER JOIN _AusgleichUndSitzePlusOne w
                ON w.wahlkreis = a.wahlkreis
                AND w.landtagswahl = a.landtagswahl
                AND w.partei = a.partei
            GROUP BY a.wahlkreis, a.landtagswahl, w.sitze
        ),
             -- Analog AnteilSortiert
        _AnteilSortiert(partei, wahlkreis, landtagswahl, anzahl, anteil, ganzzahlig, rest, o) AS(
            SELECT *, row_number() over (
                partition by wahlkreis, landtagswahl
                order by rest desc) as o
            FROM _Anteile a
        ),
             -- Analog SitzeMitRest
        _SitzeMitRest(partei, wahlkreis, landtagswahl, gesamt) AS (
            SELECT a.partei, a.wahlkreis, a.landtagswahl,
                   a.ganzzahlig + CASE WHEN a.o <= n.anzahl THEN 1 ELSE 0 END as gesamt
            FROM _AnteilSortiert a
            INNER JOIN _SitzeNichtVergebenProWahlkreis n
                ON n.wahlkreis = a.wahlkreis
                AND n.landtagswahl = a.landtagswahl
        )
        SELECT ap1.partei, ap1.wahlkreis, ap1.landtagswahl, ap1.ausgleich, s.gesamt, ap1.sitze, ap1.ueberhang, ap1.minsitze, NOT EXISTS (
            SELECT *
            FROM MinProPartei m
            INNER JOIN _SitzeMitRest s2
                ON s2.wahlkreis = m.wahlkreis
                AND s2.landtagswahl = m.landtagswahl
                AND s2.partei = m.partei
                AND s2.gesamt < m.gesamt                -- Hier befindet sich das wesentliche Kriterium zum Abbruch
            WHERE m.landtagswahl = s.landtagswahl
            AND m.wahlkreis = s.wahlkreis
        ) as abort                                      -- abort wird true wenn alle Parteien des Wahlkreises mindestens die Anzahl
        FROM _SitzeMitRest s                            --  Sitze wie in MinProPartei erhalten haben
        INNER JOIN _AusgleichUndSitzePlusOne ap1
            ON ap1.partei = s.partei
            AND ap1.landtagswahl = s.landtagswahl
            AND ap1.wahlkreis = s.wahlkreis
        WHERE ap1.abort = false                         -- Wurde abort in der letzten Runde gesetzt, ist dieser Wahlkreis 'fertig'
    )
),
     -- Bestimmung der maximalen Anzahl an Ausgleichsmandaten pro Wahlkreis
     -- Wird für nachfolgende Abfrage benötigt
MaxAusgleichsmandateProWahlkreis(landtagswahl, wahlkreis, maxAusgleich) AS (
    SELECT a.landtagswahl, a.wahlkreis, MAX(a.ausgleich)
    FROM Ausgleichsmandate a
    GROUP BY a.landtagswahl, a.wahlkreis
),
     -- Bereinigung der Ergebnisse, die nicht die maximale Anzahl Ausgleichsmandate pro Wahlkreis haben
     -- (Die sind während der Rekursion entstanden werden aber nicht benötigt)
Ergebnis AS (
    SELECT a.landtagswahl, a.wahlkreis, a.partei, a.ausgleich, a.sitze, a.gesamt, a.ueberhang, a.minsitze
    FROM Ausgleichsmandate a
    INNER JOIN MaxAusgleichsmandateProWahlkreis m
        ON m.landtagswahl = a.landtagswahl
        AND m.wahlkreis = a.wahlkreis
        AND m.maxAusgleich = a.ausgleich
)
SELECT * FROM Ergebnis s;
