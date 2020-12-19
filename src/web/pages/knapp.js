import SideNavigation from "../src/SideNavigation";
import { InputLabel, makeStyles, Select, Typography, MenuItem, Table, TableHead, TableBody, TableRow, TableCell } from "@material-ui/core"
import { useState, useEffect, useMemo } from "react";


const useStyles = makeStyles(theme => ({
    table: {
        width: '100%',
        margin: theme.spacing(7, 7)
    },
    chart: {
        position: "relative",
        width: '55%',
        alignSelf: "center",
        paddingTop: theme.spacing(5)
    },
    wrapper: {
        display: 'flex',
        flexDirection: 'column',
        flex: '1 1 100%',
        padding: theme.spacing(5, 15, 0, 15),
        maxWidth: 1500
    }
}));

export default function Knapp() {
    const classes = useStyles()

    const [ltw, setLtw] = useState(2018)
    const [selectedPartei, setSelectedPartei] = useState('CSU')
    const [parteienData, setParteienData] = useState([])
    const [knappData, setKnappData] = useState([])

    useEffect(() => {
        fetch(process.env.NEXT_PUBLIC_BACKEND_URL + `/partei`).then(resp => {
            if (resp.ok) {
                resp.json()
                    .then(data => setParteienData(data))
                    .catch(err => console.error('Failed to deserialize JSON', err));
            } else {
                console.warn('Backend Request not successful', resp);
            }
        }).catch(err => console.error('Backend Request failed', err))
    }, []);

    useEffect(() => {
        fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/knapp?landtagswahl=eq.${ltw}`)
            .then(res => {
                if (res.ok) {
                    res.json()
                        .then(data => setKnappData(data))
                        .catch(err => console.error('Failed to deserialize JSON', err))
                } else {
                    console.warn('Backend request not successful', resp)
                }
            }).catch(err => console.error('Backend request failed', err))
    }, [ltw])

    const filteredKnappData = useMemo(() => {
        return knappData.filter((row) => row.partei === selectedPartei)
    }, [selectedPartei, knappData])

    const handleLtwSelect = (event) => setLtw(event.target.value)
    const handleParteiSelect = (event) => setSelectedPartei(event.target.value)

    return <>
        <SideNavigation drawerWidth={300} />
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Knappste Siege/Verluste</Typography>
            <InputLabel id="ltw-select-label">Landtagswahl</InputLabel>
            <Select labelId="ltw-select-label" id="ltw-select" value={ltw} onChange={handleLtwSelect}>
                <MenuItem value={2018}>2018</MenuItem>
                <MenuItem value={2013}>2013</MenuItem>
            </Select>
            <InputLabel id="partei-select-label">Partei</InputLabel>
            <Select labelId="partei-select-label" id="partei-select" value={selectedPartei} onChange={handleParteiSelect}>
                {parteienData.map((partei) => (<MenuItem key={partei.name} value={partei.name}>{partei.name}</MenuItem>))}
            </Select>
            <Table>
                <TableHead>
                    <TableRow>
                        <TableCell>Partei</TableCell>
                        <TableCell>verlor/gewann</TableCell>
                        <TableCell>Partei</TableCell>
                        <TableCell>Stimmendifferenz (in %)</TableCell>
                        <TableCell>Stimmkreis</TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {filteredKnappData.map((versus) => (
                        <TableRow>
                            <TableCell>{versus.partei}</TableCell>
                            <TableCell>{versus.platzierung_erststimmen === 1 ? 'gewann' : 'verlor'} gegen</TableCell>
                            <TableCell>{versus.partei_vs}</TableCell>
                            <TableCell>um {versus.diff_abs} Stimmen ({Intl.NumberFormat({ maximumSignificantDigits: 3 }).format(versus.diff_proz * 100)} %)</TableCell>
                            <TableCell>in {versus.stimmkreisname} ({versus.stimmkreis})</TableCell>
                        </TableRow>
                    ))}
                </TableBody>
            </Table>
        </div>
    </>
}