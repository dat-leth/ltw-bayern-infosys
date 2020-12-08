import {Drawer, List, ListItem, makeStyles, Typography} from "@material-ui/core";
import Link from "./Link";
import React from "react";
import PropTypes from "prop-types";

const useStyles = (drawerWidth) => makeStyles((theme) => ({
    drawer: {
        width: drawerWidth,
        flexShrink: 0,
    },
    drawerPaper: {
        width: drawerWidth,
    },
    list: {
        padding: theme.spacing(25, 0, 0, 4)
    },
}))();

function SideNavigation(props) {
    const classes = useStyles(props.drawerWidth);

    return <Drawer
        className={classes.drawer}
        variant="permanent"
        classes={{
            paper: classes.drawerPaper,
        }}
        anchor="left"
    >
        <List className={classes.list}>
            <ListItem>
                <Link href={'/overview'} color="textPrimary" variant="subtitle1">Übersicht</Link>
            </ListItem>
            <ListItem>
                <Link href={'/wahlkreis'} color="textPrimary" variant="subtitle1">Wahlkreisübersicht</Link>
            </ListItem>
            <ListItem>
                <Link href={'/stimmkreis'} color="textPrimary" variant="subtitle1">Stimmkreisübersicht</Link>
            </ListItem>
            <ListItem>
                <Link href={'/gewaehlte'} color="textPrimary" variant="subtitle1">Gewählte</Link>
            </ListItem>
        </List>
    </Drawer>;
}

SideNavigation.propTypes = {
    drawerWidth: PropTypes.number
};

export default SideNavigation;
