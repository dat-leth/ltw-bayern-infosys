import SideNavigation from "../../src/SideNavigation";
import {
    InputLabel,
    makeStyles,
    MenuItem,
    Select,
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableRow,
    Typography
} from "@material-ui/core"
import React, {useEffect, useState} from "react";
import {useRouter} from "next/router";
import {loadData, serverSideRendering} from "../../src/helper/serverSide";


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

export const getServerSideProps = async (context) => await loadData(`/gewaehlte?landtagswahl=eq.${context.params.ltw}`);

export default function Gewaehlte({data}) {
    const classes = useStyles();

    const router = useRouter();
    const {ltw} = router.query;

    const [gewaehlteData, setGewaehlteData] = useState(data || []);

    // update state if new data was loaded (happens on drop down change)
    useEffect(() => setGewaehlteData(data || []), [data]);

    useEffect(() => {
        if (ltw == null) return;

        loadData(`/gewaehlte?landtagswahl=eq.${ltw}`, setGewaehlteData);
    }, [ltw]);

    const handleSelect = (event) => router.push(`/gewaehlte/${event.target.value}`);

    return <>
        <SideNavigation drawerWidth={300}/>
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Gewählte</Typography>
            <InputLabel id="ltw-select-label">Landtagswahl</InputLabel>
            <Select labelId="ltw-select-label" id="ltw-select" value={ltw || ''} onChange={handleSelect}>
                <MenuItem value={2018}>2018</MenuItem>
                <MenuItem value={2013}>2013</MenuItem>
            </Select>
            <Table stickyHeader={true} size="small">
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