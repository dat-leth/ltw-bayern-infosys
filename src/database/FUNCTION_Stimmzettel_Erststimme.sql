CREATE FUNCTION W.STIMMZETTEL_ERSTSTIMME(stimmkreis integer) returns table(nummer bigint, name text, partei text) as $$
SELECT row_number() OVER (
		order by t.ord
	),
	K.NAME,
	K.PARTEI
FROM W.KANDIDAT K
	LEFT JOIN UNNEST(
		'{CSU,SPD,FREIE WÄHLER,GRÜNE,FDP,DIE LINKE,BP,ÖDP,PIRATEN,DIE FRANKEN,AfD,LKR,mut,Die Humanisten,Die PARTEI,Gesundheitsforschung,Tierschutzpartei,V-Partei³}'::text []
	) WITH ORDINALITY T(PARTEI, ORD) ON K.PARTEI = T.PARTEI
WHERE K.LANDTAGSWAHL = 2018
	AND K.DIREKTKANDIDATINSTIMMKREIS = stimmkreis
ORDER BY T.ORD $$ LANGUAGE SQL IMMUTABLE;