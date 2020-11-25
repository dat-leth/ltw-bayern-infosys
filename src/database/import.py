import xml.etree.ElementTree as ET
import psycopg2

conn = psycopg2.connect("dbname=postgres user=postgres password=postgres")
cur = conn.cursor()

try:

    cur.execute(
        "DELETE FROM w.kandidat; DELETE FROM w.partei; DELETE FROM w.stimmkreis; DELETE FROM w.wahlkreis; DELETE FROM w.landtagswahl;")

    cur.execute("INSERT INTO w.landtagswahl (jahr, wahltag) VALUES " +
                "(2013, '2013-09-15'), (2018, '2018-10-14')")

    wahlkreise = {
        'Oberbayern': [101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131],
        'Niederbayern': [201, 202, 203, 204, 205, 206, 207, 208, 209],
        'Oberpfalz': [301, 302, 303, 304, 305, 306, 307, 308],
        'Oberfranken': [401, 402, 403, 404, 405, 406, 407, 408],
        'Mittelfranken': [501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512],
        'Unterfranken': [601, 602, 603, 604, 605, 606, 607, 608, 609, 610],
        'Schwaben': [701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713]
    }

    sitze = {
        'Oberbayern': 61,
        'Niederbayern': 18,
        'Oberpfalz': 16,
        'Oberfranken': 16,
        'Mittelfranken': 24,
        'Unterfranken': 19,
        'Schwaben': 26
    }

    stimmkreise = {}

    kandidaten = []

    parteiStimmen = {}

    # wahlkreise invertieren
    for k, v in wahlkreise.items():
        for i in v:
            stimmkreise[i] = k

    root = ET.parse('14_10_2018_Landtagswahl_2018_Bayern.xml').getroot()

    for re in root.findall('Regionaleinheit'):
        id = int(re.findtext('Allgemeine_Angaben/Schluesselnummer'))
        name = re.findtext('Allgemeine_Angaben/Name_der_Regionaleinheit')

        if name in wahlkreise:
            print(id, name)
            cur.executemany("INSERT INTO w.wahlkreis (name, landtagswahl, sitze) VALUES (%s,%s,%s)",
                            [
                                (name, 2018, sitze[name])
                            ])
        elif id in stimmkreise:
            print(id, name)
            wk = stimmkreise[id]
            stimmberechtigte = int(re.findtext(
                'Allgemeine_Angaben/Stimmberechtigte'))
            cur.executemany("INSERT INTO w.stimmkreis (nummer, wahlkreisname, landtagswahl, stimmkreisname, stimmberechtigte) VALUES (%s,%s,%s,%s,%s)",
                            [
                                (id, wk, 2018, name, stimmberechtigte)
                            ])
            for wv in re.findall('Wahlvorschläge/Wahlvorschlag'):
                partei = wv.findtext('Name')
                bewerber = wv.findtext('Bewerber')
                erststimmen = wv.findtext('Erststimmen_der_aktuellen_Wahl')
                zweitstimmen = wv.findtext('Zweitstimmen_der_aktuellen_Wahl')

                if bewerber != '-':
                    print(' ' + bewerber + ' - ' + partei)

                    assert erststimmen is not None, 'if there is a bewerber, erststimmen must not be None'

                    kandidaten.append({
                        'partei': partei,
                        'name': bewerber,
                        'stimmkreis': id,
                        'wahlkreis': wk,
                        'erststimmen': int(erststimmen),
                        'zweitstimmen': 0 if zweitstimmen is None else int(zweitstimmen)
                    })
                elif zweitstimmen is not None:
                    print(' !! NO BEWERBER, Partei: ' + partei)

                    assert erststimmen is None, 'if there is no bewerber, there should be no erststimmen'

                    if partei not in parteiStimmen:
                        parteiStimmen[partei] = {
                            'name': partei,
                            'wahlkreis': {
                                'Oberbayern': 0,
                                'Niederbayern': 0,
                                'Oberpfalz': 0,
                                'Oberfranken': 0,
                                'Mittelfranken': 0,
                                'Unterfranken': 0,
                                'Schwaben': 0
                            }
                        }

                    parteiStimmen[partei]['wahlkreis'][wk] += int(zweitstimmen)


    parteiNames = set([(p['name'],) for p in parteiStimmen.values()] + [(k['partei'],) for k in kandidaten])
    cur.executemany("INSERT INTO w.partei (name) VALUES (%s)", parteiNames)

    a = [
            (
                i,
                2018,
                k['name'],
                k['partei'],
                -1,
                k['wahlkreis'],
                k['stimmkreis'] if k['zweitstimmen'] is not None else None
            ) for i,k in enumerate(kandidaten)]

    cur.executemany("INSERT INTO w.kandidat (persnr,landtagswahl,name,partei,listenplatz,listenkandidatinwahlkreis,direktkandidatinstimmkreis) VALUES (%s,%s,%s,%s,%s,%s,%s)", a)

    # Sanity check total votes
    totalErststimmen = sum([0 if o['erststimmen'] is None else o['erststimmen'] for o in kandidaten])
    assert totalErststimmen == 6796249
    print('Anzahl Erststimmen: ' + str(totalErststimmen))

    totalZweitstimmen = sum([o['zweitstimmen'] for o in kandidaten]) + \
                        sum([sum(p['wahlkreis'].values()) for p in parteiStimmen.values()])
    assert totalZweitstimmen == 6768498
    print('Anzahl Zweitstimmen: ' + str(totalZweitstimmen))

finally:
    conn.commit()
    cur.close()
    conn.close()
