import React, {useEffect, useMemo, useState} from 'react';
import SideNavigation from "../src/SideNavigation";
import {
    Link,
    makeStyles,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Typography
} from "@material-ui/core";
import {groupBy} from "../src/helper/groupBy";
import {loadData} from "../src/helper/serverSide";

const useStyles = makeStyles(theme => ({
    table: {
        width: '100%',
        padding: theme.spacing(7, 7)
    },
    wrapper: {
        display: 'flex',
        flexDirection: 'column',
        flex: '1 1 100%',
        padding: theme.spacing(5, 15, 0, 15),
        maxWidth: 1500
    },
    groupRow: {
        fontWeight: '500',
        backgroundColor: '#ecf2ff'
    }
}));

export const getServerSideProps = async () => await loadData('/stimmkreissiegerpartei?order=stimmkreis.asc');

export default function Stimmkreis({data}) {
    const classes = useStyles();

    const [stimmkreisSiegerData, setStimmkreisSiegerData] = useState(data || []);

    useEffect(() => {
        loadData('/stimmkreissiegerpartei?order=stimmkreis.asc', setStimmkreisSiegerData);
    }, []);

    useEffect(() => console.log('Stimmkreis Sieger', stimmkreisSiegerData), [stimmkreisSiegerData]);

    const wahlkreise = useMemo(() => {
        return [...new Set(stimmkreisSiegerData.map(o => o.wahlkreisname))]
    }, [stimmkreisSiegerData])

    const tableData = useMemo(() => {
        const stimmkreisSieger = stimmkreisSiegerData?.filter(o => o.landtagswahl === 2018) || [];
        return groupBy(stimmkreisSieger, o => o.wahlkreisname);
    }, [stimmkreisSiegerData]);

    return <>
        <SideNavigation drawerWidth={300}/>
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Stimmkreis Übersicht</Typography>
            <TableContainer className={classes.table}>
                <Table stickyHeader={true} size="small">
                    <TableHead>
                        <TableRow>
                            <TableCell>Stimmkreis Nummer</TableCell>
                            <TableCell>Stimmkreis Name</TableCell>
                            <TableCell align="right">Sieger Partei Erstimmen</TableCell>
                            <TableCell align="right">Anzahl Erstimmen</TableCell>
                            <TableCell align="right">Sieger Partei Zweitstimmen</TableCell>
                            <TableCell align="right">Anzahl Zweitstimmen</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {wahlkreise.map(wahlkreis =>
                            <>
                                <TableRow className={classes.groupRow} key={wahlkreis}>
                                    <TableCell>{wahlkreis}</TableCell>
                                    <TableCell/>
                                    <TableCell align="right"/>
                                    <TableCell align="right"/>
                                    <TableCell align="right"/>
                                    <TableCell align="right"/>
                                </TableRow>
                                {tableData[wahlkreis].map(o =>
                                    <TableRow key={o.stimmkreis}>
                                        <TableCell>{o.stimmkreis}</TableCell>
                                        <TableCell>
                                            <Link href={`stimmkreis/${o.stimmkreis}`}>
                                                {o.stimmkreisname}
                                            </Link>
                                        </TableCell>
                                        <TableCell align="right">{o.erststimmensieger}</TableCell>
                                        <TableCell align="right">{o.erststimmen}</TableCell>
                                        <TableCell align="right">{o.zweitstimmensieger}</TableCell>
                                        <TableCell align="right">{o.zweitstimmen}</TableCell>
                                    </TableRow>
                                )}
                            </>
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </div>
    </>;
}
