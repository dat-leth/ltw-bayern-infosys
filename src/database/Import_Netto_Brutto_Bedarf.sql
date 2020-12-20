CREATE TABLE w.Bedarf (
    Kreisschluessel int not null primary key references w.Kreis,
    NettoBedarf int not null,
    BruttoBedarf int not null,
    AngerechnetesEinkommen int not null
);

COPY w.Bedarf(Kreisschluessel, NettoBedarf, BruttoBedarf, AngerechnetesEinkommen)  FROM '/database/netto_brutto_bedarf.csv' DELIMITER ';' CSV HEADER;
