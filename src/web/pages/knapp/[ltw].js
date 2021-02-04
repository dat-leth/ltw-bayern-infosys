import SideNavigation from "../../src/SideNavigation";
import {
    InputLabel,
    makeStyles,
    Select,
    Typography,
    MenuItem,
    Table,
    TableHead,
    TableBody,
    TableRow,
    TableCell
} from "@material-ui/core"
import {useState, useEffect, useMemo} from "react";
import {clientSideRendering, loadData} from "../../src/helper/serverSide";
import {useRouter} from "next/router";


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

export const getServerSideProps = async (context) => {
    if (clientSideRendering()) return {props: {}};

    const parteiDataUrl = `/partei`;
    const parteiData = await loadData(parteiDataUrl);


    const knappDataUrl = `/knapp?landtagswahl=eq.${context.params.ltw}`;
    const knappData = await loadData(knappDataUrl);

    return {
        props: {
            preParteiData: parteiData.props.data,
            preKnappData: knappData.props.data
        }
    }
}

export default function Knapp({preParteiData, preKnappData}) {
    const router = useRouter();
    const {ltw} = router.query;

    const classes = useStyles()

    const [selectedPartei, setSelectedPartei] = useState('CSU')
    const [parteienData, setParteienData] = useState(preParteiData || [])
    const [knappData, setKnappData] = useState(preKnappData || [])

    // update state if new data was loaded (happens on drop down change)
    useEffect(() => setKnappData(preKnappData || []), [preKnappData]);

    useEffect(() => {
        loadData(`/partei`, setParteienData);
    }, []);

    useEffect(() => {
        if (ltw == null) return;

        loadData(`/knapp?landtagswahl=eq.${ltw}`, setKnappData);
    }, [ltw])

    const filteredKnappData = useMemo(() => {
        return knappData.filter((row) => row.partei === selectedPartei)
    }, [selectedPartei, knappData])

    const handleLtwSelect = (event) => router.push(`/knapp/${event.target.value}`);
    const handleParteiSelect = (event) => setSelectedPartei(event.target.value)

    return <>
        <SideNavigation drawerWidth={300}/>
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Knappste Siege/Verluste</Typography>
            <InputLabel id="ltw-select-label">Landtagswahl</InputLabel>
            <Select labelId="ltw-select-label" id="ltw-select" value={ltw || ''} onChange={handleLtwSelect}>
                <MenuItem value={2018}>2018</MenuItem>
                <MenuItem value={2013}>2013</MenuItem>
            </Select>
            <InputLabel id="partei-select-label">Partei</InputLabel>
            <Select labelId="partei-select-label" id="partei-select" value={selectedPartei}
                    onChange={handleParteiSelect}>
                {parteienData.map((partei) => (
                    <MenuItem key={partei.name} value={partei.name}>{partei.name}</MenuItem>))}
            </Select>
            <Table>
                <TableHead>
                    <TableRow>
                        <TableCell>Kandidat*in (Partei)</TableCell>
                        <TableCell>verlor/gewann</TableCell>
                        <TableCell>Kandidat*in (Partei)</TableCell>
                        <TableCell>Stimmendifferenz (in %)</TableCell>
                        <TableCell>Stimmkreis</TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {filteredKnappData.map((versus) => (
                        <TableRow>
                            <TableCell>{versus.kandidat} ({versus.partei})</TableCell>
                            <TableCell>{versus.platzierung_erststimmen === 1 ? 'gewann' : 'verlor'} gegen</TableCell>
                            <TableCell>{versus.kandidat_vs} ({versus.partei_vs})</TableCell>
                            <TableCell>um {versus.diff_abs} Stimmen
                                ({Intl.NumberFormat({maximumSignificantDigits: 3}).format(versus.diff_proz * 100)} %)</TableCell>
                            <TableCell>in {versus.stimmkreisname} ({versus.stimmkreis})</TableCell>
                        </TableRow>
                    ))}
                </TableBody>
            </Table>
        </div>
    </>
}