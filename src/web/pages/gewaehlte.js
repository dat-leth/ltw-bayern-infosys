import SideNavigation from "../src/SideNavigation";
import { makeStyles, Table, TableBody, TableCell, TableHead, TableRow, Typography, Select, InputLabel, MenuItem } from "@material-ui/core"
import { useState, useEffect } from "react";


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

export default function Gewaehlte() {
    const classes = useStyles()

    const [ltw, setLtw] = useState(2018);
    const [gewaehlteData, setGewaehlteData] = useState([]);

    useEffect(() => {
        fetch(process.env.NEXT_PUBLIC_BACKEND_URL + `/gewaehlte?landtagswahl=eq.${ltw}`).then(resp => {
            if (resp.ok) {
                resp.json()
                    .then(data => setGewaehlteData(data))
                    .catch(err => console.error('Failed to deserialize JSON', err));
            } else {
                console.warn('Backend Request not successful', resp);
            }
        }).catch(err => console.error('Backend Request failed', err))
    }, [ltw]);

    const handleSelect = (event) => setLtw(event.target.value)

    return <>
        <SideNavigation drawerWidth={300} />
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Gewählte</Typography>
            <InputLabel id="ltw-select-label">Landtagswahl</InputLabel>
            <Select labelId="ltw-select-label" id="ltw-select" value={ltw} onChange={handleSelect}>
                <MenuItem value={2018}>2018</MenuItem>
                <MenuItem value={2013}>2013</MenuItem>
            </Select>
            <Table>
                <TableHead>
                    <TableRow>
                        <TableCell rowSpan={2}>Name</TableCell>
                        <TableCell rowSpan={2}>Partei</TableCell>
                        <TableCell rowSpan={2}>Wahlkreis</TableCell>
                        <TableCell colSpan={3}>Gewählt im Stimmkreis bzw. auf Wahlkreisliste</TableCell>
                    </TableRow>
                    <TableRow>
                        <TableCell>Nr.</TableCell>
                        <TableCell>Bezeichnung</TableCell>
                        <TableCell>Mandat</TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {gewaehlteData.map((mandat) => {
                        return <TableRow key={`${mandat.landtagswahl}_${mandat.persnr}`}>
                            <TableCell>{mandat.name}</TableCell>
                            <TableCell>{mandat.partei}</TableCell>
                            <TableCell>{mandat.wahlkreis}</TableCell>
                            <TableCell>{mandat.stimmkreis ?? 'Wkr'}</TableCell>
                            <TableCell>{mandat.stimmkreisname ?? mandat.wahlkreis}</TableCell>
                            <TableCell>{mandat.typ}</TableCell>
                        </TableRow>
                    })}
                </TableBody>
            </Table>
        </div>
    </>
}