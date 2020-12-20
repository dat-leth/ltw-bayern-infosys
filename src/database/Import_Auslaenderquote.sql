CREATE TABLE w.Auslaenderquote (
    Kreisschluessel int not null primary key references w.Kreis,
    Quote numeric(4, 3) not null
);

COPY w.Auslaenderquote(Kreisschluessel, Quote) FROM '/database/auslaenderquote.csv' DELIMITER ',' CSV HEADER;