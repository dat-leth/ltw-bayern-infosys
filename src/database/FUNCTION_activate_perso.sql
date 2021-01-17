CREATE FUNCTION WAHLHELFER.activate_perso(perso_nr text, wahllokal text) RETURNS void AS $$
	INSERT INTO W.wahlabgabetoken VALUES (digest(perso_nr, 'sha256'), wahllokal, 2018, FALSE, FALSE)
$$ LANGUAGE SQL