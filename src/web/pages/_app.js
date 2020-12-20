import React from 'react';
import PropTypes from 'prop-types';
import Head from 'next/head';
import {ThemeProvider, withStyles} from '@material-ui/core/styles';
import CssBaseline from '@material-ui/core/CssBaseline';
import theme from '../src/theme';
import '../public/style.css';

const GlobalCss = withStyles(theme => ({
    '@global': {
        'html,body': {
            height: '100%'
        },
        'body,#__next': {
            display: 'flex',
            flex: 1
        },
        '.MuiLink-root': {
            fontSize: '12pt',
            cursor: 'pointer'
        },
        '.MuiLink-root.active': {
            fontWeight: theme.typography.fontWeightBold,
            color: theme.palette.primary.main
        },
    },
}))(() => null);

export default function MyApp(props) {
    const {Component, pageProps} = props;

    React.useEffect(() => {
        // Remove the server-side injected CSS.
        const jssStyles = document.querySelector('#jss-server-side');
        if (jssStyles) {
            jssStyles.parentElement.removeChild(jssStyles);
        }
    }, []);

    return (
        <React.Fragment>
            <Head>
                <title>Wahlinformation</title>
                <meta name="viewport" content="minimum-scale=1, initial-scale=1, width=device-width"/>
            </Head>
            <ThemeProvider theme={theme}>
                <CssBaseline/>
                <GlobalCss/>
                <Component {...pageProps} />
            </ThemeProvider>
        </React.Fragment>
    );
}

MyApp.propTypes = {
    Component: PropTypes.elementType.isRequired,
    pageProps: PropTypes.object.isRequired,
};
