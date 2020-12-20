from dataclasses import dataclass
from datetime import datetime
import xml.etree.ElementTree as ET
import psycopg2
import psycopg2.extras

@dataclass
class Wahlkreis:
    nummer: int
    name: str
    landtagswahl: int
    sitze: int

@dataclass
class Stimmkreis:
    nummer: int
    wahlkreisname: str
    landtagswahl: int
    stimmkreisname: str
    stimmberechtigte: int
    waehler: int


@dataclass
class Kandidat:
    persNr: int
    landtagswahl: int
    name: str
    partei: str
    listenplatz: int
    listenkandidatInWahlkreis: str
    direktkandidatInStimmkreis: int
    erststimmen: dict # StimmkreisNummer -> Anzahl (nur 1 Eintrag)
    zweitstimmen: dict # StimmkreisNummer -> Anzahl (alle anderen)

@dataclass
class Partei:
    parteiname: str
    landtagswahl: int
    zweitstimmenPartei: dict # StimmkreisNummer -> Anzahl
    zweitstimmenWahlkreis: dict # Gesammtzahl Zweitstimmen pro Wahlkreis


def get_wahlkreisname(stimmkreisnr):
    if 100 < stimmkreisnr < 200:
        return 'Oberbayern'
    elif 200 < stimmkreisnr < 300:
        return 'Niederbayern'
    elif 300 < stimmkreisnr < 400:
        return 'Oberpfalz'
    elif 400 < stimmkreisnr < 500:
        return 'Oberfranken'
    elif 500 < stimmkreisnr < 600:
        return 'Mittelfranken'
    elif 600 < stimmkreisnr < 700:
        return 'Unterfranken'
    elif 700 < stimmkreisnr < 800:
        return 'Schwaben'
    else:
        raise ValueError


def parse_wahlkreise(jahr):
    if jahr == 2013:
        return [
            Wahlkreis(901, 'Oberbayern', 2013, 60),
            Wahlkreis(902, 'Niederbayern', 2013, 18),
            Wahlkreis(903, 'Oberpfalz', 2013, 16),
            Wahlkreis(904, 'Oberfranken', 2013, 16),
            Wahlkreis(905, 'Mittelfranken', 2013, 24),
            Wahlkreis(906, 'Unterfranken', 2013, 20),
            Wahlkreis(907, 'Schwaben', 2013, 26),
        ]
    elif jahr == 2018:
        return [
            Wahlkreis(901, 'Oberbayern', 2018, 61),
            Wahlkreis(902, 'Niederbayern', 2018, 18),
            Wahlkreis(903, 'Oberpfalz', 2018, 16),
            Wahlkreis(904, 'Oberfranken', 2018, 16),
            Wahlkreis(905, 'Mittelfranken', 2018, 24),
            Wahlkreis(906, 'Unterfranken', 2018, 19),
            Wahlkreis(907, 'Schwaben', 2018, 26),
        ]


def parse_stimmkreise(info_xml_path, jahr):
    stimmkreise = []

    root = ET.parse(info_xml_path).getroot()
    for regionaleinheit in root.findall('Regionaleinheit'):
        nummer = int(regionaleinheit.findtext('Allgemeine_Angaben/Schluesselnummer'))
        if nummer >= 900 or nummer % 100 == 0:
            continue

        stimmkreise.append(Stimmkreis(
            nummer = nummer,
            wahlkreisname = get_wahlkreisname(nummer),
            landtagswahl = jahr,
            stimmkreisname = regionaleinheit.findtext('Allgemeine_Angaben/Name_der_Regionaleinheit').strip(),
            stimmberechtigte = int(regionaleinheit.findtext('Allgemeine_Angaben/Stimmberechtigte')),
            waehler = int(regionaleinheit.findtext('Allgemeine_Angaben/Waehler'))
        ))

    return stimmkreise

def parse_parteien(ergebnis_xml_path, info_xml_path, wahlkreise, jahr):
    rootErgebnis = ET.parse(ergebnis_xml_path).getroot()
    parteinamen = {i.findtext('Name').strip() for i in rootErgebnis.findall('.//Partei')}
    parteien = {n: Partei(n, jahr, {}, {}) for n in parteinamen}

    for partei in rootErgebnis.findall('.//Partei'):
        name = partei.findtext('Name').strip()

        for stimmkreis in partei.findall('.//Stimmkreis'):
            parteien[name].zweitstimmenPartei[int(stimmkreis.findtext('NrSK'))] = int(stimmkreis.findtext('ZweitSohneKandidat'))

    return list(parteien.values())

