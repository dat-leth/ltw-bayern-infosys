CREATE VIEW W.KNAPP AS 
WITH ERSTSTIMMEN_ORDNUNG AS (
    SELECT E.STIMMKREIS,
        E.WAHLKREIS,
        E.LANDTAGSWAHL,
        E.PERSNR,
		K.NAME,
        E.PARTEI,
        E.ANZAHL,
        (
            ROW_NUMBER() OVER(
                PARTITION BY E.LANDTAGSWAHL,
                E.STIMMKREIS
                ORDER BY E.ANZAHL DESC
            )
        )
    FROM W.ERSTSTIMMENPROKANDIDATSTIMMKREIS E
	JOIN W.KANDIDAT K ON K.PERSNR = E.PERSNR and K.LANDTAGSWAHL = E.LANDTAGSWAHL
),
DIFFERENZ AS (
    SELECT E.LANDTAGSWAHL,
        E.STIMMKREIS,
		S.STIMMKREISNAME,
        E.ROW_NUMBER AS PLATZIERUNG_ERSTSTIMMEN,
        E.PARTEI,
        E.NAME AS KANDIDAT,
        E.ANZAHL,
        S.STIMMBERECHTIGTE,
        CASE
            WHEN E.ROW_NUMBER != 1 THEN ABS(
                (
                    SELECT ANZAHL
                    FROM ERSTSTIMMEN_ORDNUNG e2
                    WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                        AND E.STIMMKREIS = E2.STIMMKREIS
                        AND E2.ROW_NUMBER = 1
                ) - E.ANZAHL
            ) * 1.00 / S.STIMMBERECHTIGTE
            ELSE ABS(
                (
                    SELECT ANZAHL
                    FROM ERSTSTIMMEN_ORDNUNG e2
                    WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                        AND E.STIMMKREIS = E2.STIMMKREIS
                        AND E2.ROW_NUMBER = 2
                ) - E.ANZAHL
            ) * 1.00 / S.STIMMBERECHTIGTE
        END AS DIFF_PROZ,
        CASE
            WHEN E.ROW_NUMBER != 1 THEN (
                SELECT ANZAHL
                FROM ERSTSTIMMEN_ORDNUNG e2
                WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                    AND E.STIMMKREIS = E2.STIMMKREIS
                    AND E2.ROW_NUMBER = 1
            ) - E.ANZAHL
            ELSE E.ANZAHL - (
                SELECT ANZAHL
                FROM ERSTSTIMMEN_ORDNUNG e2
                WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                    AND E.STIMMKREIS = E2.STIMMKREIS
                    AND E2.ROW_NUMBER = 2
            )
        END AS DIFF_ABS,
        CASE
            WHEN E.ROW_NUMBER != 1 THEN (
                SELECT PARTEI
                FROM ERSTSTIMMEN_ORDNUNG e2
                WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                    AND E.STIMMKREIS = E2.STIMMKREIS
                    AND E2.ROW_NUMBER = 1
            )
            ELSE (
                SELECT PARTEI
                FROM ERSTSTIMMEN_ORDNUNG e2
                WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                    AND E.STIMMKREIS = E2.STIMMKREIS
                    AND E2.ROW_NUMBER = 2
            )
        END AS PARTEI_VS,
        CASE
            WHEN E.ROW_NUMBER != 1 THEN (
                SELECT NAME
                FROM ERSTSTIMMEN_ORDNUNG e2
                WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                    AND E.STIMMKREIS = E2.STIMMKREIS
                    AND E2.ROW_NUMBER = 1
            )
            ELSE (
                SELECT NAME
                FROM ERSTSTIMMEN_ORDNUNG e2
                WHERE E.LANDTAGSWAHL = E2.LANDTAGSWAHL
                    AND E.STIMMKREIS = E2.STIMMKREIS
                    AND E2.ROW_NUMBER = 2
            )
        END AS KANDIDAT_VS
    FROM ERSTSTIMMEN_ORDNUNG E
        JOIN W.STIMMKREIS S ON E.STIMMKREIS = S.NUMMER
        AND E.LANDTAGSWAHL = S.LANDTAGSWAHL
    ORDER BY E.STIMMKREIS ASC,
        E.ROW_NUMBER ASC
),
DIFFERENZ_ORDNUNG AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY PARTEI, LANDTAGSWAHL
            ORDER BY DIFF_PROZ ASC
        ) AS KNAPP_RANG
    FROM DIFFERENZ
)
SELECT *
FROM DIFFERENZ_ORDNUNG o
WHERE KNAPP_RANG <= 10