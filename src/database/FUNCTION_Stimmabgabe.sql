CREATE FUNCTION W.Stimmabgabe(perso_nr text, wahllokal_id text, wahlkreis text, stimmkreis integer, e_kandidat integer, z_kandidat integer, z_partei text) RETURNS VOID
    SECURITY DEFINER
    AS $$
	DECLARE
    BEGIN
      UPDATE W.WAHLABGABETOKEN SET erststimmeabgegeben = true, chtime = now() WHERE token = digest(perso_nr, 'sha256')::text and wahllokal = wahllokal_id and erststimmeabgegeben = false;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Erststimme kann nicht abgegeben werden. Keine Stimmen wurden gespeichert.'
        USING DETAIL = 'Möglicherweise ist Personalausweis nicht freigeschalten oder Erststimme wurde bereits abgegeben.',
        HINT = 'Wahlhelfer kontaktieren!';
      END IF;
      IF e_kandidat IS NOT NULL THEN
        INSERT INTO W.ERSTSTIMME (kandidat, landtagswahl, gueltig) VALUES (e_kandidat, 2018, TRUE);
      END IF;

			UPDATE W.WAHLABGABETOKEN SET zweitstimmeabgegeben = true, chtime = now() WHERE token = digest(perso_nr, 'sha256')::text and wahllokal = wahllokal_id and zweitstimmeabgegeben = false;
			IF NOT FOUND THEN
				RAISE EXCEPTION 'Zweitstimme kann nicht abgegeben werden. Keine Stimmen wurden gespeichert.'
				USING DETAIL = 'Möglicherweise ist Personalausweis nicht freigeschalten oder Zweitstimme wurde bereits abgegeben.',
				HINT = 'Wahlhelfer kontaktieren!';
			END IF;
			IF z_kandidat IS NOT NULL AND z_partei IS NULL THEN
				INSERT INTO W.zweitstimmekandidat (kandidat, stimmkreis, landtagswahl, gueltig) VALUES (z_kandidat, stimmkreis, 2018, TRUE);
			END IF;
			IF z_kandidat IS NULL and z_partei IS NOT NULL THEN
				INSERT INTO W.zweitstimmepartei (landtagswahl, wahlkreisname, stimmkreis, partei, gueltig) VALUES (2018, wahlkreis, stimmkreis, z_partei, TRUE);
			END IF;
    END
$$ LANGUAGE 'plpgsql'