def parse_kandidaten(ergebnis_xml_path, jahr):
    persNr = 1
    kandidaten = []
    root = ET.parse(ergebnis_xml_path).getroot()
    for wahlkreis in root.findall('Wahlkreis'):
        wahlkreisname = wahlkreis.findtext('Name')
        for partei in wahlkreis.findall('Partei'):
            parteiname = partei.findtext('Name')
            for kandidat in partei.findall('Kandidat'):
                k = Kandidat(
                    persNr=persNr,
                    landtagswahl=jahr,
                    name=f"{kandidat.findtext('Nachname').strip()}, {kandidat.findtext('Vorname').strip()}",
                    partei=parteiname,
                    listenplatz=int(kandidat.findtext('AnfangListenPos')),
                    listenkandidatInWahlkreis=wahlkreisname,
                    direktkandidatInStimmkreis=None,
                    erststimmen={},
                    zweitstimmen={}
                )
                for stimmkreis in kandidat.findall('Stimmkreis'):
                    if stimmkreis.find('NumStimmen').attrib['Stimmentyp'] == 'Zweitstimmen':
                        k.zweitstimmen[int(stimmkreis.findtext('NrSK'))] = int(stimmkreis.findtext('NumStimmen'))
                    elif stimmkreis.find('NumStimmen').attrib['Stimmentyp'] == 'Erststimmen':
                        k.erststimmen[int(stimmkreis.findtext('NrSK'))] = int(stimmkreis.findtext('NumStimmen'))
                        k.direktkandidatInStimmkreis = int(stimmkreis.findtext('NrSK'))
                kandidaten.append(k)
                persNr = persNr + 1
    return kandidaten

def insert_landtagswahl(connection, jahr):
    cur = connection.cursor()
    cur.execute("INSERT INTO w.landtagswahl (jahr, wahltag) VALUES " +
                "(2013, '2013-09-15'), (2018, '2018-10-14') " +
                "ON CONFLICT (jahr) DO NOTHING")
    cur.close()

def insert_wahlkreise(connection, wahlkreise):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Wahlkreis (wahlkreisname, landtagswahl, sitze) VALUES %s',
        [(w.name, w.landtagswahl, w.sitze) for w in wahlkreise]
    )
    cur.close()

def insert_stimmkreise(connection, stimmkreise):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Stimmkreis (nummer, wahlkreisname, landtagswahl, stimmkreisname, stimmberechtigte, waehler) VALUES %s',
        [(s.nummer, s.wahlkreisname, s.landtagswahl, s.stimmkreisname, s.stimmberechtigte, s.waehler) for s in stimmkreise]
    )
    cur.close()

def insert_parteien(connection, parteien):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Partei (name) VALUES %s ON CONFLICT (name) DO NOTHING',
        [(p.parteiname, ) for p in parteien]
    )
    cur.close()

def insert_kandidaten(connection, kandidaten):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Kandidat (persNr, landtagswahl, name, partei, listenplatz, listenkandidatInWahlkreis, direktkandidatInStimmkreis) VALUES %s',
        [(k.persNr, k.landtagswahl, k.name, k.partei, k.listenplatz, k.listenkandidatInWahlkreis, k.direktkandidatInStimmkreis) for k in kandidaten]
    )
    cur.close()

def generate_erststimmen(connection, kandidaten, year, stimmkreise=None):
    if stimmkreise is not None:
        kandidaten = [k for k in kandidaten if k.direktkandidatInStimmkreis in stimmkreise]

    cur = connection.cursor()

    cur.execute(
        """
        CREATE TEMP TABLE tmp_agg_erststimmen (
            persNr int not null,
            anzahl int not null
        )
        ON COMMIT DELETE ROWS
        """
    )
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO tmp_agg_erststimmen VALUES %s',
        [(k.persNr, sum(k.erststimmen.values())) for k in kandidaten]
    )
    cur.execute(
        """
        INSERT INTO w.erststimme(kandidat, landtagswahl, gueltig)
        SELECT tae.persnr, {} as landtagswahl, true AS gueltig
        FROM
            tmp_agg_erststimmen tae,
            generate_series(1, tae.anzahl)
        """.format(year)
    )

    cur.close()

def generate_zweitstimmen(connection, kandidaten, parteien, year, stimmkreise=None):
    if stimmkreise is not None:
        kandidaten = [k for k in kandidaten if k.direktkandidatInStimmkreis in stimmkreise]

    cur = connection.cursor()

    # Generate Zweitstimmen für Listenkandidaten
    cur.execute(
        """
        CREATE TEMP TABLE tmp_agg_zweitstimmen (
            persNr int not null,
            stimmkreisnr int not null,
            anzahl int not null
        )
        ON COMMIT DELETE ROWS
        """
    )
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO tmp_agg_zweitstimmen VALUES %s',
        [(k.persNr, stimmkreis, anzahl) for k in kandidaten for stimmkreis, anzahl in k.zweitstimmen.items()]
    )
    cur.execute(
        """
        INSERT INTO w.zweitstimmekandidat(stimmkreis, kandidat, landtagswahl, gueltig)
        SELECT taz.stimmkreisnr, taz.persnr, {} as landtagswahl, true AS gueltig
        FROM
            tmp_agg_zweitstimmen taz,
            generate_series(1, taz.anzahl)
        """.format(year)
    )

    # Generate Zweitstimmen für Parteien
    cur.execute(
        """
        CREATE TEMP TABLE tmp_zweitstimmen_partei_stimmkreis (
            partei varchar(255) not null,
            stimmkreisnr int not null,
            total int not null
        )
        ON COMMIT DELETE ROWS
        """
    )
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO tmp_zweitstimmen_partei_stimmkreis VALUES %s',
        [(p.parteiname, stimmkreisnr, total) for p in parteien for stimmkreisnr, total in p.zweitstimmenPartei.items()]
    )
    cur.execute(
        """
        INSERT INTO w.zweitstimmepartei(landtagswahl, wahlkreisname, stimmkreis, partei, gueltig)
        WITH
        FehlendeZweitstimmen AS (
            SELECT s.wahlkreisname, zps.stimmkreisnr, zps.partei, zps.total as StimmenOhneKandidat
            FROM tmp_zweitstimmen_partei_stimmkreis zps
            INNER JOIN w.stimmkreis s
                ON s.landtagswahl = {0}
                AND s.nummer = zps.stimmkreisnr
        )
        SELECT {0} as landtagswahl, f.wahlkreisname, f.stimmkreisnr, f.partei, true as gueltig
        FROM
            FehlendeZweitstimmen f,
            generate_series(1, f.StimmenOhneKandidat);
        """.format(year)
    )

    cur.close()

def modify_index(connection, schema, indisready):
    cur = connection.cursor()
    cur.execute(
        """
        UPDATE pg_index
        SET indisready={}
        WHERE indrelid = (
            SELECT oid
            FROM pg_class
            WHERE relname='{}'
        );
        """.format(indisready, schema)
    )

    if indisready == 'true':
        cur.execute("REINDEX TABLE {};".format(schema))

    cur.close()

def modify_constraints(connection, schema, enable):
    cur = connection.cursor()
    action = 'ENABLE' if enable else 'DISABLE'
    cur.execute("ALTER TABLE {} {} TRIGGER ALL;".format(schema, action))
    cur.close()

def disable_checks(connection, *argv):
    for schema in argv:
        print(datetime.now(), 'Disabling index/checks for: {}'.format(schema))
        modify_constraints(connection, schema, False)
        modify_index(connection, schema, 'false')

def enable_checks(connection, *argv):
    for schema in argv:
        print(datetime.now(), 'Enabling index/checks for: {}'.format(schema))
        modify_constraints(connection, schema, True)
        modify_index(connection, schema, 'true')

def import_year(year):
    print(datetime.now(), 'Connecting...')
    conn = psycopg2.connect("dbname=postgres user=postgres password=postgres")

    ergebnis_xml_path = '{}Ergebnisse_final.xml'.format(year)
    info_xml_path = '{}AllgemeineInformationen.xml'.format(year)

    print(datetime.now(), 'Parsing...')
    wahlkreise = parse_wahlkreise(year)
    stimmkreise = parse_stimmkreise(info_xml_path, year)
    parteien = parse_parteien(ergebnis_xml_path, info_xml_path, wahlkreise, year)
    kandidaten = parse_kandidaten(ergebnis_xml_path, year)

    print(datetime.now(), 'Inserting Landtagswahl...')
    insert_landtagswahl(conn, year)

    print(datetime.now(), 'Inserting Wahlkreise...')
    insert_wahlkreise(conn, wahlkreise)

    print(datetime.now(), 'Inserting Stimmkreise...')
    insert_stimmkreise(conn, stimmkreise)

    print(datetime.now(), 'Inserting Parteien...')
    insert_parteien(conn, parteien)

    print(datetime.now(), 'Inserting Kandidaten...')
    insert_kandidaten(conn, kandidaten)

    disable_checks(conn, 'W.ZweitstimmeKandidat', 'W.ZweitstimmePartei', 'W.Erststimme')

    print(datetime.now(), 'Generating Erststimmen (slow)...')
    generate_erststimmen(conn, kandidaten, year)

    print(datetime.now(), 'Generating Zweitstimmen (also slow but in DB)...')
    generate_zweitstimmen(conn, kandidaten, parteien, year)

    enable_checks(conn, 'W.ZweitstimmeKandidat', 'W.ZweitstimmePartei', 'W.Erststimme')

    conn.commit()
    conn.close()

if __name__ == "__main__":
    print(datetime.now(), 'Importing 2013...')
    import_year(2013)

    print(datetime.now(), 'Importing 2018...')
    import_year(2018)

    print(datetime.now())
